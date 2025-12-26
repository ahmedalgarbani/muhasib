import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/products/data/models/product_price_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProductPriceLocalDataSource {
  Future<List<ProductPriceModel>> getAllPrices();
  Future<List<ProductPriceModel>> getPricesBySubUnit(int subUnitId);
  Future<ProductPriceModel?> getPriceBySubUnitAndLevel(int subUnitId, int priceLevel);
  Future<int> insertPrice(ProductPriceModel price);
  Future<void> updatePrice(ProductPriceModel price);
  Future<void> deletePrice(int id);
  Future<void> deletePricesBySubUnit(int subUnitId);
}

class ProductPriceLocalDataSourceImpl implements ProductPriceLocalDataSource {
  static const String _tableName = 'categories_prices';
  final Database database;

  ProductPriceLocalDataSourceImpl({required this.database});

  @override
  Future<List<ProductPriceModel>> getAllPrices() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'category_sub_unit_id ASC, price_level ASC',
      );
      return result.map((json) => ProductPriceModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load prices: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductPriceModel>> getPricesBySubUnit(int subUnitId) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'category_sub_unit_id = ?',
        whereArgs: [subUnitId],
        orderBy: 'price_level ASC',
      );
      return result.map((json) => ProductPriceModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load prices for sub unit: ${e.toString()}');
    }
  }

  @override
  Future<ProductPriceModel?> getPriceBySubUnitAndLevel(int subUnitId, int priceLevel) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'category_sub_unit_id = ? AND price_level = ?',
        whereArgs: [subUnitId, priceLevel],
        limit: 1,
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return ProductPriceModel.fromJson(result.first);
    } catch (e) {
      throw LocalStorageException('Failed to get price: ${e.toString()}');
    }
  }

  @override
  Future<int> insertPrice(ProductPriceModel price) async {
    try {
      final data = price.toJson();
      // Remove id if null for auto-increment
      if (data['id'] == null) {
        data.remove('id');
      }
      // Set timestamps
      data['creation_time'] ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert price: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePrice(ProductPriceModel price) async {
    if (price.id == null) {
      throw LocalStorageException('Price id is required for update');
    }
    
    try {
      final data = price.toJson();
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final count = await database.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [price.id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Price with id ${price.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update price: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePrice(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Price with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete price: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePricesBySubUnit(int subUnitId) async {
    try {
      await database.delete(
        _tableName,
        where: 'category_sub_unit_id = ?',
        whereArgs: [subUnitId],
      );
    } catch (e) {
      throw LocalStorageException('Failed to delete prices for sub unit: ${e.toString()}');
    }
  }
}
