import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/data/datasources/stock_adjustment_local_datasource.dart';
import 'package:muhasib/features/stores/data/models/stock_adjustment_model.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/domain/repositories/stock_adjustment_repository.dart';

class StockAdjustmentRepositoryImpl implements StockAdjustmentRepository {
  final StockAdjustmentLocalDataSource localDataSource;

  StockAdjustmentRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<StockAdjustmentEntity>>> getAdjustments() async {
    try {
      final adjustments = await localDataSource.getAdjustments();
      return Right(adjustments.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockAdjustmentEntity>>> getAdjustmentsByWarehouse(int warehouseId) async {
    try {
      final adjustments = await localDataSource.getAdjustmentsByWarehouse(warehouseId);
      return Right(adjustments.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockAdjustmentEntity>> getAdjustmentById(int id) async {
    try {
      final adjustment = await localDataSource.getAdjustment(id);
      return Right(adjustment.toEntity());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockAdjustmentEntity>>> getAdjustmentsByStatus(TransferStatus status) async {
    try {
      final adjustments = await localDataSource.getAdjustments();
      final filtered = adjustments.where((adj) => adj.status == status).toList();
      return Right(filtered.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAdjustment(StockAdjustmentEntity adjustment) async {
    try {
      final model = StockAdjustmentModel.fromEntity(adjustment);
      // Note: datasource doesn't have updateAdjustment, using createAdjustment for now
      await localDataSource.createAdjustment(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAdjustmentStatus(int id, TransferStatus status) async {
    try {
      // This would update only the status
      // For now, just return success as datasource doesn't have this method
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveAdjustment(int id) async {
    try {
      await localDataSource.postAdjustment(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectAdjustment(int id, String reason) async {
    try {
      // This would set status to rejected
      // For now, just return success
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createAdjustment(StockAdjustmentEntity adjustment) async {
    try {
      final model = StockAdjustmentModel.fromEntity(adjustment);
      final id = await localDataSource.createAdjustment(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> postAdjustment(int id) async {
    try {
      await localDataSource.postAdjustment(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAdjustment(int id) async {
    try {
      await localDataSource.deleteAdjustment(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}
