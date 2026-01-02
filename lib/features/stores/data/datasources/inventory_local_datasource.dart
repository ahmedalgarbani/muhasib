import 'package:muhasib/features/stores/data/models/inventory_model.dart';
import 'package:muhasib/features/stores/data/models/inventory_line_model.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_entity.dart';
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
    final inventory = await getInventory(id);
    
    await database.transaction((txn) async {
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
        final difference = line.actualQuantity - line.quantity;
        if (difference != 0) {
          final adjType = difference > 0 ? 0 : 1; // increase/decrease
          final differenceValue = (line.costAmount ?? 0) * difference.abs();
          
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
            'parent_number': null,
            'parent_id': null,
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
            'amount': (line.costAmount ?? 0),
            'total_amount': differenceValue,
            'currency_code': null,
            'exchange_rate': null,
            'currency_id': 1,
            'stock_id': inventory.stockId ?? 0,
            'stock_settlement_id': settlementId,
            'expire_date': null,
            'reason': 'الفرق في الجرد',
          });

          // Update stock in warehouse_stocks
          await txn.rawUpdate('''
            INSERT INTO warehouse_stocks (product_id, warehouse_id, quantity, avg_cost, creation_time, last_modification_time)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(product_id, warehouse_id) DO UPDATE SET
            quantity = quantity + ?,
            last_modification_time = ?
          ''', [
            line.categoryId ?? 0, inventory.stockId, difference, (line.costAmount ?? 0), now, now,
            difference, now
          ]);

          // Insert stock movement
          await txn.insert('stock_movements', {
            'product_id': line.categoryId ?? 0,
            'warehouse_id': inventory.stockId,
            'movement_type': 'inventory_adjustment',
            'quantity': difference,
            'unit_cost': (line.costAmount ?? 0),
            'total_cost': differenceValue,
            'balance_after': 0,
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
            'cost_amount': (line.costAmount ?? 0),
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
      }

      // Create journal entries for the total differences
      // CRITICAL: This was missing before - inventory differences must be recorded in accounting!
      
      // Get account IDs
      final inventoryAccountId = await _resolveAccountId(txn, 'المخزون', 1180);
      final increaseAccountId = await _resolveAccountId(txn, 'إيرادات تسوية مخزون', 4200);
      final decreaseAccountId = await _resolveAccountId(txn, 'خسائر تسوية مخزون', 5200);

      // Journal entry for increases (gains)
      if (totalIncrease > 0) {
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
      if (totalDecrease > 0) {
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
    
    final journalEntryId = await txn.insert('journal_entries', {
      'number': journalNumber,
      'entry_date': now,
      'description': isIncrease 
          ? 'زيادة مخزون من جرد رقم $inventoryNumber'
          : 'نقص مخزون من جرد رقم $inventoryNumber',
      'reference_type': 'inventory',
      'reference_id': inventoryId,
      'reference_number': inventoryNumber,
      'status': 1,
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
      'debit_amount': amount,
      'credit_amount': 0.0,
      'description': isIncrease ? 'زيادة مخزون' : 'عجز مخزون',
    });
    
    // Update Debit Account Balance
    await txn.rawUpdate(
      'UPDATE accounts SET balance = COALESCE(balance, 0) + ? WHERE id = ?',
      [amount, debitAccountId],
    );

    // Credit Line
    final creditMeta = await _getAccountMeta(txn, creditAccountId);
    await txn.insert('journal_entry_lines', {
      'journal_entry_id': journalEntryId,
      'line_number': 2,
      'account_id': creditAccountId,
      'account_code': creditMeta['code'],
      'account_name': creditMeta['name'],
      'debit_amount': 0.0,
      'credit_amount': amount,
      'description': isIncrease ? 'إيراد تسوية جرد' : 'تخفيض مخزون',
    });

    // Update Credit Account Balance
    await txn.rawUpdate(
      'UPDATE accounts SET balance = COALESCE(balance, 0) - ? WHERE id = ?',
      [amount, creditAccountId],
    );
  }

  // Helper methods for accounting
  Future<int> _resolveAccountId(Transaction txn, String label, int defaultId) async {
    final result = await txn.query(
      'accounts',
      columns: ['id'],
      where: 'name LIKE ? OR id = ?',
      whereArgs: ['%$label%', defaultId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return defaultId;
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
      "FROM journal_entries WHERE number LIKE '$prefix-%'",
    );
    final next = (result.first['next'] as int?) ?? 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  @override
  Future<void> deleteInventory(int id) async {
    await database.transaction((txn) async {
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
}
