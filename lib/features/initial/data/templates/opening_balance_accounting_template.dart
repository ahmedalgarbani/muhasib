import 'package:muhasib/core/services/database_service.dart';
import '../../domain/entities/opening_balance_entity.dart';

class OpeningBalanceAccountingTemplate {
  final DatabaseService _database;

  OpeningBalanceAccountingTemplate(this._database);

  /// Creates opening balance entries for all accounts
  /// This creates journal entries for initial balances in the accounting system
  Future<void> createOpeningBalanceEntries({
    required List<OpeningBalanceEntity> openingBalances,
    required DateTime date,
    required String statement,
  }) async {
    try {
      final db = await _database.database;
      await db.transaction((txn) async {
        // Prevent duplicate posting: opening balances are entered once.
        final existing = await txn.query(
          'opening_entries',
          columns: ['id'],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          throw Exception(
            'توجد أرصدة افتتاحية مسجلة مسبقًا. احذف الأرصدة الحالية قبل حفظ أرصدة جديدة.',
          );
        }

        // Enforce accounting principle: total debits must equal total credits.
        final totalDebits = _calculateTotalDebits(openingBalances);
        final totalCredits = _calculateTotalCredits(openingBalances);
        final diff = (totalDebits - totalCredits).abs();
        if (diff >= 0.01) {
          throw Exception('الأرصدة الافتتاحية غير متوازنة (الفرق: $diff)');
        }

        // Create opening entry master record
        final openingEntryId = await txn.insert('opening_entries', {
          'number': await _getNextEntryNumber(txn),
          'date': date.millisecondsSinceEpoch ~/ 1000,
          'statement': statement,
          'status': 2, // Posted (align with opening balance feature)
          'debit_amount': totalDebits,
          'credit_amount': totalCredits,
          'debit_local_amount': totalDebits,
          'credit_local_amount': totalCredits,
        });

        // Create ONE journal entry that contains all lines (clean accounting).
        final journalEntryId = await txn.insert('journal_entries', {
          'number': await _getNextJournalNumber(txn),
          'entry_date': date.millisecondsSinceEpoch ~/ 1000,
          'description': 'قيد افتتاحي',
          'reference_type': 'opening_balance',
          'reference_id': openingEntryId,
          'reference_number': openingEntryId.toString(),
          'status': 2,
          'is_posted': 1,
          'total_debit': totalDebits,
          'total_credit': totalCredits,
          'difference': 0.0,
        });

        int lineNumber = 1;

        // Create opening entry lines + journal lines, then update account balances.
        for (final balance in openingBalances) {
          if (balance.balance == 0) continue;

          final isDebit = balance.balance > 0;
          final amount = balance.balance.abs();
          final exchangeRate = balance.exchangeRate ?? 1.0;

          await txn.insert('opening_entry_lines', {
            'opening_entry_id': openingEntryId,
            'account_id': balance.accountId,
            'amount': amount,
            'local_amount': amount * exchangeRate,
            'type': isDebit ? 1 : 2, // 1 = Debit, 2 = Credit
            'currency_code': balance.currencyCode ?? 'SAR',
            'exchange_rate': exchangeRate,
            'statement': balance.statement ?? 'رصيد افتتاحي',
          });

          await txn.insert('journal_entry_lines', {
            'journal_entry_id': journalEntryId,
            'line_number': lineNumber++,
            'account_id': balance.accountId,
            'account_code': balance.accountCode,
            'account_name': balance.accountName,
            'currency_code': balance.currencyCode ?? 'SAR',
            'debit_amount': isDebit ? amount : 0.0,
            'credit_amount': isDebit ? 0.0 : amount,
            'description': balance.statement ?? 'رصيد افتتاحي',
            'notes': balance.statement,
          });

          await _updateAccountBalance(txn, balance);
        }
      });
    } catch (e) {
      throw Exception('خطأ في إنشاء القيود الافتتاحية: $e');
    }
  }

  /// Applies the opening balance as a delta on top of the existing balance
  /// (never overwrites, to avoid wiping transaction-driven balances).
  Future<void> _updateAccountBalance(
    dynamic txn,
    OpeningBalanceEntity balance,
  ) async {
    final localDelta = balance.balance * (balance.exchangeRate ?? 1.0);
    await txn.rawUpdate(
      'UPDATE accounts '
      'SET balance = balance + ?, local_balance = local_balance + ?, last_modification_time = ? '
      'WHERE id = ?',
      [
        balance.balance,
        localDelta,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        balance.accountId,
      ],
    );
  }

  /// Gets or creates the opening balance equity account
  /// Calculates total debits from opening balances
  double _calculateTotalDebits(List<OpeningBalanceEntity> balances) {
    return balances
        .where((b) => b.balance > 0)
        .fold(0.0, (sum, b) => sum + b.balance);
  }

  /// Calculates total credits from opening balances
  double _calculateTotalCredits(List<OpeningBalanceEntity> balances) {
    return balances
        .where((b) => b.balance < 0)
        .fold(0.0, (sum, b) => sum + b.balance.abs());
  }

  /// Gets the next entry number
  Future<int> _getNextEntryNumber(dynamic txn) async {
    final result = await txn.rawQuery(
      'SELECT MAX(number) as max_number FROM opening_entries',
    );
    final maxNumber = result.first['max_number'] as int?;
    return (maxNumber ?? 0) + 1;
  }

  /// Gets the next journal number
  Future<String> _getNextJournalNumber(dynamic txn) async {
    final result = await txn.rawQuery(
      'SELECT MAX(CAST(number AS INTEGER)) as max_number FROM journal_entries WHERE number NOT LIKE "%-%" AND number IS NOT NULL',
    );
    final maxNumber = result.first['max_number'] as int?;
    return 'OB-${((maxNumber ?? 0) + 1).toString().padLeft(6, '0')}';
  }

  /// Validates opening balances before creating entries
  bool validateOpeningBalances(List<OpeningBalanceEntity> balances) {
    // Check if all required accounts have balances
    for (final balance in balances) {
      if (balance.accountId == 0) {
        return false;
      }
    }
    return true;
  }

  /// Gets opening balance status
  Future<Map<String, dynamic>> getOpeningBalanceStatus() async {
    final db = await _database.database;
    
    final openingEntries = await db.query('opening_entries');
    final hasOpeningBalances = openingEntries.isNotEmpty;
    
    final totalDebits = _calculateTotalFromEntries(openingEntries, 'debit_amount');
    final totalCredits = _calculateTotalFromEntries(openingEntries, 'credit_amount');
    
    return {
      'has_opening_balances': hasOpeningBalances,
      'total_debits': totalDebits,
      'total_credits': totalCredits,
      'is_balanced': (totalDebits - totalCredits).abs() < 0.01,
      'entries_count': openingEntries.length,
    };
  }

  double _calculateTotalFromEntries(List<Map<String, dynamic>> entries, String field) {
    return entries.fold(0.0, (sum, entry) => 
      sum + ((entry[field] as num?)?.toDouble() ?? 0.0));
  }
}
