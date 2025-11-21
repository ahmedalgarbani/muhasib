import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/data/datasources/item_movement_local_datasource.dart';
import 'package:muhasib/features/products/domain/entities/item_movement_entity.dart';
import 'package:muhasib/features/products/domain/repositories/item_movement_repository.dart';

class ItemMovementRepositoryImpl implements ItemMovementRepository {
  final ItemMovementLocalDataSource localDataSource;

  ItemMovementRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> getAllMovements() async {
    try {
      final movements = await localDataSource.getAllMovements();
      return Right(movements);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByProduct(int categoryId) async {
    try {
      final movements = await localDataSource.getMovementsByProduct(categoryId);
      return Right(movements);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
      final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;
      final movements = await localDataSource.getMovementsByDateRange(startTimestamp, endTimestamp);
      return Right(movements);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByStock(int stockId) async {
    try {
      final movements = await localDataSource.getMovementsByStock(stockId);
      return Right(movements);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> getMovementsByType(int transDocType) async {
    try {
      final movements = await localDataSource.getMovementsByType(transDocType);
      return Right(movements);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ItemMovementEntity>>> searchMovements(String query) async {
    try {
      final movements = await localDataSource.searchMovements(query);
      return Right(movements);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
