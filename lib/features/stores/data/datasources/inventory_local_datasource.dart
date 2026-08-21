import 'package:muhasib/features/stores/data/models/inventory_model.dart';
import 'package:muhasib/features/stores/data/models/inventory_line_model.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:sqflite/sqflite.dart';

abstract class InventoryLocalDataSource {
  Future<List<InventoryModel>> getInventories();
  Future<List<InventoryModel>> getInventoriesByWarehouse(int warehouseId);
  Future<InventoryModel> getInventory(int id);
  Future<int> createInventory(InventoryModel inventory);
  Future<void> updateInventory(InventoryModel inventory);
  Future<void> postInventory(int id);
  Future<void> deleteInventory(int id);
  Future<double> getProductQuantityInWarehouse(int productId, int warehouseId);
  Future<Map<int, double>> getWarehouseStockMap(int warehouseId);
  Future<List<InventoryLineEntity>> getCurrentStockLines(int warehouseId);
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final Database database;

  InventoryLocalDataSourceImpl({required this.database});

  @override
  Future<List<InventoryModel>> getInventories() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'inventories',
      orderBy: 'date DESC',
    );

    List<InventoryModel> inventories = [];
    for (var map in maps) {
      final lines = await _getInventoryLines(map['id']);
      inventories.add(InventoryModel.fromMap(map, lines: lines.cast<InventoryLineEntity>()));
    }
    return inventories;
  }

  @override
  Future<List<InventoryModel>> getInventoriesByWarehouse(int warehouseId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'inventories',
      where: 'stock_id = ?',
      whereArgs: [warehouseId],
      orderBy: 'date DESC',
    );

    List<InventoryModel> inventories = [];
    for (var map in maps) {
      final lines = await _getInventoryLines(map['id']);
      inventories.add(InventoryModel.fromMap(map, lines: lines.cast<InventoryLineEntity>()));
    }
    return inventories;
  }

  @override
  Future<InventoryModel> getInventory(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'inventories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      throw Exception('Inventory not found');
    }

    final lines = await _getInventoryLines(id);
    return InventoryModel.fromMap(maps.first, lines: lines.cast<InventoryLineEntity>());
  }

  @override
  Future<int> createInventory(InventoryModel inventory) async {
    return await database.transaction((txn) async {
      final id = await txn.insert('inventories', inventory.toMap());
      
      // Insert inventory lines
      if (inventory.lines.isNotEmpty) {
        for (var line in inventory.lines) {
          final lineModel =
              line is InventoryLineModel ? line : InventoryLineModel.fromEntity(line);
          await txn.insert(
            'inventory_lines',
            {...lineModel.toMap(), 'inventory_id': id},
          );
        }
      }
      
      return id;
    });
  }

  @override
  Future<void> updateInventory(InventoryModel inventory) async {
    if (inventory.id != null) {
      final existing = await getInventory(inventory.id!);
      if (existing.status == TransferStatus.completed) {
        throw Exception('لا يمكن تعديل جرد مرحّل');
      }
    }

    await database.transaction((txn) async {
      await txn.update(
        'inventories',
        inventory.toMap(),
        where: 'id = ?',
        whereArgs: [inventory.id],
      );

      // Delete existing lines
      await txn.delete(
        'inventory_lines',
        where: 'inventory_id = ?',
        whereArgs: [inventory.id],
      );

      // Insert updated lines
      if (inventory.lines.isNotEmpty) {
        for (var line in inventory.lines) {
          final lineModel =
              line is InventoryLineModel ? line : InventoryLineModel.fromEntity(line);
          await txn.insert(
            'inventory_lines',
            {...lineModel.toMap(), 'inventory_id': inventory.id},
          );
        }
      }
    });
  }

  @override
  Future<void> postInventory(int id) async {
    await database.transaction((txn) async {
      // Re-fetch inventory inside transaction (snapshot consistency + double-post guard)
      final headerMaps = await txn.query(
        'inventories',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (headerMaps.isEmpty) throw Exception('Inventory not found');
      final status = TransferStatus.fromValue(
          headerMaps.first['status'] as int? ?? 0);
      if (status == TransferStatus.completed) {
        throw Exception('تم ترحيل هذا الجرد مسبقاً');
      }
      // Fetch lines inside txn for consistency
      final lineMaps = await txn.query(
        'inventory_lines',
        where: 'inventory_id = ?',
        whereArgs: [id],
      );
      final lines = lineMaps
          .map((m) => InventoryLineModel.fromMap(m))
          .toList()
          .cast<InventoryLineEntity>();
      final inventoryHeader = InventoryModel.fromMap(
          headerMaps.first, lines: lines);
      // Use inventoryHeader for number/stockId, but lines already fetched
      final inventory = inventoryHeader;

      // Update inventory status to posted
      await txn.update(
        'inventories',
        {
          'status': TransferStatus.completed.value,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      double totalIncrease = 0.0;
      double totalDecrease = 0.0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create stock settlements for differences
      for (var line in inventory.lines) {
        // Authoritative system quantity from warehouse_stocks
        final stockRow = await txn.query(
          'warehouse_stocks',
          columns: ['quantity', 'avg_cost'],
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [line.categoryId ?? 0, inventory.stockId],
          limit: 1,
        );
        final systemQty = stockRow.isNotEmpty
            ? (stockRow.first['quantity'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        final currentAvg = stockRow.isNotEmpty
            ? (stockRow.first['avg_cost'] as num?)?.toDouble() ?? 0.0
            : 0.0;

        final difference = line.actualQuantity - systemQty;
        if (difference.abs() < 0.0001) continue;

        final adjType = difference > 0 ? 0 : 1; // increase/decrease
        // Accounting correctness: shortage must be valued at book avg, not counted cost
        double unitCost;
        if (difference > 0) {
          // Increase: use counted cost if provided, else book avg
          unitCost = (line.costAmount != null && line.costAmount! > 0)
              ? line.costAmount!
              : (currentAvg > 0 ? currentAvg : 0);
        } else {
          // Decrease: always at book average cost (if available)
          unitCost = currentAvg > 0
              ? currentAvg
              : ((line.costAmount != null && line.costAmount! > 0)
                  ? line.costAmount!
                  : 0);
        }
        final differenceValue = unitCost * difference.abs();
        
        if (difference > 0) {
          totalIncrease += differenceValue;
        } else {
          totalDecrease += differenceValue;
        }

        final settlementId = await txn.insert('stock_settlements', {
          'number': 'ADJ-INV-$id-${line.categoryId ?? 0}',
          'date': now,
          'type': adjType,
          'total_amount': differenceValue,
          'currency_code': null,
          'exchange_rate': null,
          'currency_id': 1,
          'statement': 'تسوية جرد المخزون',
          'parent_number': inventory.number,
          'parent_id': id,
          'status': TransferStatus.completed.value,
          'stock_id': inventory.stockId,
          'u_no': null,
          'settlement_reason': 'inventory',
        });

        await txn.insert('stock_settlement_lines', {
          'category_id': line.categoryId ?? 0,
          'group_id': line.groupId,
          'unit_id': line.unitId,
          'category_sub_unit_id': line.categorySubUnitId,
          'quantity': difference.abs(),
          'statement': line.statement,
          'amount': unitCost,
          'total_amount': differenceValue,
          'currency_code': null,
          'exchange_rate': null,
          'currency_id': 1,
          'stock_id': inventory.stockId ?? 0,
          'stock_settlement_id': settlementId,
          'expire_date': null,
          'reason': 'الفرق في الجرد',
        });

        final newQty = systemQty + difference;
        if (newQty < -0.0001) {
          throw Exception(
              'كمية النقص للمنتج ${line.statement} أكبر من المتاح ($systemQty)');
        }
        // Prevent inserting negative quantity for new product
        if (stockRow.isEmpty && difference < -0.0001) {
          throw Exception(
              'لا يمكن تسجيل نقص لمنتج غير موجود في هذا المخزن: ${line.statement}');
        }

        // Update stock in warehouse_stocks (+ blend avg cost on increase)
        if (stockRow.isNotEmpty) {
          double newAvg = currentAvg;
          if (difference > 0 && newQty > 0) {
            newAvg = ((systemQty * currentAvg) + (difference * unitCost)) / newQty;
          }
          await txn.update(
            'warehouse_stocks',
            {
              'quantity': newQty,
              'avg_cost': newAvg,
              'last_modification_time': now,
            },
            where: 'product_id = ? AND warehouse_id = ?',
            whereArgs: [line.categoryId ?? 0, inventory.stockId],
          );
        } else {
          // Only increases can create new stock rows; validated above
          await txn.insert('warehouse_stocks', {
            'product_id': line.categoryId ?? 0,
            'warehouse_id': inventory.stockId,
            'quantity': difference,
            'avg_cost': unitCost,
            'last_cost': unitCost,
            'creation_time': now,
            'last_modification_time': now,
          });
        }

        // Insert stock movement with real balance_after
        await txn.insert('stock_movements', {
          'product_id': line.categoryId ?? 0,
          'warehouse_id': inventory.stockId,
          'movement_type': 'inventory_adjustment',
          'quantity': difference,
          'unit_cost': unitCost,
          'total_cost': differenceValue,
          'balance_after': newQty,
          'reference_type': 'inventory',
          'reference_id': id,
          'reference_number': 'INV-$id',
          'creation_time': now,
          'notes': line.statement,
        });

        // Legacy category_movs for backwards compatibility
        await txn.insert('category_movs', {
          'doc_no': settlementId,
          'trans_doc_type': 6,
          'trans_in_out': difference > 0 ? 1 : 0,
          'trans_date': now,
          'category_id': line.categoryId ?? 0,
          'unit_id': line.unitId,
          'group_id': line.groupId,
          'category_sub_unit_id': line.categorySubUnitId,
          'stock_id': inventory.stockId ?? 0,
          'quantity': difference.abs(),
          'quantity_in': difference > 0 ? difference.abs() : 0,
          'quantity_out': difference > 0 ? 0 : difference.abs(),
          'cost_amount': unitCost,
          'cost_local_amount': differenceValue,
          'currency_id': 1,
          'currency_code': null,
          'exchange_rate': null,
          'sell_amount': 0,
          'sell_local_amount': 0,
          'refrenc_no': 'ADJ-INV-$id',
          'statement': line.statement,
          'reference_number': null,
          'u_no': null,
          'barcode_no': null,
          'expire_date': null,
          'customer_id': null,
          'creation_time': now,
          'last_modification_time': now,
        });
      }

      // Create journal entries for the total differences
      // (Inventory differences must be recorded in accounting)

      // Get account IDs (get-or-create so existing DBs work)
      final inventoryAccountId = await _getOrCreateAccount(
        txn,
        code: '1003',
        cId: 1130,
        name: 'المخزون',
        type: 1,
      );
      final increaseAccountId = await _getOrCreateAccount(
        txn,
        code: '4200',
        cId: 4200,
        name: 'إيرادات تسوية المخزون',
        type: 4,
      );
      final decreaseAccountId = await _getOrCreateAccount(
        txn,
        code: '5200',
        cId: 5200,
        name: 'خسائر تسوية المخزون',
        type: 5,
      );

      // Journal entry for increases (gains)
      if (totalIncrease > 0.001) {
        await _createJournalEntry(
          txn: txn,
          now: now,
          inventoryId: id,
          inventoryNumber: inventory.number,
          debitAccountId: inventoryAccountId,
          creditAccountId: increaseAccountId,
          amount: totalIncrease,
          isIncrease: true,
        );
      }

      // Journal entry for decreases (losses)
      if (totalDecrease > 0.001) {
        await _createJournalEntry(
          txn: txn,
          now: now,
          inventoryId: id,
          inventoryNumber: inventory.number,
          debitAccountId: decreaseAccountId,
          creditAccountId: inventoryAccountId,
          amount: totalDecrease,
          isIncrease: false,
        );
      }
    });
  }

  /// Creates a journal entry for inventory adjustments
  Future<void> _createJournalEntry({
    required Transaction txn,
    required int now,
    required int inventoryId,
    required String inventoryNumber,
    required int debitAccountId,
    required int creditAccountId,
    required double amount,
    required bool isIncrease,
  }) async {
    final journalNumber = await _nextJournalNumber(txn, 'INV');

    final currencyId = await _resolveCurrencyId(txn);

    final journalEntryId = await txn.insert('journal_entries', {
      'number': journalNumber,
      'entry_date': now,
      'description': isIncrease 
          ? 'زيادة مخزون من جرد رقم $inventoryNumber'
          : 'نقص مخزون من جرد رقم $inventoryNumber',
      'reference_type': 'inventory',
      'reference_id': inventoryId,
      'reference_number': inventoryNumber,
      'status': 2,
      'is_posted': 1,
      'total_debit': amount,
      'total_credit': amount,
      'difference': 0.0,
      'creation_time': now,
      'last_modification_time': now,
    });

    // Debit Line
    final debitMeta = await _getAccountMeta(txn, debitAccountId);
    await txn.insert('journal_entry_lines', {
      'journal_entry_id': journalEntryId,
      'line_number': 1,
      'account_id': debitAccountId,
      'account_code': debitMeta['code'],
      'account_name': debitMeta['name'],
      'currency_id': currencyId,
      'debit_amount': amount,
      'credit_amount': 0.0,
      'description': isIncrease ? 'زيادة مخزون' : 'عجز مخزون',
    });
    
    // Update Debit Account Balance (+local_balance)
    await _applyAccountBalanceDelta(txn, debitAccountId, amount);

    // Credit Line
    final creditMeta = await _getAccountMeta(txn, creditAccountId);
    await txn.insert('journal_entry_lines', {
      'journal_entry_id': journalEntryId,
      'line_number': 2,
      'account_id': creditAccountId,
      'account_code': creditMeta['code'],
      'account_name': creditMeta['name'],
      'currency_id': currencyId,
      'debit_amount': 0.0,
      'credit_amount': amount,
      'description': isIncrease ? 'إيراد تسوية جرد' : 'تخفيض مخزون',
    });

    // Update Credit Account Balance
    await _applyAccountBalanceDelta(txn, creditAccountId, -amount);
  }

  // Helper methods for accounting
  /// Resolves an account by code, creating it if missing
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
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    final byName = await txn.query(
      'accounts',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (byName.isNotEmpty) {
      return byName.first['id'] as int;
    }

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

  Future<int?> _resolveCurrencyId(Transaction txn) async {
    final any = await txn.query(
      'currencies',
      columns: ['id'],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (any.isEmpty) return null;
    return any.first['id'] as int;
  }

  /// Applies delta to account balance respecting normal balance (debit vs credit).
  /// delta = +amount for debit, -amount for credit (debit-normal convention).
  /// For credit-normal accounts (liability/equity/revenue type 2,3,4) we invert.
  Future<void> _applyAccountBalanceDelta(
    Transaction txn,
    int accountId,
    double delta,
  ) async {
    final rows = await txn.query(
      'accounts',
      columns: ['balance', 'type'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = (rows.first['balance'] as num?)?.toDouble() ?? 0.0;
    final type = (rows.first['type'] as int?) ?? 1;
    final isCreditNormal = type == 2 || type == 3 || type == 4;
    final newBalance = isCreditNormal ? current - delta : current + delta;
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

  Future<Map<String, dynamic>> _getAccountMeta(Transaction txn, int accountId) async {
    final result = await txn.query(
      'accounts',
      columns: ['code', 'name'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return {'code': result.first['code'] ?? '', 'name': result.first['name'] ?? ''};
    }
    return {'code': '', 'name': ''};
  }

  Future<String> _nextJournalNumber(Transaction txn, String prefix) async {
    final result = await txn.rawQuery(
      "SELECT COALESCE(MAX(CAST(SUBSTR(number, ${prefix.length + 2}) AS INTEGER)), 0) + 1 as next "
      "FROM journal_entries WHERE number LIKE ?",
      ['$prefix-%'],
    );
    final next = (result.first['next'] as num?)?.toInt() ?? 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  @override
  Future<void> deleteInventory(int id) async {
    final inventory = await getInventory(id);

    await database.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Posted inventory: reverse ALL accounting/stock effects
      if (inventory.status == TransferStatus.completed) {
        // 1. Reverse journal entries
        final entries = await txn.query(
          'journal_entries',
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['inventory', id],
        );
        for (final entry in entries) {
          final entryId = entry['id'] as int;
          final lines = await txn.query(
            'journal_entry_lines',
            where: 'journal_entry_id = ?',
            whereArgs: [entryId],
          );
          for (final line in lines) {
            final accountId = line['account_id'] as int;
            final debit = (line['debit_amount'] as num?)?.toDouble() ?? 0.0;
            final credit = (line['credit_amount'] as num?)?.toDouble() ?? 0.0;
            await _applyAccountBalanceDelta(txn, accountId, -(debit - credit));
          }
          await txn.delete(
            'journal_entry_lines',
            where: 'journal_entry_id = ?',
            whereArgs: [entryId],
          );
          await txn.delete(
            'journal_entries',
            where: 'id = ?',
            whereArgs: [entryId],
          );
        }

        // 2. Reverse stock changes via the created settlements
        final settlements = await txn.query(
          'stock_settlements',
          where: 'parent_id = ? AND settlement_reason = ?',
          whereArgs: [id, 'inventory'],
        );
        for (final settlement in settlements) {
          final settlementId = settlement['id'] as int;
          final isIncrease = (settlement['type'] as int? ?? 0) == 0;
          final settlementStockId = settlement['stock_id'] as int?;

          final settlementLines = await txn.query(
            'stock_settlement_lines',
            where: 'stock_settlement_id = ?',
            whereArgs: [settlementId],
          );
          for (final line in settlementLines) {
            final productId = line['category_id'] as int?;
            final qty = (line['quantity'] as num?)?.toDouble() ?? 0.0;
            if (productId == null || qty <= 0) continue;
            final reverseDelta = isIncrease ? -qty : qty;
            await txn.rawUpdate('''
              UPDATE warehouse_stocks
              SET quantity = quantity + ?,
                  last_modification_time = ?
              WHERE product_id = ? AND warehouse_id = ?
            ''', [reverseDelta, now, productId, settlementStockId]);
          }

          // Delete legacy category movements
          await txn.delete(
            'category_movs',
            where: 'doc_no = ? AND trans_doc_type = ?',
            whereArgs: [settlementId, 6],
          );
          await txn.delete(
            'stock_settlement_lines',
            where: 'stock_settlement_id = ?',
            whereArgs: [settlementId],
          );
          await txn.delete(
            'stock_settlements',
            where: 'id = ?',
            whereArgs: [settlementId],
          );
        }

        // Delete inventory stock movements
        await txn.delete(
          'stock_movements',
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['inventory', id],
        );
      }

      // Delete inventory lines first
      await txn.delete(
        'inventory_lines',
        where: 'inventory_id = ?',
        whereArgs: [id],
      );
      
      // Delete inventory
      await txn.delete(
        'inventories',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<InventoryLineModel>> _getInventoryLines(int inventoryId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'inventory_lines',
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
    );

    return maps.map((map) => InventoryLineModel.fromMap(map)).toList();
  }

  @override
  @override
  Future<double> getProductQuantityInWarehouse(
      int productId, int warehouseId) async {
    final result = await database.query(
      'warehouse_stocks',
      columns: ['quantity'],
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [productId, warehouseId],
      limit: 1,
    );
    if (result.isEmpty) return 0.0;
    return (result.first['quantity'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<Map<int, double>> getWarehouseStockMap(int warehouseId) async {
    final result = await database.query(
      'warehouse_stocks',
      columns: ['product_id', 'quantity'],
      where: 'warehouse_id = ?',
      whereArgs: [warehouseId],
    );
    return {
      for (var row in result)
        (row['product_id'] as int): (row['quantity'] as num).toDouble()
    };
  }

  Future<List<InventoryLineEntity>> getCurrentStockLines(int warehouseId) async {
    // Join warehouse_stocks with categories to get product metadata
    final rows = await database.rawQuery('''
      SELECT ws.product_id, ws.quantity, ws.avg_cost,
             c.name as product_name, c.group_id, c.unit_id, c.category_sub_unit_id
      FROM warehouse_stocks ws
      LEFT JOIN categories c ON c.id = ws.product_id
      WHERE ws.warehouse_id = ?
    ''', [warehouseId]);
    return rows.map((row) {
      return InventoryLineEntity(
        categoryId: row['product_id'] as int?,
        groupId: (row['group_id'] as int?) ?? 1,
        unitId: (row['unit_id'] as int?) ?? 1,
        categorySubUnitId: (row['category_sub_unit_id'] as int?) ?? 1,
        statement: (row['product_name'] as String?) ?? 'منتج ${row['product_id']}',
        quantity: (row['quantity'] as num).toDouble(),
        actualQuantity: (row['quantity'] as num).toDouble(),
        difference: 0,
        costAmount: (row['avg_cost'] as num?)?.toDouble(),
      );
    }).toList();
  }
}
