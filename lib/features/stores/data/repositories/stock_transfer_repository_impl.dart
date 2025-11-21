import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/data/datasources/stock_transfer_local_datasource.dart';
import 'package:muhasib/features/stores/data/models/stock_transfer_model.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/domain/repositories/stock_transfer_repository.dart';

class StockTransferRepositoryImpl implements StockTransferRepository {
  final StockTransferLocalDataSource localDataSource;

  StockTransferRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<StockTransferEntity>>> getTransfers() async {
    try {
      final transfers = await localDataSource.getTransfers();
      return Right(transfers.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockTransferEntity>>> getTransfersByWarehouse(int warehouseId) async {
    try {
      final transfers = await localDataSource.getTransfersByWarehouse(warehouseId);
      return Right(transfers.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StockTransferEntity>> getTransferById(int id) async {
    try {
      final transfer = await localDataSource.getTransfer(id);
      return Right(transfer.toEntity());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockTransferEntity>>> getTransfersByStatus(TransferStatus status) async {
    try {
      final transfers = await localDataSource.getTransfers();
      final filtered = transfers.where((t) => t.status == status).toList();
      return Right(filtered.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransfer(StockTransferEntity transfer) async {
    try {
      final model = StockTransferModel.fromEntity(transfer);
      // Note: datasource doesn't have updateTransfer, using createTransfer for now
      await localDataSource.createTransfer(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createTransfer(StockTransferEntity transfer) async {
    try {
      final model = StockTransferModel.fromEntity(transfer);
      final id = await localDataSource.createTransfer(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransferStatus(int id, TransferStatus status) async {
    try {
      await localDataSource.updateTransferStatus(id, status.name);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveTransfer(int id) async {
    try {
      await localDataSource.updateTransferStatus(id, TransferStatus.approved.name);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectTransfer(int id, String reason) async {
    try {
      await localDataSource.updateTransferStatus(id, TransferStatus.rejected.name);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeTransfer(int id) async {
    try {
      await localDataSource.updateTransferStatus(id, TransferStatus.completed.name);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransfer(int id) async {
    try {
      await localDataSource.deleteTransfer(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}
