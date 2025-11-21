import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/data/datasources/inventory_local_datasource.dart';
import 'package:muhasib/features/stores/data/models/inventory_model.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_entity.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource localDataSource;

  InventoryRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<InventoryEntity>>> getInventories() async {
    try {
      final inventories = await localDataSource.getInventories();
      return Right(inventories.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryEntity>>> getInventoriesByWarehouse(int warehouseId) async {
    try {
      final inventories = await localDataSource.getInventoriesByWarehouse(warehouseId);
      return Right(inventories.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryEntity>> getInventoryById(int id) async {
    try {
      final inventory = await localDataSource.getInventory(id);
      return Right(inventory.toEntity());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryEntity>>> getInventoriesByStatus(TransferStatus status) async {
    try {
      final inventories = await localDataSource.getInventories();
      // Filter by status
      final filtered = inventories.where((inv) => inv.status == status).toList();
      return Right(filtered.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateInventoryStatus(int id, TransferStatus status) async {
    try {
      // This method would update only the status
      final inventory = await localDataSource.getInventory(id);
      final updated = InventoryModel(
        id: inventory.id,
        number: inventory.number,
        date: inventory.date,
        statement: inventory.statement,
        parentNumber: inventory.parentNumber,
        parentId: inventory.parentId,
        status: status,
        stockId: inventory.stockId,
        inventoryType: inventory.inventoryType,
        totalDifference: inventory.totalDifference,
        totalValue: inventory.totalValue,
        lines: inventory.lines,
        creatorId: inventory.creatorId,
        lastModifierId: inventory.lastModifierId,
        concurrencyStamp: inventory.concurrencyStamp,
        extraProperties: inventory.extraProperties,
        creationTime: inventory.creationTime,
        lastModificationTime: inventory.lastModificationTime,
      );
      await localDataSource.updateInventory(updated);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryLineEntity>>> getCurrentStock(int warehouseId) async {
    try {
      // This would query current stock levels for a warehouse
      // For now, return empty list as this requires complex query
      return const Right([]);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createInventory(InventoryEntity inventory) async {
    try {
      final model = InventoryModel.fromEntity(inventory);
      final id = await localDataSource.createInventory(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateInventory(InventoryEntity inventory) async {
    try {
      final model = InventoryModel.fromEntity(inventory);
      await localDataSource.updateInventory(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> postInventory(int id) async {
    try {
      await localDataSource.postInventory(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInventory(int id) async {
    try {
      await localDataSource.deleteInventory(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}
