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
  Future<void> updateAdjustment(StockAdjustmentModel adjustment);
  Future<void> updateAdjustmentStatus(int id, TransferStatus status);
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
      
      // Insert adjustment lines linked to the settlement id
      if (adjustment.lines.isNotEmpty) {
        for (var line in adjustment.lines) {
          final lineModel = line is StockAdjustmentLineModel ? line : StockAdjustmentLineModel.fromEntity(line);
          await txn.insert(
            'stock_settlement_lines',
            {...lineModel.toMap(), 'stock_settlement_id': id},
          );
        }
      }
      
      return id;
    });
  }

  @override
  Future<void> updateAdjustment(StockAdjustmentModel adjustment) async {
    if (adjustment.id == null) {
      throw Exception('Adjustment id is required for update');
    }

    final existing = await getAdjustment(adjustment.id!);
    if (existing.status == TransferStatus.completed) {
      throw Exception('لا يمكن تعديل تسوية مرحّلة');
    }

    final db = await databaseService.database;
    await db.transaction((txn) async {
      await txn.update(
        'stock_settlements',
        adjustment.toMap(),
        where: 'id = ?',
        whereArgs: [adjustment.id],
      );

      // Replace lines
      await txn.delete(
        'stock_settlement_lines',
        where: 'stock_settlement_id = ?',
        whereArgs: [adjustment.id],
      );
      for (var line in adjustment.lines) {
        final lineModel = line is StockAdjustmentLineModel ? line : StockAdjustmentLineModel.fromEntity(line);
        await txn.insert(
          'stock_settlement_lines',
          {...lineModel.toMap(), 'stock_settlement_id': adjustment.id},
        );
      }
    });
  }

  @override
  Future<void> updateAdjustmentStatus(int id, TransferStatus status) async {
    final db = await databaseService.database;
    await db.update(
      'stock_settlements',
      {
        'status': status.value,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> postAdjustment(int id) async {
    final db = await databaseService.database;
    
    await db.transaction((txn) async {
      // Re-fetch inside transaction for atomicity
      final headerMaps = await txn.query(
        'stock_settlements',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (headerMaps.isEmpty) throw Exception('Adjustment not found');
      final status = TransferStatus.fromValue(
          headerMaps.first['status'] as int? ?? 0);
      if (status == TransferStatus.completed) {
        throw Exception('تم ترحيل هذه التسوية مسبقاً');
      }
      final lineMaps = await txn.query(
        'stock_settlement_lines',
        where: 'stock_settlement_id = ?',
        whereArgs: [id],
      );
      final lines = lineMaps.map((m) => StockAdjustmentLineModel.fromMap(m)).toList();
      if (lines.isEmpty) {
        throw Exception('لا توجد أصناف في التسوية للترحيل');
      }
      final adjustmentHeader = StockAdjustmentModel.fromMap(
          headerMaps.first, lines: lines.cast<StockAdjustmentLineEntity>());
      final adjustment = adjustmentHeader;

      // 1. Update adjustment status to posted
      await txn.update(
        'stock_settlements',
        {
          'status': TransferStatus.completed.value,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      double totalValue = 0.0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isIncrease = adjustment.type == AdjustmentType.increase;

      // 2. Process stock movements
      for (var line in adjustment.lines) {
        final quantity = isIncrease ? line.quantity : -line.quantity;
        final unitCost = line.amount; // unit cost

        // Current stock row (for avg cost blending + balance_after)
        final stockResult = await txn.query(
          'warehouse_stocks',
          columns: ['quantity', 'avg_cost'],
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [line.categoryId, adjustment.stockId],
          limit: 1,
        );

        final currentQty = stockResult.isNotEmpty
            ? (stockResult.first['quantity'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        final currentAvg = stockResult.isNotEmpty
            ? (stockResult.first['avg_cost'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        final newQty = currentQty + quantity;
        if (!isIncrease && stockResult.isEmpty) {
          throw Exception(
              'لا يمكن تسجيل نقص لمنتج غير موجود في هذا المخزن: ${line.categoryId}');
        }
        if (newQty < -0.0001) {
          throw Exception(
              'كمية النقص للمنتج ${line.statement} أكبر من المتاح ($currentQty)');
        }

        // Movement cost and line value:
        // - Increase: at the user-entered unit cost; blend avg cost.
        // - Decrease: at the current weighted average cost (correct COGS basis).
        double movementCost;
        double lineTotal;
        double newAvgCost = currentAvg;

        if (isIncrease) {
          movementCost = unitCost;
          lineTotal = line.quantity * unitCost;
          if (newQty > 0) {
            newAvgCost =
                ((currentQty * currentAvg) + (line.quantity * unitCost)) /
                    newQty;
          }
        } else {
          movementCost = currentAvg > 0 ? currentAvg : unitCost;
          lineTotal = line.quantity * movementCost;
        }
        totalValue += lineTotal;

        if (stockResult.isNotEmpty) {
          await txn.update(
            'warehouse_stocks',
            {
              'quantity': newQty,
              'avg_cost': newAvgCost,
              'last_modification_time': now,
            },
            where: 'product_id = ? AND warehouse_id = ?',
            whereArgs: [line.categoryId, adjustment.stockId],
          );
        } else {
          await txn.insert('warehouse_stocks', {
            'product_id': line.categoryId,
            'warehouse_id': adjustment.stockId,
            'quantity': newQty,
            'avg_cost': isIncrease ? unitCost : 0.0,
            'last_cost': isIncrease ? unitCost : 0.0,
            'creation_time': now,
            'last_modification_time': now,
          });
        }

        // Stock movement with real balance_after
        await txn.insert('stock_movements', {
          'product_id': line.categoryId,
          'warehouse_id': adjustment.stockId,
          'movement_type': 'adjustment',
          'quantity': quantity,
          'unit_cost': movementCost,
          'total_cost': lineTotal,
          'balance_after': newQty,
          'reference_type': 'stock_adjustment',
          'reference_id': id,
          'reference_number': adjustment.number,
          'creation_time': now,
          'notes': line.statement,
        });
      }

      // 3. Create Journal Entry (balanced)
      // Increase (Gain): Dr Inventory / Cr Settlement Income (4200)
      // Decrease (Loss):  Dr Settlement Loss (5200) / Cr Inventory
      if (totalValue > 0.001) {
        final inventoryAccountId = await _getOrCreateAccount(
          txn,
          code: '1003',
          cId: 1130,
          name: 'المخزون',
          type: 1,
        );
        final adjustmentAccountId = isIncrease
            ? await _getOrCreateAccount(
                txn,
                code: '4200',
                cId: 4200,
                name: 'إيرادات تسوية المخزون',
                type: 4,
              )
            : await _getOrCreateAccount(
                txn,
                code: '5200',
                cId: 5200,
                name: 'خسائر تسوية المخزون',
                type: 5,
              );

        final journalNumber = await _nextJournalNumber(txn, 'ADJ');

        final currencyId = await _resolveCurrencyId(txn);

        final journalEntryId = await txn.insert('journal_entries', {
          'number': journalNumber,
          'entry_date': now,
          'description': 'تسوية مخزنية رقم ${adjustment.number}',
          'reference_type': 'stock_adjustment',
          'reference_id': id,
          'reference_number': adjustment.number,
          'status': 2,
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
          'currency_id': currencyId,
          'debit_amount': totalValue,
          'credit_amount': 0.0,
          'description': isIncrease ? 'زيادة مخزون' : 'عجز مخزون',
        });
        
        // Update Debit Account Balance
        await _applyAccountBalanceDelta(txn, debitAccount, totalValue);

        // Credit Line
        final creditAccount = isIncrease ? adjustmentAccountId : inventoryAccountId;
        final creditMeta = await _getAccountMeta(txn, creditAccount);
        await txn.insert('journal_entry_lines', {
          'journal_entry_id': journalEntryId,
          'line_number': 2,
          'account_id': creditAccount,
          'account_code': creditMeta['code'],
          'account_name': creditMeta['name'],
          'currency_id': currencyId,
          'debit_amount': 0.0,
          'credit_amount': totalValue,
          'description': isIncrease ? 'إيراد تسوية' : 'تخفيض مخزون',
        });

        // Update Credit Account Balance
        await _applyAccountBalanceDelta(txn, creditAccount, -totalValue);
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
  /// Resolves an account by code, creating it if missing (works for
  /// existing databases where the settlement accounts were never seeded).
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

  /// Applies delta respecting normal balance (debit vs credit).
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
}
