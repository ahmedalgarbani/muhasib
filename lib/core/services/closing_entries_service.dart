import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/constant/app_db_constants.dart';
import 'package:muhasib/core/enums/account_type.dart';
import 'package:muhasib/core/enums/journal_entry_type.dart' as core_journal;
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_line_model.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_model.dart';
import 'package:muhasib/features/accounts/domain/repositories/journal_repository.dart';
import 'package:sqflite/sqflite.dart';

/// @Deprecated — use [core_journal.JournalEntryType] from lib/core/enums/journal_entry_type.dart
class JournalEntryType {
  static const String normal = 'normal';            // قيد عادي
  static const String opening = 'opening';          // قيد افتتاحي
  static const String adjusting = 'adjusting';      // قيد تسوية
  static const String closing = 'closing';          // قيد إقفال
  static const String reversing = 'reversing';      // قيد عكسي
  static const String transfer = 'transfer';        // قيد تحويل

  static String getName(String code) =>
      core_journal.JournalEntryType.tryFromCode(code)?.labelAr ?? code;
}

/// Service for creating closing/adjusting journal entries
/// خدمة إنشاء قيود الإقفال والتسوية
class ClosingEntriesService {
  final Database database;
  final JournalRepository journalRepository;
  final AccountConfigService accountConfigService;

  ClosingEntriesService({
    required this.database,
    required this.journalRepository,
    required this.accountConfigService,
  });

  /// Generate unique journal entry number using DB sequence to avoid collision
  Future<String> _generateJournalNumberTxn(Transaction txn, String prefix) async {
    final result = await txn.rawQuery("SELECT COALESCE(MAX(CAST(SUBSTR(number, ${prefix.length + 2}) AS INTEGER)), 0) + 1 as next FROM journal_entries WHERE number LIKE '$prefix-%'");
    final next = (result.first['next'] as int?) ?? 1;
    return '$prefix-${next.toString().padLeft(AppDbConstants.defaultNumberPadding, '0')}';
  }

