import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account_model.dart';

abstract class AccountLocalDataSource {
  Future<List<AccountModel>> getAllAccounts();
  Future<AccountModel> getAccountById(int id);
  Future<AccountModel> getAccountByCId(int cId);
  Future<List<AccountModel>> getAccountsByType(int type);
  Future<List<AccountModel>> getMasterAccounts();
  Future<List<AccountModel>> getSubAccounts(int masterId);
  Future<int> insertAccount(AccountModel account);
  Future<int> updateAccount(AccountModel account);
  Future<int> deleteAccount(int id);
  Future<List<AccountModel>> searchAccounts(String query);
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  final Database database;
  final String tableName = AccountsTable().tableName;

  AccountLocalDataSourceImpl(this.database);

  @override
  Future<List<AccountModel>> getAllAccounts() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        orderBy: 'code ASC',
      );
      return maps.map((map) => AccountModel.fromJson(map)).toList();
    } catch (e) {
      throw LocalStorageException(
        'Failed to get all accounts: ${e.toString()}',
      );
    }
  }

  @override
  Future<AccountModel> getAccountById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw LocalStorageException('Account with id $id not found');
      }

      return AccountModel.fromJson(maps.first);
    } catch (e) {
      throw LocalStorageException(
        'Failed to get account by id: ${e.toString()}',
      );
    }
  }

  @override
  Future<AccountModel> getAccountByCId(int cId) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'c_id = ?',
        whereArgs: [cId],
      );

      if (maps.isEmpty) {
        throw LocalStorageException('Account with c_id $cId not found');
      }

      return AccountModel.fromJson(maps.first);
    } catch (e) {
      throw LocalStorageException(
        'Failed to get account by c_id: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AccountModel>> getAccountsByType(int type) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'code ASC',
      );
      return maps.map((map) => AccountModel.fromJson(map)).toList();
    } catch (e) {
      throw LocalStorageException(
        'Failed to get accounts by type: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AccountModel>> getMasterAccounts() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'is_master = ?',
        whereArgs: [1],
        orderBy: 'code ASC',
      );
      return maps.map((map) => AccountModel.fromJson(map)).toList();
    } catch (e) {
      throw LocalStorageException(
        'Failed to get master accounts: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AccountModel>> getSubAccounts(int masterId) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'master_id = ?',
        whereArgs: [masterId],
        orderBy: 'code ASC',
      );
      return maps.map((map) => AccountModel.fromJson(map)).toList();
    } catch (e) {
      throw LocalStorageException(
        'Failed to get sub accounts: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> insertAccount(AccountModel account) async {
    try {
      final data = account.toJson();
      // Ensure timestamps are set
      data['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
      data['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
      
      final id = await database.insert(
        tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id;
    } catch (e) {
      throw LocalStorageException('Failed to insert account: ${e.toString()}');
    }
  }

  @override
  Future<int> updateAccount(AccountModel account) async {
    try {
      final count = await database.update(
        tableName,
        account.toJson(),
        where: 'id = ?',
        whereArgs: [account.id],
      );

      if (count == 0) {
        throw LocalStorageException('Account with id ${account.id} not found');
      }

      return count;
    } catch (e) {
      throw LocalStorageException('Failed to update account: ${e.toString()}');
    }
  }

  @override
  Future<int> deleteAccount(int id) async {
    try {
      final count = await database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw LocalStorageException('Account with id $id not found');
      }

      return count;
    } catch (e) {
      throw LocalStorageException('Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Future<List<AccountModel>> searchAccounts(String query) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'name LIKE ? OR code LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'code ASC',
      );
      return maps.map((map) => AccountModel.fromJson(map)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search accounts: ${e.toString()}');
    }
  }
}
