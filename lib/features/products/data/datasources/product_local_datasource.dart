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

  Future<bool> _hasTable(String table) async {
    final result = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return result.isNotEmpty;
  }

  /// Reads products joined with the REAL stock quantity from warehouse_stocks
  /// (the single source of truth; categories.quantity is only a legacy fallback).
  Future<List<Map<String, dynamic>>> _queryProductsWithStock({
    String? whereClause,
    List<Object?>? whereArgs,
    String orderBy = 'c.name ASC',
  }) async {
    if (!await _hasTable('warehouse_stocks')) {
      return database.query(
        _tableName,
        where: whereClause?.replaceAll('c.', ''),
        whereArgs: whereArgs,
        orderBy: orderBy.replaceAll('c.', ''),
      );
    }
    final where = whereClause != null ? 'WHERE $whereClause' : '';
    return database.rawQuery(
      '''
      SELECT c.*, COALESCE(SUM(ws.quantity), 0) AS stock_quantity
      FROM $_tableName c
      LEFT JOIN warehouse_stocks ws ON ws.product_id = c.id
      $where
      GROUP BY c.id
      ORDER BY $orderBy
      ''',
      whereArgs,
    );
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final result = await _queryProductsWithStock(
        whereClause: 'c.is_deleted = 0',
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load products: ${e.toString()}');
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final result = await _queryProductsWithStock(
        whereClause: 'c.id = ?',
        whereArgs: [id],
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
      // Check table availability BEFORE opening the transaction
      // (querying the Database inside a transaction would deadlock)
      final hasWarehouseStocks = await _hasTable('warehouse_stocks');
      final hasJournalTables = await _hasTable('journal_entries');

      return await database.transaction((txn) async {
        final data = product.toJson();
        // Ensure timestamps are set
        data['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
        data['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
        
        final id = await txn.insert(
          _tableName,
          data,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // Initial stock: create warehouse row + movement + opening journal
        final initialQty = product.quantity;
        if (initialQty > 0 && hasWarehouseStocks && hasJournalTables) {
          await _postInitialStock(txn, product, id, initialQty);
        }

        return id;
      });
    } catch (e) {
      throw LocalStorageException('Failed to insert product: ${e.toString()}');
    }
  }

  /// Posts the initial stock of a new product:
  /// - warehouse_stocks row (avg_cost = cost price)
  /// - stock movement (initial_stock)
  /// - opening journal entry: Dr inventory (1003) / Cr opening balance (3100)
  Future<void> _postInitialStock(
    Transaction txn,
    ProductModel product,
    int productId,
    double quantity,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final unitCost = product.costAmount ?? 0.0;

    await txn.insert('warehouse_stocks', {
      'product_id': productId,
      'warehouse_id': product.stockId,
      'quantity': quantity,
      'avg_cost': unitCost,
      'last_cost': unitCost,
      'creation_time': now,
      'last_modification_time': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    try {
      await txn.insert('stock_movements', {
        'product_id': productId,
        'warehouse_id': product.stockId,
        'movement_type': 'initial_stock',
        'quantity': quantity,
        'unit_cost': unitCost,
        'total_cost': quantity * unitCost,
        'balance_after': quantity,
        'reference_type': 'product_creation',
        'reference_id': productId,
        'reference_number': product.barcodeNo,
        'creation_time': now,
      });
    } catch (_) {
      // Ignore if stock_movements table doesn't exist
    }

    // Accounting: opening balance entry (only when a cost exists)
    if (unitCost > 0) {
      final value = quantity * unitCost;
      final inventoryId = await _getOrCreateAccount(
        txn,
        code: '1003',
        cId: 1130,
        name: 'المخزون',
        type: 1,
      );
      final obId = await _getOrCreateAccount(
        txn,
        code: '3100',
        cId: 3100,
        name: 'أرصدة افتتاحية',
        type: 3,
      );

      final entryId = await txn.insert('journal_entries', {
        'number': 'OBP-${DateTime.now().millisecondsSinceEpoch}',
        'entry_date': now,
        'description': 'رصيد افتتاحي - منتج: ${product.name}',
        'reference_type': 'opening_balance',
        'reference_number': product.barcodeNo,
        'reference_id': productId,
        'total_debit': value,
        'total_credit': value,
        'difference': 0.0,
        'status': 2,
        'is_posted': 1,
        'creation_time': now,
        'last_modification_time': now,
      });

      await txn.insert('journal_entry_lines', {
        'journal_entry_id': entryId,
        'line_number': 1,
        'account_id': inventoryId,
        'account_code': '1003',
        'account_name': 'المخزون',
        'debit_amount': value,
        'credit_amount': 0.0,
        'description': 'رصيد افتتاحي مخزون - ${product.name}',
      });
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': entryId,
        'line_number': 2,
        'account_id': obId,
        'account_code': '3100',
        'account_name': 'أرصدة افتتاحية',
        'debit_amount': 0.0,
        'credit_amount': value,
        'description': 'رصيد افتتاحي مخزون - ${product.name}',
      });

      await _applyBalanceDelta(txn, inventoryId, value);
      await _applyBalanceDelta(txn, obId, -value);
    }
  }

  Future<int> _getOrCreateAccount(
    Transaction txn, {
    required String code,
    required int cId,
    required String name,
    required int type,
  }) async {
    final existing = await txn.query(
      'accounts',
      columns: ['id'],
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;

    final byName = await txn.query(
      'accounts',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (byName.isNotEmpty) return byName.first['id'] as int;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return await txn.insert('accounts', {
      'c_id': cId,
      'code': code,
      'name': name,
      'is_master': 0,
      'type': type,
      'national': 1,
      'is_active': 1,
      'allow_update_delete': 0,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': now,
      'last_modification_time': now,
    });
  }

  Future<void> _applyBalanceDelta(
    Transaction txn,
    int accountId,
    double delta,
  ) async {
    final rows = await txn.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = (rows.first['balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = current + delta;
    await txn.update(
      'accounts',
      {
        'balance': newBalance,
        'local_balance': newBalance,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    if (product.id == null) {
      throw LocalStorageException('Product id is required for update');
    }
    
    try {
      final data = product.toJson();
      // Stock is managed exclusively through operations (sales/purchases/
      // transfers/adjustments). Never overwrite it from the product form.
      data.remove('quantity');

      final count = await database.update(
        _tableName,
        data,
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
      final result = await _queryProductsWithStock(
        whereClause: 'c.name LIKE ? OR c.barcode_no LIKE ? OR c.statement LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search products: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByGroup(int groupId) async {
    try {
      final result = await _queryProductsWithStock(
        whereClause: 'c.group_id = ?',
        whereArgs: [groupId],
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to get products by group: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByStock(int stockId) async {
    try {
      final result = await _queryProductsWithStock(
        whereClause: 'c.stock_id = ?',
        whereArgs: [stockId],
      );
      return result.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to get products by stock: ${e.toString()}');
    }
  }
}
