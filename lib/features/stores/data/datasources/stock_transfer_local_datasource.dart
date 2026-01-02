import 'package:muhasib/features/stores/data/models/stock_transfer_model.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:sqflite/sqflite.dart';

abstract class StockTransferLocalDataSource {
  Future<List<StockTransferModel>> getTransfers();
  Future<List<StockTransferModel>> getTransfersByWarehouse(int warehouseId);
  Future<StockTransferModel> getTransfer(int id);
  Future<int> createTransfer(StockTransferModel transfer);
  Future<void> updateTransferStatus(int id, String status);
  Future<void> deleteTransfer(int id);
}

class StockTransferLocalDataSourceImpl implements StockTransferLocalDataSource {
  final Database database;

  StockTransferLocalDataSourceImpl({required this.database});

  @override
  Future<List<StockTransferModel>> getTransfers() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_transfers',
      orderBy: 'date DESC',
    );

    List<StockTransferModel> transfers = [];
    for (var map in maps) {
      final lines = await _getTransferLines(map['id']);
      transfers.add(StockTransferModel.fromMap(map, lines: lines.cast<StockTransferLineEntity>()));
    }
    return transfers;
  }

  @override
  Future<List<StockTransferModel>> getTransfersByWarehouse(int warehouseId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_transfers',
      where: 'from_stock_id = ? OR to_stock_id = ?',
      whereArgs: [warehouseId, warehouseId],
      orderBy: 'date DESC',
    );

    List<StockTransferModel> transfers = [];
    for (var map in maps) {
      final lines = await _getTransferLines(map['id']);
      transfers.add(StockTransferModel.fromMap(map, lines: lines.cast<StockTransferLineEntity>()));
    }
    return transfers;
  }

  @override
  Future<StockTransferModel> getTransfer(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_transfers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      throw Exception('Transfer not found');
    }

    final lines = await _getTransferLines(id);
    return StockTransferModel.fromMap(maps.first, lines: lines.cast<StockTransferLineEntity>());
  }

  @override
  Future<int> createTransfer(StockTransferModel transfer) async {
    return await database.transaction((txn) async {
      final id = await txn.insert('stock_transfers', transfer.toMap());
      
      // Insert transfer lines
      if (transfer.lines.isNotEmpty) {
        for (var line in transfer.lines) {
          final lineModel = line is StockTransferLineModel ? line : StockTransferLineModel.fromEntity(line);
          await txn.insert('stock_transfer_lines', lineModel.toMap());
        }
      }
      
      return id;
    });
  }

  @override
  Future<void> updateTransferStatus(int id, String status) async {
    final parsedStatus = TransferStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => TransferStatus.draft,
    );

    await database.update(
      'stock_transfers',
      {
        'status': parsedStatus.value,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // If status is 'completed', update stock quantities
    if (parsedStatus == TransferStatus.completed) {
      await _processTransferCompletion(id);
    }
  }

  @override
  Future<void> deleteTransfer(int id) async {
    // Check if transfer is completed
    final transfer = await getTransfer(id);
    if (transfer.status == TransferStatus.completed) {
      throw Exception('لا يمكن حذف تحويل مكتمل - يرجى إنشاء تحويل معاكس');
    }
    
    await database.transaction((txn) async {
      // Delete transfer lines first
      await txn.delete(
        'stock_transfer_lines',
        where: 'stock_transfer_id = ?',
        whereArgs: [id],
      );
      
      // Delete transfer
      await txn.delete(
        'stock_transfers',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<StockTransferLineModel>> _getTransferLines(int transferId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_transfer_lines',
      where: 'stock_transfer_id = ?',
      whereArgs: [transferId],
    );

    return maps.map((map) => StockTransferLineModel.fromMap(map)).toList();
  }

  Future<void> _processTransferCompletion(int transferId) async {
    final transfer = await getTransfer(transferId);
    
    if (transfer.lines.isEmpty) return;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    await database.transaction((txn) async {
      for (var line in transfer.lines) {
        final productId = line.categoryId;
        final quantity = line.quantity;
        final costAmount = line.costAmount ?? 0;
        
        // 1. Validate quantity availability in source warehouse
        final sourceStock = await txn.query(
          'warehouse_stocks',
          columns: ['quantity'],
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [productId, transfer.fromStockId],
          limit: 1,
        );
        
        final availableQty = sourceStock.isNotEmpty 
            ? (sourceStock.first['quantity'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        
        if (availableQty < quantity) {
          throw Exception(
            'الكمية المتوفرة في المخزن المصدر ($availableQty) أقل من الكمية المطلوبة ($quantity)'
          );
        }
        
        // 2. Decrease from source warehouse (warehouse_stocks)
        await txn.rawUpdate('''
          UPDATE warehouse_stocks 
          SET quantity = quantity - ?, 
              last_modification_time = ?
          WHERE product_id = ? AND warehouse_id = ?
        ''', [quantity, now, productId, transfer.fromStockId]);
        
        // 3. Increase in destination warehouse (warehouse_stocks)
        await txn.rawInsert('''
          INSERT INTO warehouse_stocks (product_id, warehouse_id, quantity, avg_cost, creation_time, last_modification_time)
          VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(product_id, warehouse_id) DO UPDATE SET
          quantity = quantity + ?,
          last_modification_time = ?
        ''', [
          productId, transfer.toStockId, quantity, costAmount, now, now,
          quantity, now
        ]);
        
        // 4. Record stock movement for source (outgoing)
        await txn.insert('stock_movements', {
          'product_id': productId,
          'warehouse_id': transfer.fromStockId,
          'movement_type': 'transfer_out',
          'quantity': -quantity, // Negative for outgoing
          'unit_cost': costAmount,
          'total_cost': costAmount * quantity,
          'balance_after': availableQty - quantity,
          'reference_type': 'stock_transfer',
          'reference_id': transferId,
          'reference_number': transfer.number,
          'creation_time': now,
          'notes': 'تحويل إلى مخزن ${transfer.toStockId}',
        });
        
        // 5. Record stock movement for destination (incoming)
        final destStock = await txn.query(
          'warehouse_stocks',
          columns: ['quantity'],
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [productId, transfer.toStockId],
          limit: 1,
        );
        final destQty = destStock.isNotEmpty 
            ? (destStock.first['quantity'] as num?)?.toDouble() ?? 0.0
            : quantity;
        
        await txn.insert('stock_movements', {
          'product_id': productId,
          'warehouse_id': transfer.toStockId,
          'movement_type': 'transfer_in',
          'quantity': quantity, // Positive for incoming
          'unit_cost': costAmount,
          'total_cost': costAmount * quantity,
          'balance_after': destQty,
          'reference_type': 'stock_transfer',
          'reference_id': transferId,
          'reference_number': transfer.number,
          'creation_time': now,
          'notes': 'تحويل من مخزن ${transfer.fromStockId}',
        });
        
        // 6. Legacy category_movs for backwards compatibility
        // Decrease from source warehouse
        await txn.insert('category_movs', {
          'doc_no': transferId,
          'trans_doc_type': 5, // Transfer type
          'trans_in_out': 0, // Out
          'trans_date': transfer.date,
          'category_id': line.categoryId,
          'unit_id': line.unitId,
          'group_id': line.groupId,
          'category_sub_unit_id': line.categorySubUnitId,
          'stock_id': transfer.fromStockId,
          'quantity': line.quantity,
          'quantity_in': 0,
          'quantity_out': line.quantity,
          'cost_amount': line.costAmount ?? 0,
          'cost_local_amount': (line.costAmount ?? 0) * line.quantity,
          'currency_id': 1,
          'refrenc_no': transfer.number,
          'statement': line.statement,
          'creation_time': now,
          'last_modification_time': now,
        });

        // Increase in destination warehouse
        await txn.insert('category_movs', {
          'doc_no': transferId,
          'trans_doc_type': 5, // Transfer type
          'trans_in_out': 1, // In
          'trans_date': transfer.date,
          'category_id': line.categoryId,
          'unit_id': line.unitId,
          'group_id': line.groupId,
          'category_sub_unit_id': line.categorySubUnitId,
          'stock_id': transfer.toStockId,
          'quantity': line.quantity,
          'quantity_in': line.quantity,
          'quantity_out': 0,
          'cost_amount': line.costAmount ?? 0,
          'cost_local_amount': (line.costAmount ?? 0) * line.quantity,
          'currency_id': 1,
          'refrenc_no': transfer.number,
          'statement': line.statement,
          'creation_time': now,
          'last_modification_time': now,
        });
      }
    });
  }
}
