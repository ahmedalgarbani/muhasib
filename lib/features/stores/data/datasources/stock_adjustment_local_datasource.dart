import 'package:muhasib/core/services/database_service.dart';
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
  final DatabaseService databaseService;

  StockAdjustmentLocalDataSourceImpl({required this.databaseService});

  @override
  Future<List<StockAdjustmentModel>> getAdjustments() async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
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
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
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
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
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
    final db = await databaseService.database;
    return await db.transaction((txn) async {
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
    final db = await databaseService.database;
    
    await db.transaction((txn) async {
      // 1. Update adjustment status to posted
      await txn.update(
        'stock_settlements',
        {
          'status': 4, // TransferStatus.completed
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      double totalValue = 0.0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 2. Process stock movements
      if (adjustment.lines.isNotEmpty) {
        for (var line in adjustment.lines) {
          final isIncrease = adjustment.type == AdjustmentType.increase;
          final quantity = isIncrease ? line.quantity : -line.quantity;
          final unitCost = line.amount / (line.quantity > 0 ? line.quantity : 1);
          final lineTotal = line.amount;
          
          totalValue += lineTotal;

          // Update inventory stock (warehouse_stocks)
          // We need to fetch current stock to update avg_cost if needed, 
          // but for simple adjustment we might just update quantity.
          // For strict accounting, we should recalculate avg cost on increase.
          
          // Simple stock update for now
          await txn.rawUpdate('''
            INSERT INTO warehouse_stocks (product_id, warehouse_id, quantity, avg_cost, creation_time, last_modification_time)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(product_id, warehouse_id) DO UPDATE SET
            quantity = quantity + ?,
            last_modification_time = ?
          ''', [
            line.categoryId, adjustment.stockId, quantity, unitCost, now, now,
            quantity, now
          ]);

          // Insert into CORRECT stock_movements table
          await txn.insert('stock_movements', {
            'product_id': line.categoryId,
            'warehouse_id': adjustment.stockId,
            'movement_type': 'adjustment',
            'quantity': quantity,
            'unit_cost': unitCost,
            'total_cost': lineTotal,
            'balance_after': 0, // Ideally we fetch this, but 0 is placeholder if we don't want extra query
            'reference_type': 'stock_adjustment',
            'reference_id': id,
            'reference_number': adjustment.number,
            'creation_time': now,
            'notes': line.statement,
          });
        }
      }

      // 3. Create Journal Entry
      // Increase (Gain): Dr Inventory (1180) / Cr Adjustment Income (4200)
      // Decrease (Loss): Dr Adjustment Expense (5200) / Cr Inventory (1180)
      
      if (totalValue > 0) {
        final isIncrease = adjustment.type == AdjustmentType.increase;
        final inventoryAccountId = await _resolveAccountId(txn, 'المخزون', 1180);
        final adjustmentAccountId = isIncrease
            ? await _resolveAccountId(txn, 'إيرادات تسوية مخزون', 4200)
            : await _resolveAccountId(txn, 'خسائر تسوية مخزون', 5200);

        final journalNumber = await _nextJournalNumber(txn, 'ADJ');
        
        final journalEntryId = await txn.insert('journal_entries', {
          'number': journalNumber,
          'entry_date': now,
          'description': 'تسوية مخزنية رقم ${adjustment.number}',
          'reference_type': 'stock_adjustment',
          'reference_id': id,
          'reference_number': adjustment.number,
          'status': 1,
          'is_posted': 1,
          'total_debit': totalValue,
          'total_credit': totalValue,
          'difference': 0.0,
          'creation_time': now,
          'last_modification_time': now,
        });

        // Debit Line
        final debitAccount = isIncrease ? inventoryAccountId : adjustmentAccountId;
        final debitMeta = await _getAccountMeta(txn, debitAccount);
        await txn.insert('journal_entry_lines', {
          'journal_entry_id': journalEntryId,
          'line_number': 1,
          'account_id': debitAccount,
          'account_code': debitMeta['code'],
          'account_name': debitMeta['name'],
          'debit_amount': totalValue,
          'credit_amount': 0.0,
          'description': isIncrease ? 'زيادة مخزون' : 'عجز مخزون',
        });
        
        // Update Debit Account Balance
        await txn.rawUpdate(
          'UPDATE accounts SET balance = COALESCE(balance, 0) + ? WHERE id = ?',
          [totalValue, debitAccount],
        );

        // Credit Line
        final creditAccount = isIncrease ? adjustmentAccountId : inventoryAccountId;
        final creditMeta = await _getAccountMeta(txn, creditAccount);
        await txn.insert('journal_entry_lines', {
          'journal_entry_id': journalEntryId,
          'line_number': 2,
          'account_id': creditAccount,
          'account_code': creditMeta['code'],
          'account_name': creditMeta['name'],
          'debit_amount': 0.0,
          'credit_amount': totalValue,
          'description': isIncrease ? 'إيراد تسوية' : 'تخفيض مخزون',
        });

        // Update Credit Account Balance
        await txn.rawUpdate(
          'UPDATE accounts SET balance = COALESCE(balance, 0) - ? WHERE id = ?',
          [totalValue, creditAccount],
        );
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

    final db = await databaseService.database;
    await db.transaction((txn) async {
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
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_settlement_lines',
      where: 'stock_settlement_id = ?',
      whereArgs: [adjustmentId],
    );

    return maps.map((map) => StockAdjustmentLineModel.fromMap(map)).toList();
  }
  // Helpers for Accounting
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
}
