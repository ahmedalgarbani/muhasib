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
        where: 'is_deleted = 0',
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
      // Check 1: Verify product exists
      final product = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (product.isEmpty) {
        throw LocalStorageException('المنتج غير موجود');
      }
      
      // Check 2: Check if product has invoice lines
      final invoiceLines = await database.rawQuery(
        'SELECT COUNT(*) as count FROM invoice_lines WHERE category_id = ?',
        [id],
      );
      final invoiceCount = (invoiceLines.first['count'] as int?) ?? 0;
      if (invoiceCount > 0) {
        throw LocalStorageException(
          'لا يمكن حذف المنتج - مستخدم في $invoiceCount فاتورة. يمكنك تعطيله بدلاً من ذلك.'
        );
      }
      
      // Check 3: Check if product has stock movements
      try {
        final movements = await database.rawQuery(
          'SELECT COUNT(*) as count FROM stock_movements WHERE product_id = ?',
          [id],
        );
        final movementCount = (movements.first['count'] as int?) ?? 0;
        if (movementCount > 0) {
          throw LocalStorageException(
            'لا يمكن حذف المنتج - يوجد $movementCount حركة مخزون. يمكنك تعطيله بدلاً من ذلك.'
          );
        }
      } catch (e) {
        // Ignore if stock_movements table doesn't exist
        if (!e.toString().contains('no such table')) rethrow;
      }
      
      // Check 4: Check if product has quantity in any warehouse
      try {
        final stocks = await database.rawQuery(
          'SELECT SUM(quantity) as total FROM warehouse_stocks WHERE product_id = ? AND quantity != 0',
          [id],
        );
        final totalQty = (stocks.first['total'] as num?)?.toDouble() ?? 0.0;
        if (totalQty.abs() > 0.001) {
          throw LocalStorageException(
            'لا يمكن حذف المنتج - يوجد كمية في المخزون ($totalQty). يجب تصفير الكمية أولاً.'
          );
        }
      } catch (e) {
        // Ignore if warehouse_stocks table doesn't exist
        if (!e.toString().contains('no such table')) rethrow;
      }
      
      // Safe to delete - use soft delete
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await database.update(
        _tableName,
        {
          'is_deleted': 1,
          'is_active': 0,
          'deleted_at': now,
          'last_modification_time': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('فشل في حذف المنتج: ${e.toString()}');
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
