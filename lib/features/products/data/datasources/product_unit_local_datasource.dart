import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/products/data/models/product_unit_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProductUnitLocalDataSource {
  Future<List<ProductUnitModel>> getAllUnits();
  Future<ProductUnitModel> getUnitById(int id);
  Future<int> insertUnit(ProductUnitModel unit);
  Future<void> updateUnit(ProductUnitModel unit);
  Future<void> deleteUnit(int id);
  Future<List<ProductUnitModel>> searchUnits(String query);
}

class ProductUnitLocalDataSourceImpl implements ProductUnitLocalDataSource {
  static const String _tableName = 'categories_units';
  final Database database;

  ProductUnitLocalDataSourceImpl({required this.database});

  @override
  Future<List<ProductUnitModel>> getAllUnits() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductUnitModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load product units: ${e.toString()}');
    }
  }

  @override
  Future<ProductUnitModel> getUnitById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) {
        throw LocalStorageException('Product unit with id $id not found');
      }
      
      return ProductUnitModel.fromJson(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get product unit: ${e.toString()}');
    }
  }

  @override
  Future<int> insertUnit(ProductUnitModel unit) async {
    try {
      final data = unit.toJson();
      // Ensure timestamps are set
      data['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
      data['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
      
      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert product unit: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUnit(ProductUnitModel unit) async {
    if (unit.id == null) {
      throw LocalStorageException('Product unit id is required for update');
    }
    
    try {
      final count = await database.update(
        _tableName,
        unit.toJson(),
        where: 'id = ?',
        whereArgs: [unit.id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Product unit with id ${unit.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update product unit: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUnit(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Product unit with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete product unit: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductUnitModel>> searchUnits(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ? OR short LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductUnitModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search product units: ${e.toString()}');
    }
  }
}
