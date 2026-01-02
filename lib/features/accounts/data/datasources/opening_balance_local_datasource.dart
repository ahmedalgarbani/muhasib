import 'package:sqflite/sqflite.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/accounts/data/models/opening_balance_model.dart';

abstract class OpeningBalanceLocalDataSource {
  Future<List<OpeningBalanceModel>> getAllOpeningBalances();
  Future<OpeningBalanceModel> getOpeningBalanceById(int id);
  Future<int> createOpeningBalance(OpeningBalanceModel openingBalance);
  Future<void> updateOpeningBalance(OpeningBalanceModel openingBalance);
  Future<void> deleteOpeningBalance(int id);
  Future<void> postOpeningBalance(int id);
  Future<String> generateNextNumber();
}

class OpeningBalanceLocalDataSourceImpl implements OpeningBalanceLocalDataSource {
  static const _entriesTable = 'opening_entries';
  static const _linesTable = 'opening_entry_lines';
  static const _accountsTable = 'accounts';
  static const _journalEntries = 'journal_entries';
  static const _journalLines = 'journal_entry_lines';

  final DatabaseService databaseService;

  OpeningBalanceLocalDataSourceImpl({required this.databaseService});

  @override
  Future<List<OpeningBalanceModel>> getAllOpeningBalances() async {
    final db = await databaseService.database;

    final entries = await db.query(
      _entriesTable,
      orderBy: 'date DESC, id DESC',
    );

    final List<OpeningBalanceModel> openingBalances = [];

    for (final entry in entries) {
      final lines = await db.rawQuery(
        '''
        SELECT l.*, a.code AS account_code, a.name AS account_name
        FROM $_linesTable l
        LEFT JOIN $_accountsTable a ON a.id = l.account_id
        WHERE l.opening_entry_id = ?
        ORDER BY l.line_number
        ''',
        [entry['id']],
      );

      final lineModels =
          lines.map((line) => OpeningBalanceLineModel.fromMap(line)).toList();
      openingBalances.add(OpeningBalanceModel.fromMap(entry, lineModels));
    }

    return openingBalances;
  }

