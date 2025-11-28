import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/settings_entities/data/models/other_fee_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class OtherFeeLocalDataSource {
  Future<List<OtherFeeModel>> getOtherFees();
  Future<OtherFeeModel> getOtherFeeById(int id);
  Future<List<OtherFeeModel>> getActiveOtherFees();
  Future<List<OtherFeeModel>> getOtherFeesByType(int toolType);
  Future<int> insertOtherFee(OtherFeeModel otherFee);
  Future<void> updateOtherFee(OtherFeeModel otherFee);
  Future<void> deleteOtherFee(int id);
  Future<List<OtherFeeModel>> searchOtherFees(String query);
}

class OtherFeeLocalDataSourceImpl implements OtherFeeLocalDataSource {
  static const String _tableName = 'other_tools';
  final Database database;

  OtherFeeLocalDataSourceImpl({required this.database});

  @override
  Future<List<OtherFeeModel>> getOtherFees() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => OtherFeeModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load other fees: ${e.toString()}');
    }
  }

  @override
  Future<OtherFeeModel> getOtherFeeById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw LocalStorageException('Other fee with id $id not found');
      }

      return OtherFeeModel.fromMap(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get other fee: ${e.toString()}');
    }
  }

  @override
  Future<List<OtherFeeModel>> getActiveOtherFees() async {
    try {
      final result = await database.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return result.map((json) => OtherFeeModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load active other fees: ${e.toString()}');
    }
  }

  @override
  Future<List<OtherFeeModel>> getOtherFeesByType(int toolType) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'tool_type = ?',
        whereArgs: [toolType],
        orderBy: 'name ASC',
      );
      return result.map((json) => OtherFeeModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load other fees by type: ${e.toString()}');
    }
  }

  @override
  Future<int> insertOtherFee(OtherFeeModel otherFee) async {
    try {
      final data = otherFee.toMap();
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['creation_time'] ??= nowInSeconds;
      data['last_modification_time'] ??= nowInSeconds;

      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert other fee: ${e.toString()}');
    }
  }

  @override
  Future<void> updateOtherFee(OtherFeeModel otherFee) async {
    if (otherFee.id == null) {
      throw LocalStorageException('Other fee id is required for update');
    }

    try {
      final data = otherFee.toMap();
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final count = await database.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [otherFee.id],
      );

      if (count == 0) {
        throw LocalStorageException('Other fee with id ${otherFee.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update other fee: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteOtherFee(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw LocalStorageException('Other fee with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete other fee: ${e.toString()}');
    }
  }

  @override
  Future<List<OtherFeeModel>> searchOtherFees(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => OtherFeeModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search other fees: ${e.toString()}');
    }
  }
}

