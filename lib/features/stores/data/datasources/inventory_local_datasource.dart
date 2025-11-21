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

      // Create stock settlements for differences
      for (var line in inventory.lines) {
        final difference = line.actualQuantity - line.quantity;
        if (difference != 0) {
          final adjType = difference > 0 ? 0 : 1; // increase/decrease

          final settlementId = await txn.insert('stock_settlements', {
            'number': 'ADJ-INV-$id-${line.categoryId ?? 0}',
            'date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'type': adjType,
            'total_amount': (line.costAmount ?? 0) * difference.abs(),
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
            'total_amount': (line.costAmount ?? 0) * difference.abs(),
            'currency_code': null,
            'exchange_rate': null,
            'currency_id': 1,
            'stock_id': inventory.stockId ?? 0,
            'stock_settlement_id': settlementId,
            'expire_date': null,
            'reason': 'الفرق في الجرد',
          });

          // Update stock movement
          await txn.insert('category_movs', {
            'doc_no': settlementId,
            'trans_doc_type': 6,
            'trans_in_out': difference > 0 ? 1 : 0,
            'trans_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'category_id': line.categoryId ?? 0,
            'unit_id': line.unitId,
            'group_id': line.groupId,
            'category_sub_unit_id': line.categorySubUnitId,
            'stock_id': inventory.stockId ?? 0,
            'quantity': difference.abs(),
            'quantity_in': difference > 0 ? difference.abs() : 0,
            'quantity_out': difference > 0 ? 0 : difference.abs(),
            'cost_amount': (line.costAmount ?? 0),
            'cost_local_amount': (line.costAmount ?? 0) * difference.abs(),
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
            'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
        }
      }
    });
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
