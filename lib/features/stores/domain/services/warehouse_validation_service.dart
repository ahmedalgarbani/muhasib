import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';

/// Service to validate warehouse operations before execution
/// Prevents data integrity issues like deleting warehouses with movements
abstract class WarehouseValidationService {
  /// Checks if a warehouse can be safely deleted
  Future<Either<Failure, bool>> canDeleteWarehouse(int warehouseId);
  
  /// Gets statistics about warehouse usage
  Future<Either<Failure, WarehouseUsageStats>> getWarehouseUsageStats(int warehouseId);
  
  /// Validates if warehouse has required accounting setup
  Future<Either<Failure, bool>> hasValidAccountingSetup(int warehouseId);
}

class WarehouseUsageStats {
  final int stockMovementsCount;
  final int invoiceLinesCount;
  final int productsWithStockCount;
  final double totalStockValue;
  final bool hasOpenTransfers;
  
  const WarehouseUsageStats({
    required this.stockMovementsCount,
    required this.invoiceLinesCount,
    required this.productsWithStockCount,
    required this.totalStockValue,
    required this.hasOpenTransfers,
  });
  
  bool get isEmpty => 
    stockMovementsCount == 0 && 
    invoiceLinesCount == 0 && 
    productsWithStockCount == 0;
    
  bool get canDelete => isEmpty && !hasOpenTransfers;
}
