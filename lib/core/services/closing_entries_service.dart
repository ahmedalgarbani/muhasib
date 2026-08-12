import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_line_model.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_model.dart';
import 'package:muhasib/features/accounts/domain/repositories/journal_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Journal Entry Types for categorization
class JournalEntryType {
  static const String normal = 'normal';            // قيد عادي
  static const String opening = 'opening';          // قيد افتتاحي
  static const String adjusting = 'adjusting';      // قيد تسوية
  static const String closing = 'closing';          // قيد إقفال
  static const String reversing = 'reversing';      // قيد عكسي
  static const String transfer = 'transfer';        // قيد تحويل
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

  /// Generate unique journal entry number
  String _generateJournalNumber(String prefix) {
    return '$prefix-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
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

      final journalLines = <JournalEntryLineModel>[];
      int lineNumber = 1;
      
      for (final line in lines) {
        if (line.debitAmount > 0) {
          journalLines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: line.accountId,
            accountName: line.accountName,
            currencyCode: 'SAR',
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
            currencyCode: 'SAR',
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
        referenceType: JournalEntryType.adjusting,
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
  Future<Either<Failure, ClosingResult>> createClosingEntries({
    required DateTime periodEndDate,
    required int retainedEarningsAccountId,
  }) async {
    try {
      // Get all revenue accounts (type = 4) balances
      final revenueQuery = await database.rawQuery('''
        SELECT a.id, a.name, a.balance
        FROM accounts a
        WHERE a.type = 4 AND a.is_active = 1 AND a.is_master = 0
        AND a.balance != 0
      ''');

      // Get all expense accounts (type = 3) balances
      final expenseQuery = await database.rawQuery('''
        SELECT a.id, a.name, a.balance
        FROM accounts a
        WHERE a.type = 3 AND a.is_active = 1 AND a.is_master = 0
        AND a.balance != 0
      ''');

      double totalRevenue = 0;
      double totalExpenses = 0;
      final closingEntries = <int>[];

      // Close revenue accounts (Credit balance -> Debit to close)
      if (revenueQuery.isNotEmpty) {
        final revenueLines = <JournalEntryLineModel>[];
        int lineNumber = 1;

        for (final account in revenueQuery) {
          final balance = (account['balance'] as num?)?.toDouble() ?? 0;
          if (balance.abs() < 0.01) continue;
          
          totalRevenue += balance.abs();
          
          // Debit revenue account to zero it out
          revenueLines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: account['id'] as int,
            accountName: account['name'] as String? ?? '',
            currencyCode: 'SAR',
            debit: balance.abs(),
            credit: 0,
            notes: 'إقفال الإيرادات',
          ));
        }

        if (revenueLines.isNotEmpty) {
          // Credit retained earnings
          revenueLines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: retainedEarningsAccountId,
            accountName: 'الأرباح المحتجزة',
            currencyCode: 'SAR',
            debit: 0,
            credit: totalRevenue,
            notes: 'نقل الإيرادات',
          ));

          final revenueClosingEntry = JournalEntryModel(
            number: _generateJournalNumber('CLOSE-REV'),
            entryDate: periodEndDate,
            description: 'قيد إقفال الإيرادات للفترة المنتهية في ${DateFormat('yyyy-MM-dd').format(periodEndDate)}',
            referenceType: JournalEntryType.closing,
            isPosted: true,
            totalDebit: totalRevenue,
            totalCredit: totalRevenue,
            difference: 0,
            lines: revenueLines,
          );

          final result = await journalRepository.createJournalEntry(revenueClosingEntry);
          result.fold(
            (failure) => null,
            (id) => closingEntries.add(id),
          );
        }
      }

      // Close expense accounts (Debit balance -> Credit to close)
      if (expenseQuery.isNotEmpty) {
        final expenseLines = <JournalEntryLineModel>[];
        int lineNumber = 1;

        for (final account in expenseQuery) {
          final balance = (account['balance'] as num?)?.toDouble() ?? 0;
          if (balance.abs() < 0.01) continue;
          
          totalExpenses += balance.abs();
          
          // Credit expense account to zero it out
          expenseLines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: account['id'] as int,
            accountName: account['name'] as String? ?? '',
            currencyCode: 'SAR',
            debit: 0,
            credit: balance.abs(),
            notes: 'إقفال المصروفات',
          ));
        }

        if (expenseLines.isNotEmpty) {
          // Debit retained earnings
          expenseLines.add(JournalEntryLineModel(
            lineNumber: lineNumber++,
            accountId: retainedEarningsAccountId,
            accountName: 'الأرباح المحتجزة',
            currencyCode: 'SAR',
            debit: totalExpenses,
            credit: 0,
            notes: 'نقل المصروفات',
          ));

          final expenseClosingEntry = JournalEntryModel(
            number: _generateJournalNumber('CLOSE-EXP'),
            entryDate: periodEndDate,
            description: 'قيد إقفال المصروفات للفترة المنتهية في ${DateFormat('yyyy-MM-dd').format(periodEndDate)}',
            referenceType: JournalEntryType.closing,
            isPosted: true,
            totalDebit: totalExpenses,
            totalCredit: totalExpenses,
            difference: 0,
            lines: expenseLines,
          );

          final result = await journalRepository.createJournalEntry(expenseClosingEntry);
          result.fold(
            (failure) => null,
            (id) => closingEntries.add(id),
          );
        }
      }

      final netIncome = totalRevenue - totalExpenses;

      return Right(ClosingResult(
        periodEndDate: periodEndDate,
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        netIncome: netIncome,
        closingEntryIds: closingEntries,
      ));
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
          // Create reversed lines
          final reversedLines = originalEntry.lines.map((line) {
            return JournalEntryLineModel(
              lineNumber: line.lineNumber,
              accountId: line.accountId,
              accountName: line.accountName ?? '',
              currencyCode: line.currencyCode ?? 'SAR',
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
            referenceType: JournalEntryType.reversing,
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
