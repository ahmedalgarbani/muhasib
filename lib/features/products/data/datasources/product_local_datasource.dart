import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/products/data/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProductById(int id);
  Future<int> insertProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(int id);
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<ProductModel>> getProductsByGroup(int groupId);
  Future<List<ProductModel>> getProductsByStock(int stockId);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  static const String _tableName = 'categories';
  final Database database;

  ProductLocalDataSourceImpl({required this.database});

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load products: ${e.toString()}');
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) {
        throw LocalStorageException('Product with id $id not found');
      }
      
      return ProductModel.fromJson(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get product: ${e.toString()}');
    }
  }

  @override
  Future<int> insertProduct(ProductModel product) async {
    try {
      final data = product.toJson();
      // Ensure timestamps are set
      data['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
      data['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
      
      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert product: ${e.toString()}');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    if (product.id == null) {
      throw LocalStorageException('Product id is required for update');
    }
    
    try {
      final count = await database.update(
        _tableName,
        product.toJson(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Product with id ${product.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update product: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Product with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete product: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ? OR barcode_no LIKE ? OR statement LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search products: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByGroup(int groupId) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to get products by group: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByStock(int stockId) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'stock_id = ?',
        whereArgs: [stockId],
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to get products by stock: ${e.toString()}');
    }
  }
}
