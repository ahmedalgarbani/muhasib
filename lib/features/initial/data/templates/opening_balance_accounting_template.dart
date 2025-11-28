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
        // Create opening entry master record
        final openingEntryId = await txn.insert('opening_entries', {
          'number': await _getNextEntryNumber(txn),
          'date': date.millisecondsSinceEpoch ~/ 1000,
          'statement': statement,
          'status': 1, // Posted
          'debit_amount': _calculateTotalDebits(openingBalances),
          'credit_amount': _calculateTotalCredits(openingBalances),
          'debit_local_amount': _calculateTotalDebits(openingBalances),
          'credit_local_amount': _calculateTotalCredits(openingBalances),
        });

        // Create opening entry lines for each account
        for (final balance in openingBalances) {
          if (balance.balance != 0) {
            await txn.insert('opening_entry_lines', {
              'opening_entry_id': openingEntryId,
              'account_id': balance.accountId,
              'amount': balance.balance.abs(),
              'local_amount': balance.balance.abs(),
              'type': balance.balance > 0 ? 0 : 1, // 0 = Debit, 1 = Credit
              'currency_code': balance.currencyCode ?? 'SAR',
              'exchange_rate': balance.exchangeRate ?? 1.0,
              'statement': balance.statement ?? 'رصيد افتتاحي',
            });

            // Create journal entry for accounting
            await _createJournalEntry(
              txn,
              balance,
              date,
              openingEntryId,
            );

            // Update account balance
            await _updateAccountBalance(txn, balance);
          }
        }

        // Create balancing entry if needed
        await _createBalancingEntry(txn, openingBalances, openingEntryId, date);
      });
    } catch (e) {
      throw Exception('خطأ في إنشاء القيود الافتتاحية: $e');
    }
  }

  /// Creates journal entry for each opening balance
  Future<void> _createJournalEntry(
    dynamic txn,
    OpeningBalanceEntity balance,
    DateTime date,
    int openingEntryId,
  ) async {
    // Create journal entry
    final journalEntryId = await txn.insert('journal_entries', {
      'number': await _getNextJournalNumber(txn),
      'entry_date': date.millisecondsSinceEpoch ~/ 1000,
      'description': 'قيد افتتاحي - ${balance.accountName}',
      'reference_type': 'opening_balance',
      'reference_id': openingEntryId,
      'is_posted': 1,
      'total_debit': balance.balance > 0 ? balance.balance : 0,
      'total_credit': balance.balance < 0 ? balance.balance.abs() : 0,
    });

    // Create journal entry lines
    if (balance.balance > 0) {
      // Debit entry
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': journalEntryId,
        'account_id': balance.accountId,
        'debit_amount': balance.balance,
        'credit_amount': 0,
        'description': 'رصيد افتتاحي مدين',
      });
    } else if (balance.balance < 0) {
      // Credit entry
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': journalEntryId,
        'account_id': balance.accountId,
        'debit_amount': 0,
        'credit_amount': balance.balance.abs(),
        'description': 'رصيد افتتاحي دائن',
      });
    }
  }

  /// Creates a balancing entry to ensure debits equal credits
  Future<void> _createBalancingEntry(
    dynamic txn,
    List<OpeningBalanceEntity> openingBalances,
    int openingEntryId,
    DateTime date,
  ) async {
    final totalDebits = _calculateTotalDebits(openingBalances);
    final totalCredits = _calculateTotalCredits(openingBalances);
    final difference = totalDebits - totalCredits;

    if (difference != 0) {
      // Get or create opening balance equity account
      final equityAccount = await _getOpeningBalanceEquityAccount(txn);
      
      await txn.insert('opening_entry_lines', {
        'opening_entry_id': openingEntryId,
        'account_id': equityAccount['id'],
        'amount': difference.abs(),
        'local_amount': difference.abs(),
        'type': difference > 0 ? 1 : 0, // If debits > credits, credit equity
        'currency_code': 'SAR',
        'exchange_rate': 1.0,
        'statement': 'موازنة القيد الافتتاحي',
      });

      // Create balancing journal entry
      final journalEntryId = await txn.insert('journal_entries', {
        'number': await _getNextJournalNumber(txn),
        'entry_date': date.millisecondsSinceEpoch ~/ 1000,
        'description': 'قيد موازنة الأرصدة الافتتاحية',
        'reference_type': 'opening_balance',
        'reference_id': openingEntryId,
        'is_posted': 1,
        'total_debit': difference > 0 ? 0 : difference.abs(),
        'total_credit': difference > 0 ? difference : 0,
      });

      await txn.insert('journal_entry_lines', {
        'journal_entry_id': journalEntryId,
        'account_id': equityAccount['id'],
        'debit_amount': difference > 0 ? 0 : difference.abs(),
        'credit_amount': difference > 0 ? difference : 0,
        'description': 'موازنة الأرصدة الافتتاحية',
      });
    }
  }

  /// Updates account balance in the accounts table
  Future<void> _updateAccountBalance(
    dynamic txn,
    OpeningBalanceEntity balance,
  ) async {
    await txn.update(
      'accounts',
      {
        'balance': balance.balance,
        'local_balance': balance.balance * (balance.exchangeRate ?? 1.0),
      },
      where: 'id = ?',
      whereArgs: [balance.accountId],
    );
  }

  /// Gets or creates the opening balance equity account
  Future<Map<String, dynamic>> _getOpeningBalanceEquityAccount(
    dynamic txn,
  ) async {
    final accounts = await txn.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['3000'], // Standard opening balance equity account code
    );

    if (accounts.isNotEmpty) {
      return accounts.first;
    }

    // Create opening balance equity account if it doesn't exist
    final accountId = await txn.insert('accounts', {
      'c_id': 3000,
      'code': '3000',
      'name': 'حقوق الملكية - أرصدة افتتاحية',
      'is_master': 0,
      'type': 3, // Equity account type
      'national': 3,
      'statement': 'حساب موازنة الأرصدة الافتتاحية',
      'is_active': 1,
      'balance': 0.0,
      'local_balance': 0.0,
    });

    return {
      'id': accountId,
      'code': '3000',
      'name': 'حقوق الملكية - أرصدة افتتاحية',
    };
  }

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
