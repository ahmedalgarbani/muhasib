import 'package:muhasib/features/stores/data/models/stock_adjustment_model.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:sqflite/sqflite.dart';

abstract class StockAdjustmentLocalDataSource {
  Future<List<StockAdjustmentModel>> getAdjustments();
  Future<List<StockAdjustmentModel>> getAdjustmentsByWarehouse(int warehouseId);
  Future<StockAdjustmentModel> getAdjustment(int id);
  Future<int> createAdjustment(StockAdjustmentModel adjustment);
  Future<void> postAdjustment(int id);
  Future<void> deleteAdjustment(int id);
}

class StockAdjustmentLocalDataSourceImpl implements StockAdjustmentLocalDataSource {
  final Database database;

  StockAdjustmentLocalDataSourceImpl({required this.database});

  @override
  Future<List<StockAdjustmentModel>> getAdjustments() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_settlements',
      orderBy: 'date DESC',
    );

    List<StockAdjustmentModel> adjustments = [];
    for (var map in maps) {
      final lines = await _getAdjustmentLines(map['id']);
      adjustments.add(StockAdjustmentModel.fromMap(map, lines: lines.cast<StockAdjustmentLineEntity>()));
    }
    return adjustments;
  }

  @override
  Future<List<StockAdjustmentModel>> getAdjustmentsByWarehouse(int warehouseId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_settlements',
      where: 'stock_id = ?',
      whereArgs: [warehouseId],
      orderBy: 'date DESC',
    );

    List<StockAdjustmentModel> adjustments = [];
    for (var map in maps) {
      final lines = await _getAdjustmentLines(map['id']);
      adjustments.add(StockAdjustmentModel.fromMap(map, lines: lines.cast<StockAdjustmentLineEntity>()));
    }
    return adjustments;
  }

  @override
  Future<StockAdjustmentModel> getAdjustment(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_settlements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      throw Exception('Adjustment not found');
    }

    final lines = await _getAdjustmentLines(id);
    return StockAdjustmentModel.fromMap(maps.first, lines: lines.cast<StockAdjustmentLineEntity>());
  }

  @override
  Future<int> createAdjustment(StockAdjustmentModel adjustment) async {
    return await database.transaction((txn) async {
      final id = await txn.insert('stock_settlements', adjustment.toMap());
      
      // Insert adjustment lines
      if (adjustment.lines.isNotEmpty) {
        for (var line in adjustment.lines) {
          final lineModel = line is StockAdjustmentLineModel ? line : StockAdjustmentLineModel.fromEntity(line);
          await txn.insert('stock_settlement_lines', lineModel.toMap());
        }
      }
      
      return id;
    });
  }

  @override
  Future<void> postAdjustment(int id) async {
    final adjustment = await getAdjustment(id);
    
    await database.transaction((txn) async {
      // Update adjustment status to posted
      await txn.update(
        'stock_settlements',
        {
          'status': 4, // TransferStatus.completed
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Process stock movements
      if (adjustment.lines.isNotEmpty) {
        for (var line in adjustment.lines) {
          // Update stock movement
          final isIncrease = adjustment.type == AdjustmentType.increase;
          await txn.insert('category_movs', {
            'doc_no': id,
            'trans_doc_type': 6, // Adjustment type
            'trans_in_out': isIncrease ? 1 : 0,
            'trans_date': adjustment.date,
            'category_id': line.categoryId,
            'unit_id': line.unitId,
            'group_id': line.groupId,
            'category_sub_unit_id': line.categorySubUnitId,
            'stock_id': adjustment.stockId,
            'quantity': line.quantity,
            'quantity_in': isIncrease ? line.quantity : 0,
            'quantity_out': isIncrease ? 0 : line.quantity,
            'cost_amount': line.amount / line.quantity,
            'cost_local_amount': line.amount,
            'currency_id': adjustment.currencyId,
            'currency_code': adjustment.currencyCode,
            'exchange_rate': adjustment.exchangeRate ?? 1.0,
            'sell_amount': 0,
            'sell_local_amount': 0,
            'refrenc_no': adjustment.number,
            'statement': line.statement,
            'reference_number': adjustment.parentNumber,
            'u_no': adjustment.uNo,
            'barcode_no': '',
            'expire_date': line.expireDate,
            'customer_id': null,
            'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
        }
      }
    });
  }

  @override
  Future<void> deleteAdjustment(int id) async {
    final adjustment = await getAdjustment(id);
    
    // Only allow deletion if not posted
    if (adjustment.status == TransferStatus.completed) {
      throw Exception('Cannot delete posted adjustment');
    }

    await database.transaction((txn) async {
      // Delete adjustment lines first
      await txn.delete(
        'stock_settlement_lines',
        where: 'stock_settlement_id = ?',
        whereArgs: [id],
      );
      
      // Delete adjustment
      await txn.delete(
        'stock_settlements',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<StockAdjustmentLineModel>> _getAdjustmentLines(int adjustmentId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'stock_settlement_lines',
      where: 'stock_settlement_id = ?',
      whereArgs: [adjustmentId],
    );

    return maps.map((map) => StockAdjustmentLineModel.fromMap(map)).toList();
  }

  // NOTE:
  // We intentionally do not auto-create accounting journal entries here.
  // In this codebase, inventory accounting requires a clear mapping for:
  // - Inventory control account (per warehouse or global)
  // - Adjustment gain/loss accounts
  // Those mappings are not defined for adjustments yet, so creating entries would be incorrect.
}
