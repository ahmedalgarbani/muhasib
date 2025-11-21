import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/domain/entities/item_movement_entity.dart';

abstract class ItemMovementRepository {
  Future<Either<Failure, List<ItemMovementEntity>>> getAllMovements();
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByProduct(int categoryId);
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByStock(int stockId);
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByType(int transDocType);
  Future<Either<Failure, List<ItemMovementEntity>>> searchMovements(String query);
}
