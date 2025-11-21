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
  final DatabaseService databaseService;

  OpeningBalanceLocalDataSourceImpl({required this.databaseService});

  @override
  Future<List<OpeningBalanceModel>> getAllOpeningBalances() async {
    final db = await databaseService.database;
    
    // Get all journal entries that are opening balances
    final entries = await db.query(
      'journal_entries',
      where: 'description LIKE ?',
      whereArgs: ['%رصيد افتتاحي%'],
      orderBy: 'entry_date DESC, id DESC',
    );

    final List<OpeningBalanceModel> openingBalances = [];
    
    for (final entry in entries) {
      // Get lines for this entry
      final lines = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [entry['id']],
        orderBy: 'line_number',
      );
      
      final lineModels = lines.map((line) => OpeningBalanceLineModel.fromMap(line)).toList();
      openingBalances.add(OpeningBalanceModel.fromMap(entry, lineModels));
    }
    
    return openingBalances;
  }

  @override
  Future<OpeningBalanceModel> getOpeningBalanceById(int id) async {
    final db = await databaseService.database;
    
    final entries = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (entries.isEmpty) {
      throw Exception('Opening balance not found');
    }
    
    final lines = await db.query(
      'journal_entry_lines',
      where: 'journal_entry_id = ?',
      whereArgs: [id],
      orderBy: 'line_number',
    );
    
    final lineModels = lines.map((line) => OpeningBalanceLineModel.fromMap(line)).toList();
    return OpeningBalanceModel.fromMap(entries.first, lineModels);
  }

  @override
  Future<int> createOpeningBalance(OpeningBalanceModel openingBalance) async {
    final db = await databaseService.database;
    
    return await db.transaction((txn) async {
      // Insert journal entry
      final entryId = await txn.insert(
        'journal_entries',
        {
          ...openingBalance.toMap(),
          'reference_number': 'OB-${openingBalance.number}',
        },
      );
      
      // Insert journal entry lines
      for (int i = 0; i < openingBalance.lines.length; i++) {
        final line = openingBalance.lines[i] as OpeningBalanceLineModel;
        await txn.insert(
          'journal_entry_lines',
          line.toMap(entryId),
        );
        
        // Update account balance if posted
        if (openingBalance.isPosted) {
          await _updateAccountBalance(txn, line.accountId, line.debit - line.credit);
        }
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
    
    await db.transaction((txn) async {
      // Get old entry to reverse balances if posted
      final oldEntry = await getOpeningBalanceById(openingBalance.id!);
      
      if (oldEntry.isPosted) {
        // Reverse old balances
        for (final line in oldEntry.lines) {
          await _updateAccountBalance(txn, line.accountId, -(line.debit - line.credit));
        }
      }
      
      // Update journal entry
      await txn.update(
        'journal_entries',
        openingBalance.toMap(),
        where: 'id = ?',
        whereArgs: [openingBalance.id],
      );
      
      // Delete old lines
      await txn.delete(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [openingBalance.id],
      );
      
      // Insert new lines
      for (int i = 0; i < openingBalance.lines.length; i++) {
        final line = openingBalance.lines[i] as OpeningBalanceLineModel;
        await txn.insert(
          'journal_entry_lines',
          line.toMap(openingBalance.id!),
        );
        
        // Update account balance if posted
        if (openingBalance.isPosted) {
          await _updateAccountBalance(txn, line.accountId, line.debit - line.credit);
        }
      }
    });
  }

  @override
  Future<void> deleteOpeningBalance(int id) async {
    final db = await databaseService.database;
    
    await db.transaction((txn) async {
      // Get entry to reverse balances if posted
      final entry = await getOpeningBalanceById(id);
      
      if (entry.isPosted) {
        // Reverse balances
        for (final line in entry.lines) {
          await _updateAccountBalance(txn, line.accountId, -(line.debit - line.credit));
        }
      }
      
      // Delete entry (lines will be cascade deleted)
      await txn.delete(
        'journal_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> postOpeningBalance(int id) async {
    final db = await databaseService.database;
    
    await db.transaction((txn) async {
      // Get the opening balance
      final entry = await getOpeningBalanceById(id);
      
      if (entry.isPosted) {
        throw Exception('Opening balance is already posted');
      }
      
      if (!entry.isBalanced) {
        throw Exception('Cannot post unbalanced entry. Debit must equal Credit.');
      }
      
      // Update status to posted
      await txn.update(
        'journal_entries',
        {
          'is_posted': 1,
          'status': 2, // Posted status
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Update account balances
      for (final line in entry.lines) {
        await _updateAccountBalance(txn, line.accountId, line.debit - line.credit);
      }
    });
  }

  @override
  Future<String> generateNextNumber() async {
    final db = await databaseService.database;
    
    // Get the last opening balance number
    final result = await db.rawQuery('''
      SELECT MAX(CAST(SUBSTR(number, 4) AS INTEGER)) as max_num 
      FROM journal_entries 
      WHERE number LIKE 'OB-%'
    ''');
    
    int nextNumber = 1;
    if (result.isNotEmpty && result.first['max_num'] != null) {
      nextNumber = (result.first['max_num'] as int) + 1;
    }
    
    return 'OB-${nextNumber.toString().padLeft(6, '0')}';
  }

  Future<void> _updateAccountBalance(Transaction txn, int accountId, double amount) async {
    // Get current balance
    final accounts = await txn.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    
    if (accounts.isEmpty) {
      throw Exception('Account not found');
    }
    
    final currentBalance = accounts.first['balance'] as double? ?? 0.0;
    final newBalance = currentBalance + amount;
    
    // Update balance
    await txn.update(
      'accounts',
      {
        'balance': newBalance,
        'local_balance': newBalance,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }
}
