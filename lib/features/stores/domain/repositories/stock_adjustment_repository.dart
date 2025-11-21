import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

abstract class StockAdjustmentRepository {
  Future<Either<Failure, List<StockAdjustmentEntity>>> getAdjustments();
  Future<Either<Failure, StockAdjustmentEntity>> getAdjustmentById(int id);
  Future<Either<Failure, List<StockAdjustmentEntity>>> getAdjustmentsByWarehouse(int warehouseId);
  Future<Either<Failure, List<StockAdjustmentEntity>>> getAdjustmentsByStatus(TransferStatus status);
  Future<Either<Failure, int>> createAdjustment(StockAdjustmentEntity adjustment);
  Future<Either<Failure, void>> updateAdjustment(StockAdjustmentEntity adjustment);
  Future<Either<Failure, void>> deleteAdjustment(int id);
  Future<Either<Failure, void>> updateAdjustmentStatus(int id, TransferStatus status);
  Future<Either<Failure, void>> approveAdjustment(int id);
  Future<Either<Failure, void>> rejectAdjustment(int id, String reason);
  Future<Either<Failure, void>> postAdjustment(int id);
}
