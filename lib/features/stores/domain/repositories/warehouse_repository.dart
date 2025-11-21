import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';

abstract class WarehouseRepository {
  Future<Either<Failure, List<WarehouseEntity>>> getWarehouses();
  Future<Either<Failure, WarehouseEntity>> getWarehouseById(int id);
  Future<Either<Failure, WarehouseEntity?>> getMainWarehouse();
  Future<Either<Failure, List<WarehouseEntity>>> getActiveWarehouses();
  Future<Either<Failure, int>> createWarehouse(WarehouseEntity warehouse);
  Future<Either<Failure, void>> updateWarehouse(WarehouseEntity warehouse);
  Future<Either<Failure, void>> deleteWarehouse(int id);
  Future<Either<Failure, void>> setMainWarehouse(int id);
  Future<Either<Failure, List<WarehouseEntity>>> searchWarehouses(String query);
}
