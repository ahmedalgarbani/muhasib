import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

abstract class StockTransferRepository {
  Future<Either<Failure, List<StockTransferEntity>>> getTransfers();
  Future<Either<Failure, StockTransferEntity>> getTransferById(int id);
  Future<Either<Failure, List<StockTransferEntity>>> getTransfersByWarehouse(int warehouseId);
  Future<Either<Failure, List<StockTransferEntity>>> getTransfersByStatus(TransferStatus status);
  Future<Either<Failure, int>> createTransfer(StockTransferEntity transfer);
  Future<Either<Failure, void>> updateTransfer(StockTransferEntity transfer);
  Future<Either<Failure, void>> deleteTransfer(int id);
  Future<Either<Failure, void>> updateTransferStatus(int id, TransferStatus status);
  Future<Either<Failure, void>> approveTransfer(int id);
  Future<Either<Failure, void>> rejectTransfer(int id, String reason);
  Future<Either<Failure, void>> completeTransfer(int id);
}
