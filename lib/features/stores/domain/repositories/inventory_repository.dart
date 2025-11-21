import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_entity.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryEntity>>> getInventories();
  Future<Either<Failure, InventoryEntity>> getInventoryById(int id);
  Future<Either<Failure, List<InventoryEntity>>> getInventoriesByWarehouse(int warehouseId);
  Future<Either<Failure, List<InventoryEntity>>> getInventoriesByStatus(TransferStatus status);
  Future<Either<Failure, int>> createInventory(InventoryEntity inventory);
  Future<Either<Failure, void>> updateInventory(InventoryEntity inventory);
  Future<Either<Failure, void>> deleteInventory(int id);
  Future<Either<Failure, void>> updateInventoryStatus(int id, TransferStatus status);
  Future<Either<Failure, void>> postInventory(int id);
  Future<Either<Failure, List<InventoryLineEntity>>> getCurrentStock(int warehouseId);
}
