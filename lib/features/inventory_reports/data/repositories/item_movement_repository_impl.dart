import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/inventory_reports/data/datasources/item_movement_datasource.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/item_movement_entity.dart';
import 'package:muhasib/features/inventory_reports/domain/repositories/item_movement_repository.dart';

class ItemMovementRepositoryImpl implements ItemMovementRepository {
  final ItemMovementDataSource dataSource;

  ItemMovementRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> getMovements({
    int? warehouseId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      final models = await dataSource.getMovements(
        warehouseId: warehouseId,
        searchQuery: searchQuery,
        limit: limit,
        offset: offset,
      );
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByProduct(
    int productId, {
    int? warehouseId,
  }) async {
    try {
      final models = await dataSource.getMovementsByProduct(productId, warehouseId: warehouseId);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}
