import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/stores/domain/services/warehouse_validation_service.dart';

class WarehouseValidationServiceImpl implements WarehouseValidationService {
  final DatabaseService databaseService;

  WarehouseValidationServiceImpl({required this.databaseService});

  @override
  Future<Either<Failure, bool>> canDeleteWarehouse(int warehouseId) async {
    try {
      final stats = await _getUsageStats(warehouseId);
      return Right(stats.canDelete);
    } catch (e) {
      return Left(CacheFailure('فشل في فحص المخزن: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WarehouseUsageStats>> getWarehouseUsageStats(int warehouseId) async {
    try {
      final stats = await _getUsageStats(warehouseId);
      return Right(stats);
    } catch (e) {
      return Left(CacheFailure('فشل في جلب إحصائيات المخزن: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasValidAccountingSetup(int warehouseId) async {
    try {
      final db = await databaseService.database;
      
      // Check if warehouse has a linked inventory account
      final result = await db.rawQuery('''
        SELECT account_id FROM stocks WHERE id = ?
      ''', [warehouseId]);
      
      if (result.isEmpty) {
        return const Right(false);
      }
      
      final accountId = result.first['account_id'] as int?;
      if (accountId == null) {
        return const Right(false);
      }
      
      // Verify the account exists and is active
      final accountResult = await db.rawQuery('''
        SELECT id FROM accounts WHERE id = ? AND is_active = 1
      ''', [accountId]);
      
      return Right(accountResult.isNotEmpty);
    } catch (e) {
      return Left(CacheFailure('فشل في فحص الإعداد المحاسبي: ${e.toString()}'));
    }
  }

  Future<WarehouseUsageStats> _getUsageStats(int warehouseId) async {
    final db = await databaseService.database;

    // Count stock movements
    final movementsResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM stock_movements WHERE warehouse_id = ?
    ''', [warehouseId]);
    final movementsCount = (movementsResult.first['count'] as int?) ?? 0;

    // Count invoice lines referencing this warehouse
    final invoiceLinesResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM invoice_lines WHERE stock_id = ?
    ''', [warehouseId]);
    final invoiceLinesCount = (invoiceLinesResult.first['count'] as int?) ?? 0;

    // Count products with stock in this warehouse
    final productsResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT product_id) as count, 
             COALESCE(SUM(quantity * avg_cost), 0) as total_value
      FROM warehouse_stocks 
      WHERE warehouse_id = ? AND quantity != 0
    ''', [warehouseId]);
    final productsCount = (productsResult.first['count'] as int?) ?? 0;
    final totalValue = (productsResult.first['total_value'] as num?)?.toDouble() ?? 0.0;

    // Check for pending/open transfers
    final transfersResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM stock_transfers 
      WHERE (from_warehouse_id = ? OR to_warehouse_id = ?) 
      AND status IN (0, 1, 2)
    ''', [warehouseId, warehouseId]);
    final hasOpenTransfers = ((transfersResult.first['count'] as int?) ?? 0) > 0;

    return WarehouseUsageStats(
      stockMovementsCount: movementsCount,
      invoiceLinesCount: invoiceLinesCount,
      productsWithStockCount: productsCount,
      totalStockValue: totalValue,
      hasOpenTransfers: hasOpenTransfers,
    );
  }
}
