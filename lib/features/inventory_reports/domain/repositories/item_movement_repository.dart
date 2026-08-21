import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/item_movement_entity.dart';

abstract class ItemMovementRepository {
  Future<Either<Failure, List<ItemMovementEntity>>> getMovements({
    int? warehouseId,
    String? searchQuery,
    int? limit,
    int? offset,
  });

  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByProduct(
    int productId, {
    int? warehouseId,
  });
}
