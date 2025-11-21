import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/products/data/models/product_sub_unit_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProductSubUnitLocalDataSource {
  Future<List<ProductSubUnitModel>> getAllSubUnits();
  Future<List<ProductSubUnitModel>> getSubUnitsByProduct(int categoryId);
  Future<ProductSubUnitModel> getSubUnitById(int id);
  Future<int> insertSubUnit(ProductSubUnitModel subUnit);
  Future<void> updateSubUnit(ProductSubUnitModel subUnit);
  Future<void> deleteSubUnit(int id);
  Future<void> setMainUnit(int categoryId, int subUnitId);
}

class ProductSubUnitLocalDataSourceImpl implements ProductSubUnitLocalDataSource {
  static const String _tableName = 'category_sub_units';
  final Database database;

  ProductSubUnitLocalDataSourceImpl({required this.database});

  @override
  Future<List<ProductSubUnitModel>> getAllSubUnits() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'category_id ASC, is_main_unit DESC, packaging ASC',
      );
      return result.map((json) => ProductSubUnitModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load sub units: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductSubUnitModel>> getSubUnitsByProduct(int categoryId) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'is_main_unit DESC, packaging ASC',
      );
      return result.map((json) => ProductSubUnitModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load sub units for product: ${e.toString()}');
    }
  }

  @override
  Future<ProductSubUnitModel> getSubUnitById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) {
        throw LocalStorageException('Sub unit with id $id not found');
      }
      
      return ProductSubUnitModel.fromJson(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get sub unit: ${e.toString()}');
    }
  }

  @override
  Future<int> insertSubUnit(ProductSubUnitModel subUnit) async {
    try {
      // If this is set as main unit, unset others for the same product
      if (subUnit.isMainUnit && subUnit.categoryId != null) {
        await database.update(
          _tableName,
          {'is_main_unit': 0},
          where: 'category_id = ?',
          whereArgs: [subUnit.categoryId],
        );
      }
      
      final data = subUnit.toJson();
      // Ensure timestamps are set
      data['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
      data['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
      
      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert sub unit: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSubUnit(ProductSubUnitModel subUnit) async {
    if (subUnit.id == null) {
      throw LocalStorageException('Sub unit id is required for update');
    }
    
    try {
      // If this is set as main unit, unset others for the same product
      if (subUnit.isMainUnit && subUnit.categoryId != null) {
        await database.update(
          _tableName,
          {'is_main_unit': 0},
          where: 'category_id = ? AND id != ?',
          whereArgs: [subUnit.categoryId, subUnit.id],
        );
      }
      
      final count = await database.update(
        _tableName,
        subUnit.toJson(),
        where: 'id = ?',
        whereArgs: [subUnit.id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Sub unit with id ${subUnit.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update sub unit: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteSubUnit(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Sub unit with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete sub unit: ${e.toString()}');
    }
  }

  @override
  Future<void> setMainUnit(int categoryId, int subUnitId) async {
    try {
      await database.transaction((txn) async {
        // Unset all main units for this product
        await txn.update(
          _tableName,
          {'is_main_unit': 0},
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );
        
        // Set the specified sub unit as main
        await txn.update(
          _tableName,
          {'is_main_unit': 1},
          where: 'id = ? AND category_id = ?',
          whereArgs: [subUnitId, categoryId],
        );
      });
    } catch (e) {
      throw LocalStorageException('Failed to set main unit: ${e.toString()}');
    }
  }
}
