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
    
    if (transfer.lines.isNotEmpty) {
      await database.transaction((txn) async {
        for (var line in transfer.lines) {
          // Update category_movs table for stock tracking
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
            'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
            'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
        }
      });
    }
  }
}
