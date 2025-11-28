import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/settings_entities/data/models/cashbox_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class CashboxLocalDataSource {
  Future<List<CashboxModel>> getCashboxes();
  Future<CashboxModel> getCashboxById(int id);
  Future<CashboxModel?> getMainCashbox();
  Future<List<CashboxModel>> getActiveCashboxes();
  Future<int> insertCashbox(CashboxModel cashbox);
  Future<void> updateCashbox(CashboxModel cashbox);
  Future<void> deleteCashbox(int id);
  Future<void> setMainCashbox(int id);
  Future<List<CashboxModel>> searchCashboxes(String query);
}

class CashboxLocalDataSourceImpl implements CashboxLocalDataSource {
  static const String _tableName = 'funds';
  final Database database;

  CashboxLocalDataSourceImpl({required this.database});

  @override
  Future<List<CashboxModel>> getCashboxes() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => CashboxModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load cashboxes: ${e.toString()}');
    }
  }

  @override
  Future<CashboxModel> getCashboxById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw LocalStorageException('Cashbox with id $id not found');
      }

      return CashboxModel.fromMap(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get cashbox: ${e.toString()}');
    }
  }

  @override
  Future<CashboxModel?> getMainCashbox() async {
    try {
      final result = await database.query(
        _tableName,
        where: 'is_main_fund = ? AND is_active = ?',
        whereArgs: [1, 1],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return CashboxModel.fromMap(result.first);
    } catch (e) {
      throw LocalStorageException('Failed to get main cashbox: ${e.toString()}');
    }
  }

  @override
  Future<List<CashboxModel>> getActiveCashboxes() async {
    try {
      final result = await database.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return result.map((json) => CashboxModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load active cashboxes: ${e.toString()}');
    }
  }

  @override
  Future<int> insertCashbox(CashboxModel cashbox) async {
    try {
      final data = cashbox.toMap();
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['creation_time'] ??= nowInSeconds;
      data['last_modification_time'] ??= nowInSeconds;

      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert cashbox: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCashbox(CashboxModel cashbox) async {
    if (cashbox.id == null) {
      throw LocalStorageException('Cashbox id is required for update');
    }

    try {
      final data = cashbox.toMap();
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final count = await database.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [cashbox.id],
      );

      if (count == 0) {
        throw LocalStorageException('Cashbox with id ${cashbox.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update cashbox: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCashbox(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw LocalStorageException('Cashbox with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete cashbox: ${e.toString()}');
    }
  }

  @override
  Future<void> setMainCashbox(int id) async {
    try {
      // First, unset all main cashboxes
      await database.update(
        _tableName,
        {'is_main_fund': 0},
        where: 'is_main_fund = ?',
        whereArgs: [1],
      );

      // Then set the new main cashbox
      final count = await database.update(
        _tableName,
        {'is_main_fund': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw LocalStorageException('Cashbox with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to set main cashbox: ${e.toString()}');
    }
  }

  @override
  Future<List<CashboxModel>> searchCashboxes(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => CashboxModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search cashboxes: ${e.toString()}');
    }
  }
}