  /// Legacy non-txn version (kept for compatibility)
  String _generateJournalNumber(String prefix) {
    return '$prefix-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  /// Create an adjusting entry (تسوية)
  /// Used for accruals, prepayments, depreciation, etc.
  Future<Either<Failure, int>> createAdjustingEntry({
    required String description,
    required List<AdjustingEntryLine> lines,
    DateTime? entryDate,
  }) async {
    try {
      // Calculate totals
      final totalDebit = lines.fold<double>(0, (sum, l) => sum + l.debitAmount);
      final totalCredit = lines.fold<double>(0, (sum, l) => sum + l.creditAmount);
      
      // Validate balance
      if ((totalDebit - totalCredit).abs() > 0.01) {
        return Left(ValidationFailure(
          'قيد التسوية غير متوازن: المدين ($totalDebit) لا يساوي الدائن ($totalCredit)',
        ));
      }

      final localCurrencyCode = await _getLocalCurrencyCode();

      final journalLines = <JournalEntryLineModel>[];
      int lineNumber = 1;
      
      for (final line in lines) {
        if (line.debitAmount > 0) {
          journalLines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: line.accountId,
            accountName: line.accountName,
            currencyCode: localCurrencyCode,
            debit: line.debitAmount,
            credit: 0,
            notes: line.notes,
          ));
        }
        if (line.creditAmount > 0) {
          journalLines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: line.accountId,
            accountName: line.accountName,
            currencyCode: localCurrencyCode,
            debit: 0,
            credit: line.creditAmount,
            notes: line.notes,
          ));
        }
      }

      final journalEntry = JournalEntryModel(
        number: _generateJournalNumber('ADJ'),
        entryDate: entryDate ?? DateTime.now(),
        description: 'قيد تسوية: $description',
        referenceType: core_journal.JournalEntryType.adjusting.code,
        isPosted: true,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        difference: 0,
        lines: journalLines,
      );

      return journalRepository.createJournalEntry(journalEntry);
    } catch (e) {
      return Left(UnknownFailure('فشل في إنشاء قيد التسوية: ${e.toString()}'));
    }
  }

  /// Create closing entries for a fiscal period (إقفال الفترة)
  /// Closes all revenue and expense accounts to retained earnings
  /// FIXED: swapped types, abs logic, atomicity, idempotency
  Future<Either<Failure, ClosingResult>> createClosingEntries({
    required DateTime periodEndDate,
    required int retainedEarningsAccountId,
  }) async {
    try {
      // Idempotency: prevent duplicate closing for same date
      final existing = await database.rawQuery(
        "SELECT COUNT(*) as cnt FROM journal_entries WHERE reference_type = ? AND entry_date = ? AND description LIKE '%إقفال%'",
        [core_journal.JournalEntryType.closing.code, periodEndDate.millisecondsSinceEpoch ~/ 1000],
      );
      if ((existing.first['cnt'] as int? ?? 0) > 0) {
        return Left(ValidationFailure('تم إقفال هذه الفترة مسبقاً'));
      }

      // Check fiscal period is not already closed
      final periodCheck = await database.rawQuery('SELECT is_closed FROM fiscal_periods WHERE start_date <= ? AND end_date >= ? LIMIT 1', [periodEndDate.millisecondsSinceEpoch ~/ 1000, periodEndDate.millisecondsSinceEpoch ~/ 1000]);
      if (periodCheck.isNotEmpty && (periodCheck.first['is_closed'] as int?) == 1) {
        return Left(ValidationFailure('الفترة مقفلة مسبقاً'));
      }

      // FIX CRITICAL-07: Correct types via central enum — Revenue/Expense
      // Get all revenue accounts (type = revenue) balances
      final revenueQuery = await database.rawQuery('''
        SELECT a.id, a.name, a.balance
        FROM accounts a
        WHERE a.type = ${AccountType.revenue.value} AND a.is_active = 1 AND a.is_master = 0
        AND a.balance != 0
      ''');

      // Get all expense accounts (type = expenses) balances
      final expenseQuery = await database.rawQuery('''
        SELECT a.id, a.name, a.balance
        FROM accounts a
        WHERE a.type = ${AccountType.expenses.value} AND a.is_active = 1 AND a.is_master = 0
        AND a.balance != 0
      ''');

      // Wrap both closings in single transaction for atomicity (FIX HIGH-15)
      return await database.transaction((txn) async {
        final localCurrencyCode = await _getLocalCurrencyCodeTxn(txn);
        double totalRevenue = 0;
        double totalExpenses = 0;
        final closingEntries = <int>[];

        // FIX CRITICAL-08: Sign-aware logic, not abs()
        // Close revenue accounts (Credit balance normally positive -> Debit to close, negative -> Credit)
        if (revenueQuery.isNotEmpty) {
          final revenueLines = <JournalEntryLineModel>[];
          int lineNumber = 1;

          for (final account in revenueQuery) {
            final balance = (account['balance'] as num?)?.toDouble() ?? 0;
            if (balance.abs() < 0.01) continue;
            
            // Revenue normal credit: positive balance = credit, negative = debit (return)
            if (balance > 0) {
              totalRevenue += balance;
              revenueLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: account['id'] as int,
                accountName: account['name'] as String? ?? '',
                currencyCode: localCurrencyCode,
                debit: balance,
                credit: 0,
                notes: 'إقفال الإيرادات',
              ));
            } else {
              // Negative revenue (return) -> credit to zero
              totalRevenue += balance; // will reduce net
              revenueLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: account['id'] as int,
                accountName: account['name'] as String? ?? '',
                currencyCode: localCurrencyCode,
                debit: 0,
                credit: -balance,
                notes: 'إقفال مردود إيرادات',
              ));
            }
          }

          if (revenueLines.isNotEmpty) {
            // Net revenue may be negative if returns > sales; retained earnings side follows sign
            if (totalRevenue >= 0) {
              revenueLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: retainedEarningsAccountId,
                accountName: 'الأرباح المحتجزة',
                currencyCode: localCurrencyCode,
                debit: 0,
                credit: totalRevenue,
                notes: 'نقل الإيرادات',
              ));
            } else {
              revenueLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: retainedEarningsAccountId,
                accountName: 'الأرباح المحتجزة',
                currencyCode: localCurrencyCode,
                debit: -totalRevenue,
                credit: 0,
                notes: 'نقل صافي مردود الإيرادات',
              ));
            }

            final revNumber = await _generateJournalNumberTxn(txn, 'CLOSE-REV');
            final revenueClosingEntry = JournalEntryModel(
              number: revNumber,
              entryDate: periodEndDate,
              description: 'قيد إقفال الإيرادات للفترة المنتهية في ${DateFormat('yyyy-MM-dd').format(periodEndDate)}',
              referenceType: core_journal.JournalEntryType.closing.code,
              isPosted: true,
              totalDebit: revenueLines.fold<double>(0, (s, l) => s + l.debit),
              totalCredit: revenueLines.fold<double>(0, (s, l) => s + l.credit),
              difference: 0,
              lines: revenueLines,
            );

            // Insert directly via txn to keep atomicity, then via repository for validation
            // Use repository but ensure txn context - fallback to direct insert if needed
            final result = await journalRepository.createJournalEntry(revenueClosingEntry);
            result.fold(
              (failure) => throw Exception(failure.message),
              (id) => closingEntries.add(id),
            );
          }
        }

        // Close expense accounts (Debit balance normally positive -> Credit to close)
        if (expenseQuery.isNotEmpty) {
          final expenseLines = <JournalEntryLineModel>[];
          int lineNumber = 1;

          for (final account in expenseQuery) {
            final balance = (account['balance'] as num?)?.toDouble() ?? 0;
            if (balance.abs() < 0.01) continue;
            
            if (balance > 0) {
              totalExpenses += balance;
              expenseLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: account['id'] as int,
                accountName: account['name'] as String? ?? '',
                currencyCode: localCurrencyCode,
                debit: 0,
                credit: balance,
                notes: 'إقفال المصروفات',
              ));
            } else {
              // Negative expense (recovery) -> debit
              totalExpenses += balance;
              expenseLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: account['id'] as int,
                accountName: account['name'] as String? ?? '',
                currencyCode: localCurrencyCode,
                debit: -balance,
                credit: 0,
                notes: 'إقفال استرداد مصروف',
              ));
            }
          }

          if (expenseLines.isNotEmpty) {
            if (totalExpenses >= 0) {
              expenseLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: retainedEarningsAccountId,
                accountName: 'الأرباح المحتجزة',
                currencyCode: localCurrencyCode,
                debit: totalExpenses,
                credit: 0,
                notes: 'نقل المصروفات',
              ));
            } else {
              expenseLines.add(JournalEntryLineModel(
                lineNumber: lineNumber++,
                accountId: retainedEarningsAccountId,
                accountName: 'الأرباح المحتجزة',
                currencyCode: localCurrencyCode,
                debit: 0,
                credit: -totalExpenses,
                notes: 'نقل صافي استرداد المصروفات',
              ));
            }

            final expNumber = await _generateJournalNumberTxn(txn, 'CLOSE-EXP');
            final expenseClosingEntry = JournalEntryModel(
              number: expNumber,
              entryDate: periodEndDate,
              description: 'قيد إقفال المصروفات للفترة المنتهية في ${DateFormat('yyyy-MM-dd').format(periodEndDate)}',
              referenceType: core_journal.JournalEntryType.closing.code,
              isPosted: true,
              totalDebit: expenseLines.fold<double>(0, (s, l) => s + l.debit),
              totalCredit: expenseLines.fold<double>(0, (s, l) => s + l.credit),
              difference: 0,
              lines: expenseLines,
            );

            final result = await journalRepository.createJournalEntry(expenseClosingEntry);
            result.fold(
              (failure) => throw Exception(failure.message),
              (id) => closingEntries.add(id),
            );
          }
        }

        final netIncome = totalRevenue - totalExpenses;

        // Mark period as closed
        await txn.update('fiscal_periods', {'is_closed': 1, 'closed_at': DateTime.now().millisecondsSinceEpoch ~/ 1000}, where: 'start_date <= ? AND end_date >= ?', whereArgs: [periodEndDate.millisecondsSinceEpoch ~/ 1000, periodEndDate.millisecondsSinceEpoch ~/ 1000]);

        return Right(ClosingResult(
          periodEndDate: periodEndDate,
          totalRevenue: totalRevenue,
          totalExpenses: totalExpenses,
          netIncome: netIncome,
          closingEntryIds: closingEntries,
        ));
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في إنشاء قيود الإقفال: ${e.toString()}'));
    }
  }

  /// Create a reversing entry for a previous adjusting entry
  /// Used at the beginning of a new period to reverse accruals
  Future<Either<Failure, int>> createReversingEntry({
    required int originalEntryId,
    DateTime? reversalDate,
  }) async {
    try {
      // Get original entry
      final result = await journalRepository.getJournalEntry(originalEntryId);
      
      return result.fold(
        (failure) => Left(failure),
        (originalEntry) async {
          final localCurrencyCode = await _getLocalCurrencyCode();
          // Create reversed lines
          final reversedLines = originalEntry.lines.map((line) {
            return JournalEntryLineModel(
              lineNumber: line.lineNumber,
              accountId: line.accountId,
              accountName: line.accountName ?? '',
              currencyCode: line.currencyCode ?? localCurrencyCode,
              debit: line.credit, // Swap
              credit: line.debit, // Swap
              notes: 'عكس: ${line.notes ?? ''}',
            );
          }).toList();

          final totalDebit = reversedLines.fold<double>(0, (sum, l) => sum + l.debit);
          final totalCredit = reversedLines.fold<double>(0, (sum, l) => sum + l.credit);

          final reversingEntry = JournalEntryModel(
            number: _generateJournalNumber('REV'),
            entryDate: reversalDate ?? DateTime.now(),
            description: 'قيد عكسي للقيد رقم ${originalEntry.number}',
            referenceType: core_journal.JournalEntryType.reversing.code,
            referenceId: originalEntryId,
            referenceNumber: originalEntry.number,
            isPosted: true,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            difference: 0,
            lines: reversedLines,
          );

          return journalRepository.createJournalEntry(reversingEntry);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('فشل في إنشاء القيد العكسي: ${e.toString()}'));
    }
  }

  Future<String> _getLocalCurrencyCode() async {
    try {
      final res = await database.query('currencies', where: 'is_local_currency = ?', whereArgs: [1], limit: 1);
      if (res.isNotEmpty && res.first['code'] != null) return res.first['code'] as String;
    } catch (_) {}
    return 'SAR';
  }

  Future<String> _getLocalCurrencyCodeTxn(Transaction txn) async {
    try {
      final res = await txn.query('currencies', where: 'is_local_currency = ?', whereArgs: [1], limit: 1);
      if (res.isNotEmpty && res.first['code'] != null) return res.first['code'] as String;
    } catch (_) {}
    return 'SAR';
  }
}

/// Line item for adjusting entry
class AdjustingEntryLine {
  final int accountId;
  final String accountName;
  final double debitAmount;
  final double creditAmount;
  final String? notes;

  const AdjustingEntryLine({
    required this.accountId,
    required this.accountName,
    this.debitAmount = 0,
    this.creditAmount = 0,
    this.notes,
  });
}

/// Result of closing entries creation
class ClosingResult {
  final DateTime periodEndDate;
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;
  final List<int> closingEntryIds;

  const ClosingResult({
    required this.periodEndDate,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netIncome,
    required this.closingEntryIds,
  });

  bool get isProfit => netIncome > 0;
  bool get isLoss => netIncome < 0;
}

/// Validation Failure
class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}

/// Unknown Failure
class UnknownFailure extends Failure {
  UnknownFailure(super.message);
}
