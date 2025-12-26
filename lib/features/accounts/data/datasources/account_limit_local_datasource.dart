import 'package:sqflite/sqflite.dart';

import '../../../../core/services/database_service.dart';
import '../models/account_limit_model.dart';

abstract class AccountLimitLocalDataSource {
  Future<List<AccountLimitModel>> getAll();
  Future<AccountLimitModel?> getByAccountAndCurrency({
    required int accountId,
    required int currencyId,
  });
  Future<int> save(AccountLimitModel model);
  Future<void> delete(int id);
  Future<void> updateCurrentUsage({
    required int accountId,
    required int currencyId,
    required double debitChange,
    required double creditChange,
  });
  Future<void> resetUsage({
    required int accountId,
    required int currencyId,
  });
}

class AccountLimitLocalDataSourceImpl implements AccountLimitLocalDataSource {
  static const _table = 'account_limits';
  final DatabaseService databaseService;

  AccountLimitLocalDataSourceImpl({required this.databaseService});

  @override
  Future<List<AccountLimitModel>> getAll() async {
    final db = await databaseService.database;
    final rows = await db.rawQuery('''
      SELECT 
        al.*,
        a.name AS account_name,
        a.code AS account_code,
        c.code AS currency_code
      FROM $_table al
      JOIN accounts a ON a.id = al.account_id
      JOIN currencies c ON c.id = al.currency_id
      ORDER BY a.name, c.code
    ''');

    return rows.map(AccountLimitModel.fromMap).toList();
  }

  @override
  Future<AccountLimitModel?> getByAccountAndCurrency({
    required int accountId,
    required int currencyId,
  }) async {
    final db = await databaseService.database;
    final rows = await db.rawQuery('''
      SELECT 
        al.*,
        a.name AS account_name,
        a.code AS account_code,
        c.code AS currency_code
      FROM $_table al
      JOIN accounts a ON a.id = al.account_id
      JOIN currencies c ON c.id = al.currency_id
      WHERE al.account_id = ? AND al.currency_id = ?
      LIMIT 1
    ''', [accountId, currencyId]);

    if (rows.isEmpty) return null;
    return AccountLimitModel.fromMap(rows.first);
  }

  @override
  Future<int> save(AccountLimitModel model) async {
    final db = await databaseService.database;
    final data = model.toMap();

    return db.transaction((txn) async {
      if (model.id != null) {
        final updated = await txn.update(
          _table,
          data,
          where: 'id = ?',
          whereArgs: [model.id],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        if (updated > 0) return model.id!;
      }

      final updatedByKey = await txn.update(
        _table,
        data,
        where: 'account_id = ? AND currency_id = ?',
        whereArgs: [model.accountId, model.currencyId],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      if (updatedByKey > 0) {
        final existing = await txn.query(
          _table,
          where: 'account_id = ? AND currency_id = ?',
          whereArgs: [model.accountId, model.currencyId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          return existing.first['id'] as int;
        }
      }

      return txn.insert(
        _table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> delete(int id) async {
    final db = await databaseService.database;
    await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateCurrentUsage({
    required int accountId,
    required int currencyId,
    required double debitChange,
    required double creditChange,
  }) async {
    final db = await databaseService.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.rawUpdate(
      '''
      UPDATE $_table
      SET 
        current_debit = current_debit + ?,
        current_credit = current_credit + ?,
        last_modification_time = ?
      WHERE account_id = ? AND currency_id = ?
      ''',
      [debitChange, creditChange, now, accountId, currencyId],
    );
  }

  @override
  Future<void> resetUsage({
    required int accountId,
    required int currencyId,
  }) async {
    final db = await databaseService.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.rawUpdate(
      '''
      UPDATE $_table
      SET 
        current_debit = 0,
        current_credit = 0,
        last_modification_time = ?
      WHERE account_id = ? AND currency_id = ?
      ''',
      [now, accountId, currencyId],
    );
  }
}