  @override
  Future<OpeningBalanceModel> getOpeningBalanceById(int id) async {
    final db = await databaseService.database;

    final entries = await db.query(
      _entriesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (entries.isEmpty) {
      throw Exception('Opening balance not found');
    }

    final lines = await db.rawQuery(
      '''
      SELECT l.*, a.code AS account_code, a.name AS account_name
      FROM $_linesTable l
      LEFT JOIN $_accountsTable a ON a.id = l.account_id
      WHERE l.opening_entry_id = ?
      ORDER BY l.line_number
      ''',
      [id],
    );

    final lineModels =
        lines.map((line) => OpeningBalanceLineModel.fromMap(line)).toList();
    return OpeningBalanceModel.fromMap(entries.first, lineModels);
  }

  @override
  Future<int> createOpeningBalance(OpeningBalanceModel openingBalance) async {
    final db = await databaseService.database;

    return await db.transaction((txn) async {
      final entryId = await txn.insert(
        _entriesTable,
        openingBalance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final line in openingBalance.lines) {
        final model = line as OpeningBalanceLineModel;
        await txn.insert(
          _linesTable,
          model.toMap(entryId),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      if (openingBalance.isPosted) {
        for (final line in openingBalance.lines) {
          await _updateAccountBalance(
            txn,
            line.accountId,
            line.debit - line.credit,
          );
        }
        await _createJournalEntryFromOpening(txn, entryId, openingBalance);
      }

      return entryId;
    });
  }

  @override
  Future<void> updateOpeningBalance(OpeningBalanceModel openingBalance) async {
    if (openingBalance.id == null) {
      throw Exception('Cannot update opening balance without ID');
    }

    final db = await databaseService.database;
    
    // Get old entry first
    final oldEntry = await getOpeningBalanceById(openingBalance.id!);
    
    // ===== PROTECTION: Prevent modification of posted opening balance if transactions exist =====
    if (oldEntry.isPosted) {
      // Check if there are any journal entries after the opening balance date
      final hasTransactionsAfter = await db.rawQuery('''
        SELECT COUNT(*) as count FROM journal_entries 
        WHERE entry_date > ? 
        AND reference_type != 'opening_entry'
        AND is_posted = 1
      ''', [oldEntry.entryDate.millisecondsSinceEpoch ~/ 1000]);
      
      final count = (hasTransactionsAfter.first['count'] as int?) ?? 0;
      if (count > 0) {
        throw Exception(
          'لا يمكن تعديل الرصيد الافتتاحي المرحل لوجود $count معاملة/معاملات بعد تاريخه. '
          'يرجى إنشاء قيد تسوية بدلاً من ذلك.'
        );
      }
    }
    // ===========================================================================================

    await db.transaction((txn) async {
      // If old entry was posted, reverse its effect first
      if (oldEntry.isPosted) {
        for (final line in oldEntry.lines) {
          await _updateAccountBalance(
            txn,
            line.accountId,
            -(line.debit - line.credit),
          );
        }
        
        // Delete old journal entry if exists
        await txn.delete(
          _journalEntries,
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['opening_entry', openingBalance.id],
        );
      }

      await txn.update(
        _entriesTable,
        openingBalance.toMap(),
        where: 'id = ?',
        whereArgs: [openingBalance.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await txn.delete(
        _linesTable,
        where: 'opening_entry_id = ?',
        whereArgs: [openingBalance.id],
      );

      for (final line in openingBalance.lines) {
        final model = line as OpeningBalanceLineModel;
        await txn.insert(
          _linesTable,
          model.toMap(openingBalance.id!),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      if (openingBalance.isPosted) {
        for (final line in openingBalance.lines) {
          await _updateAccountBalance(
            txn,
            line.accountId,
            line.debit - line.credit,
          );
        }
        
        // Create new journal entry for the updated opening balance
        await _createJournalEntryFromOpening(txn, openingBalance.id!, openingBalance);
      }
    });
  }

  @override
  Future<void> deleteOpeningBalance(int id) async {
    final db = await databaseService.database;
    
    // Get entry first
    final entry = await getOpeningBalanceById(id);
    
    // ===== PROTECTION: Prevent deletion of posted opening balance if transactions exist =====
    if (entry.isPosted) {
      // Check if there are any journal entries after the opening balance date
      final hasTransactionsAfter = await db.rawQuery('''
        SELECT COUNT(*) as count FROM journal_entries 
        WHERE entry_date > ? 
        AND reference_type != 'opening_entry'
        AND is_posted = 1
      ''', [entry.entryDate.millisecondsSinceEpoch ~/ 1000]);
      
      final count = (hasTransactionsAfter.first['count'] as int?) ?? 0;
      if (count > 0) {
        throw Exception(
          'لا يمكن حذف الرصيد الافتتاحي المرحل لوجود $count معاملة/معاملات بعد تاريخه. '
          'هذا سيؤدي إلى أرصدة سالبة غير صحيحة.'
        );
      }
    }
    // ===========================================================================================

    await db.transaction((txn) async {
      // Reverse account balances if posted
      if (entry.isPosted) {
        for (final line in entry.lines) {
          await _updateAccountBalance(
            txn,
            line.accountId,
            -(line.debit - line.credit),
          );
        }
        
        // Delete related journal entry
        await txn.delete(
          _journalEntries,
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['opening_entry', id],
        );
      }

      // Delete opening entry lines (cascade should handle this, but explicit is safer)
      await txn.delete(
        _linesTable,
        where: 'opening_entry_id = ?',
        whereArgs: [id],
      );

      // Delete opening entry
      await txn.delete(
        _entriesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> postOpeningBalance(int id) async {
    final db = await databaseService.database;

    await db.transaction((txn) async {
      final entry = await getOpeningBalanceById(id);

      if (entry.isPosted) {
        throw Exception('Opening balance is already posted');
      }
      if (!entry.isBalanced) {
        throw Exception('Cannot post unbalanced entry. Debit must equal Credit.');
      }

      await txn.update(
        _entriesTable,
        {
          'status': 2,
          'last_modification_time':
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      for (final line in entry.lines) {
        await _updateAccountBalance(
          txn,
          line.accountId,
          line.debit - line.credit,
        );
      }

      await _createJournalEntryFromOpening(txn, id, entry);
    });
  }

  @override
  Future<String> generateNextNumber() async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      'SELECT MAX(number) as max_num FROM $_entriesTable',
    );

    int nextNumber = 1;
    if (result.isNotEmpty && result.first['max_num'] != null) {
      final maxNum = result.first['max_num'];
      if (maxNum is int) {
        nextNumber = maxNum + 1;
      } else if (maxNum is num) {
        nextNumber = maxNum.toInt() + 1;
      } else if (maxNum is String) {
        nextNumber = int.tryParse(maxNum) ?? 1;
      }
    }

    return nextNumber.toString().padLeft(6, '0');
  }

  Future<void> _updateAccountBalance(
    Transaction txn,
    int accountId,
    double amount,
  ) async {
    final accounts = await txn.query(
      _accountsTable,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (accounts.isEmpty) {
      throw Exception('Account not found');
    }

    final currentBalance = (accounts.first['balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = currentBalance + amount;

    await txn.update(
      _accountsTable,
      {
        'balance': newBalance,
        'local_balance': newBalance,
        'last_modification_time':
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> _createJournalEntryFromOpening(
    Transaction txn,
    int openingEntryId,
    OpeningBalanceModel openingBalance,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final journalId = await txn.insert(
      _journalEntries,
      {
        'number': 'OB-${openingBalance.number}',
        'entry_date': openingBalance.entryDate.millisecondsSinceEpoch ~/ 1000,
        'description': openingBalance.description ?? 'رصيد افتتاحي',
        'reference_type': 'opening_entry',
        'reference_id': openingEntryId,
        'reference_number': openingBalance.number,
        'notes': openingBalance.notes,
        'status': 2,
        'is_posted': 1,
        'total_debit': openingBalance.totalDebit,
        'total_credit': openingBalance.totalCredit,
        'difference': 0,
        'creation_time': now,
        'last_modification_time': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    int lineNumber = 1;
    for (final line in openingBalance.lines) {
      await txn.insert(
        _journalLines,
        {
          'journal_entry_id': journalId,
          'line_number': lineNumber++,
          'account_id': line.accountId,
          'account_code': line.accountCode,
          'account_name': line.accountName,
          'currency_id': line.currencyId,
          'currency_code': line.currencyCode,
            'debit_amount': line.debit,
            'credit_amount': line.credit,
          'notes': line.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }
}

