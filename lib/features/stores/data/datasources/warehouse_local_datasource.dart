import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/stores/data/models/warehouse_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class WarehouseLocalDataSource {
  Future<List<WarehouseModel>> getWarehouses();
  Future<WarehouseModel> getWarehouseById(int id);
  Future<WarehouseModel?> getMainWarehouse();
  Future<List<WarehouseModel>> getActiveWarehouses();
  Future<int> insertWarehouse(WarehouseModel warehouse);
  Future<void> updateWarehouse(WarehouseModel warehouse);
  Future<void> deleteWarehouse(int id);
  Future<void> setMainWarehouse(int id);
  Future<List<WarehouseModel>> searchWarehouses(String query);
}

class WarehouseLocalDataSourceImpl implements WarehouseLocalDataSource {
  static const String _tableName = 'stocks';
  final Database database;

  WarehouseLocalDataSourceImpl({required this.database});

  @override
  Future<List<WarehouseModel>> getWarehouses() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => WarehouseModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load warehouses: ${e.toString()}');
    }
  }

  @override
  Future<WarehouseModel> getWarehouseById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) {
        throw LocalStorageException('Warehouse with id $id not found');
      }
      
      return WarehouseModel.fromMap(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get warehouse: ${e.toString()}');
    }
  }

  @override
  Future<WarehouseModel?> getMainWarehouse() async {
    try {
      final result = await database.query(
        _tableName,
        where: 'is_main_stock = ? AND is_active = ?',
        whereArgs: [1, 1],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      return WarehouseModel.fromMap(result.first);
    } catch (e) {
      throw LocalStorageException('Failed to get main warehouse: ${e.toString()}');
    }
  }

  @override
  Future<List<WarehouseModel>> getActiveWarehouses() async {
    try {
      final result = await database.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return result.map((json) => WarehouseModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load active warehouses: ${e.toString()}');
    }
  }

  @override
  Future<int> insertWarehouse(WarehouseModel warehouse) async {
    try {
      final data = warehouse.toMap();
      // Ensure timestamps are set (in seconds, not milliseconds)
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['creation_time'] ??= nowInSeconds;
      data['last_modification_time'] ??= nowInSeconds;
      
      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert warehouse: ${e.toString()}');
    }
  }

  @override
  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    if (warehouse.id == null) {
      throw LocalStorageException('Warehouse id is required for update');
    }
    
    try {
      final data = warehouse.toMap();
      // Update the last modification time (in seconds)
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final count = await database.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [warehouse.id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Warehouse with id ${warehouse.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update warehouse: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteWarehouse(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Warehouse with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete warehouse: ${e.toString()}');
    }
  }

  @override
  Future<void> setMainWarehouse(int id) async {
    try {
      // First, unset all main warehouses
      await database.update(
        _tableName,
        {'is_main_stock': 0},
        where: 'is_main_stock = ?',
        whereArgs: [1],
      );
      
      // Then set the new main warehouse
      final count = await database.update(
        _tableName,
        {'is_main_stock': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Warehouse with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to set main warehouse: ${e.toString()}');
    }
  }

  @override
  Future<List<WarehouseModel>> searchWarehouses(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ? OR address LIKE ? OR manager_name LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => WarehouseModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search warehouses: ${e.toString()}');
    }
  }
}
