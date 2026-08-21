import 'package:muhasib/features/stores/data/models/stock_transfer_model.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:sqflite/sqflite.dart';

abstract class StockTransferLocalDataSource {
  Future<List<StockTransferModel>> getTransfers();
  Future<List<StockTransferModel>> getTransfersByWarehouse(int warehouseId);
  Future<StockTransferModel> getTransfer(int id);
  Future<int> createTransfer(StockTransferModel transfer);
  Future<void> updateTransfer(StockTransferModel transfer);
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
      
      // Insert transfer lines linked to the transfer id
      if (transfer.lines.isNotEmpty) {
        for (var line in transfer.lines) {
          final lineModel = line is StockTransferLineModel ? line : StockTransferLineModel.fromEntity(line);
          await txn.insert(
            'stock_transfer_lines',
            {...lineModel.toMap(), 'stock_transfer_id': id},
          );
        }
      }
      
      return id;
    });
  }

  @override
  Future<void> updateTransfer(StockTransferModel transfer) async {
    if (transfer.id == null) {
      throw Exception('Transfer id is required for update');
    }
    final existing = await getTransfer(transfer.id!);
    if (existing.status == TransferStatus.completed) {
      throw Exception('لا يمكن تعديل تحويل مرحّل');
    }
    await database.transaction((txn) async {
      await txn.update(
        'stock_transfers',
        transfer.toMap(),
        where: 'id = ?',
        whereArgs: [transfer.id],
      );
      await txn.delete(
        'stock_transfer_lines',
        where: 'stock_transfer_id = ?',
        whereArgs: [transfer.id],
      );
      for (var line in transfer.lines) {
        final lineModel = line is StockTransferLineModel
            ? line
            : StockTransferLineModel.fromEntity(line);
        await txn.insert(
          'stock_transfer_lines',
          {...lineModel.toMap(), 'stock_transfer_id': transfer.id},
        );
      }
    });
  }

  @override
  Future<void> updateTransferStatus(int id, String status) async {
    final parsedStatus = TransferStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => TransferStatus.draft,
    );

    await database.transaction((txn) async {
      // Double-completion guard inside transaction (atomic)
      final currentMaps = await txn.query(
        'stock_transfers',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (currentMaps.isEmpty) throw Exception('Transfer not found');
      final currentStatus = TransferStatus.fromValue(
          currentMaps.first['status'] as int? ?? 0);
      if (currentStatus == TransferStatus.completed &&
          parsedStatus == TransferStatus.completed) {
        throw Exception('تم اكتمال هذا التحويل مسبقاً');
      }

      await txn.update(
        'stock_transfers',
        {
          'status': parsedStatus.value,
          'last_modification_time':
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (parsedStatus == TransferStatus.completed) {
        await _processTransferCompletionTxn(txn, id);
      }
    });
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

  // ignore: unused_element
  /// Legacy non-transactional wrapper (kept for compatibility, delegates to txn version)
  Future<void> _processTransferCompletion(int transferId) async {
    await database.transaction((txn) async {
      await _processTransferCompletionTxn(txn, transferId);
    });
  }

  Future<void> _processTransferCompletionTxn(
      Transaction txn, int transferId) async {
    // Read transfer header + lines inside the same txn (snapshot consistency)
    final headerMaps = await txn.query(
      'stock_transfers',
      where: 'id = ?',
      whereArgs: [transferId],
      limit: 1,
    );
    if (headerMaps.isEmpty) throw Exception('Transfer not found');
    final lineMaps = await txn.query(
      'stock_transfer_lines',
      where: 'stock_transfer_id = ?',
      whereArgs: [transferId],
    );
    final lines = lineMaps.map((m) => StockTransferLineModel.fromMap(m)).toList();
    final transfer = StockTransferModel.fromMap(headerMaps.first,
        lines: lines.cast<StockTransferLineEntity>());

    if (transfer.lines.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (var line in transfer.lines) {
      final productId = line.categoryId;
      final quantity = line.quantity;
      if (productId == null) continue;

      // 1. Validate availability + fetch source avg cost (authoritative)
      final sourceStock = await txn.query(
        'warehouse_stocks',
        columns: ['quantity', 'avg_cost'],
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [productId, transfer.fromStockId],
        limit: 1,
      );
      final availableQty = sourceStock.isNotEmpty
          ? (sourceStock.first['quantity'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final sourceAvg = sourceStock.isNotEmpty
          ? (sourceStock.first['avg_cost'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      // Transfer must be valued at source weighted-average cost (accounting correctness)
      final transferUnitCost =
          sourceAvg > 0 ? sourceAvg : (line.costAmount ?? 0);

      if (availableQty < quantity) {
        throw Exception(
          'الكمية المتوفرة في المخزن المصدر ($availableQty) أقل من الكمية المطلوبة ($quantity)',
        );
      }

      // 2. Decrease from source warehouse (warehouse_stocks)
      final updated = await txn.rawUpdate(
        '''
          UPDATE warehouse_stocks 
          SET quantity = quantity - ?, 
              last_modification_time = ?
          WHERE product_id = ? AND warehouse_id = ?
        ''',
        [quantity, now, productId, transfer.fromStockId],
      );
      if (updated == 0) {
        throw Exception('فشل تحديث رصيد المخزن المصدر للمنتج $productId');
      }

      // 3. Increase in destination warehouse (blend avg cost at source cost)
      final destStock = await txn.query(
        'warehouse_stocks',
        columns: ['quantity', 'avg_cost'],
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [productId, transfer.toStockId],
        limit: 1,
      );
      final destQtyBefore = destStock.isNotEmpty
          ? (destStock.first['quantity'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final destAvgBefore = destStock.isNotEmpty
          ? (destStock.first['avg_cost'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final newDestQty = destQtyBefore + quantity;

      double newAvgCost = transferUnitCost;
      if (destStock.isNotEmpty && newDestQty > 0) {
        newAvgCost =
            ((destQtyBefore * destAvgBefore) + (quantity * transferUnitCost)) /
                newDestQty;
      }

      if (destStock.isNotEmpty) {
        await txn.update(
          'warehouse_stocks',
          {
            'quantity': newDestQty,
            'avg_cost': newAvgCost,
            'last_modification_time': now,
          },
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [productId, transfer.toStockId],
        );
      } else {
        await txn.insert('warehouse_stocks', {
          'product_id': productId,
          'warehouse_id': transfer.toStockId,
          'quantity': quantity,
          'avg_cost': transferUnitCost,
          'last_cost': transferUnitCost,
          'creation_time': now,
          'last_modification_time': now,
        });
      }

      // 4. Record stock movement for source (outgoing)
      await txn.insert('stock_movements', {
        'product_id': productId,
        'warehouse_id': transfer.fromStockId,
        'movement_type': 'transfer_out',
        'quantity': -quantity,
        'unit_cost': transferUnitCost,
        'total_cost': transferUnitCost * quantity,
        'balance_after': availableQty - quantity,
        'reference_type': 'stock_transfer',
        'reference_id': transferId,
        'reference_number': transfer.number,
        'creation_time': now,
        'notes': 'تحويل إلى مخزن ${transfer.toStockId}',
      });

      // 5. Record stock movement for destination (incoming)
      await txn.insert('stock_movements', {
        'product_id': productId,
        'warehouse_id': transfer.toStockId,
        'movement_type': 'transfer_in',
        'quantity': quantity,
        'unit_cost': transferUnitCost,
        'total_cost': transferUnitCost * quantity,
        'balance_after': newDestQty,
        'reference_type': 'stock_transfer',
        'reference_id': transferId,
        'reference_number': transfer.number,
        'creation_time': now,
        'notes': 'تحويل من مخزن ${transfer.fromStockId}',
      });

      // 6. Legacy category_movs for backwards compatibility
      await txn.insert('category_movs', {
        'doc_no': transferId,
        'trans_doc_type': 5,
        'trans_in_out': 0,
        'trans_date': transfer.date,
        'category_id': line.categoryId,
        'unit_id': line.unitId,
        'group_id': line.groupId,
        'category_sub_unit_id': line.categorySubUnitId,
        'stock_id': transfer.fromStockId,
        'quantity': line.quantity,
        'quantity_in': 0,
        'quantity_out': line.quantity,
        'cost_amount': transferUnitCost,
        'cost_local_amount': transferUnitCost * line.quantity,
        'currency_id': 1,
        'refrenc_no': transfer.number,
        'statement': line.statement,
        'creation_time': now,
        'last_modification_time': now,
      });

      await txn.insert('category_movs', {
        'doc_no': transferId,
        'trans_doc_type': 5,
        'trans_in_out': 1,
        'trans_date': transfer.date,
        'category_id': line.categoryId,
        'unit_id': line.unitId,
        'group_id': line.groupId,
        'category_sub_unit_id': line.categorySubUnitId,
        'stock_id': transfer.toStockId,
        'quantity': line.quantity,
        'quantity_in': line.quantity,
        'quantity_out': 0,
        'cost_amount': transferUnitCost,
        'cost_local_amount': transferUnitCost * line.quantity,
        'currency_id': 1,
        'refrenc_no': transfer.number,
        'statement': line.statement,
        'creation_time': now,
        'last_modification_time': now,
      });
    }
  }
}
