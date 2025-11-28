import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/settings_entities/data/models/bank_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class BankLocalDataSource {
  Future<List<BankModel>> getBanks();
  Future<BankModel> getBankById(int id);
  Future<List<BankModel>> getActiveBanks();
  Future<int> insertBank(BankModel bank);
  Future<void> updateBank(BankModel bank);
  Future<void> deleteBank(int id);
  Future<List<BankModel>> searchBanks(String query);
}

class BankLocalDataSourceImpl implements BankLocalDataSource {
  static const String _tableName = 'banks';
  final Database database;

  BankLocalDataSourceImpl({required this.database});

  @override
  Future<List<BankModel>> getBanks() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => BankModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load banks: ${e.toString()}');
    }
  }

  @override
  Future<BankModel> getBankById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw LocalStorageException('Bank with id $id not found');
      }

      return BankModel.fromMap(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get bank: ${e.toString()}');
    }
  }

  @override
  Future<List<BankModel>> getActiveBanks() async {
    try {
      final result = await database.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return result.map((json) => BankModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load active banks: ${e.toString()}');
    }
  }

  @override
  Future<int> insertBank(BankModel bank) async {
    try {
      final data = bank.toMap();
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['creation_time'] ??= nowInSeconds;
      data['last_modification_time'] ??= nowInSeconds;

      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert bank: ${e.toString()}');
    }
  }

  @override
  Future<void> updateBank(BankModel bank) async {
    if (bank.id == null) {
      throw LocalStorageException('Bank id is required for update');
    }

    try {
      final data = bank.toMap();
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final count = await database.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [bank.id],
      );

      if (count == 0) {
        throw LocalStorageException('Bank with id ${bank.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update bank: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteBank(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw LocalStorageException('Bank with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete bank: ${e.toString()}');
    }
  }

  @override
  Future<List<BankModel>> searchBanks(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ? OR bank_code LIKE ? OR branch_name LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => BankModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search banks: ${e.toString()}');
    }
  }
}

