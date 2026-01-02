import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/data/datasources/warehouse_local_datasource.dart';
import 'package:muhasib/features/stores/data/models/warehouse_model.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/domain/repositories/warehouse_repository.dart';
import 'package:muhasib/features/stores/domain/services/warehouse_validation_service.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  final WarehouseLocalDataSource localDataSource;
  final WarehouseValidationService? validationService;

  WarehouseRepositoryImpl(
    this.localDataSource, {
    this.validationService,
  });

  @override
  Future<Either<Failure, List<WarehouseEntity>>> getWarehouses() async {
    try {
      final warehouses = await localDataSource.getWarehouses();
      return Right(warehouses);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WarehouseEntity>> getWarehouseById(int id) async {
    try {
      final warehouse = await localDataSource.getWarehouseById(id);
      return Right(warehouse);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WarehouseEntity?>> getMainWarehouse() async {
    try {
      final warehouse = await localDataSource.getMainWarehouse();
      return Right(warehouse);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<WarehouseEntity>>> getActiveWarehouses() async {
    try {
      final warehouses = await localDataSource.getActiveWarehouses();
      return Right(warehouses);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createWarehouse(WarehouseEntity warehouse) async {
    try {
      final model = warehouse is WarehouseModel
          ? warehouse
          : WarehouseModel.fromEntity(warehouse);
      final id = await localDataSource.insertWarehouse(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateWarehouse(WarehouseEntity warehouse) async {
    try {
      final model = warehouse is WarehouseModel
          ? warehouse
          : WarehouseModel.fromEntity(warehouse);
      await localDataSource.updateWarehouse(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWarehouse(int id) async {
    try {
      // Validate before deletion if service is available
      if (validationService != null) {
        final statsResult = await validationService!.getWarehouseUsageStats(id);
        
        return statsResult.fold(
          (failure) => Left(failure),
          (stats) async {
            if (!stats.canDelete) {
              final reasons = <String>[];
              if (stats.stockMovementsCount > 0) {
                reasons.add('يوجد ${stats.stockMovementsCount} حركة مخزون');
              }
              if (stats.invoiceLinesCount > 0) {
                reasons.add('يوجد ${stats.invoiceLinesCount} سطر فاتورة');
              }
              if (stats.productsWithStockCount > 0) {
                reasons.add('يوجد ${stats.productsWithStockCount} منتج برصيد');
              }
              if (stats.hasOpenTransfers) {
                reasons.add('يوجد تحويلات مفتوحة');
              }
              
              return Left(ValidationFailure( message: 
                'لا يمكن حذف المخزن:\n${reasons.join('\n')}',
              ));
            }
            
            await localDataSource.deleteWarehouse(id);
            return const Right(null);
          },
        );
      }
      
      // Fallback: delete without validation (not recommended)
      await localDataSource.deleteWarehouse(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setMainWarehouse(int id) async {
    try {
      await localDataSource.setMainWarehouse(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<WarehouseEntity>>> searchWarehouses(String query) async {
    try {
      final warehouses = await localDataSource.searchWarehouses(query);
      return Right(warehouses);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
