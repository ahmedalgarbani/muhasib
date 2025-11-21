import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/data/datasources/product_unit_local_datasource.dart';
import 'package:muhasib/features/products/data/models/product_unit_model.dart';
import 'package:muhasib/features/products/domain/entities/product_unit_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_unit_repository.dart';

class ProductUnitRepositoryImpl implements ProductUnitRepository {
  final ProductUnitLocalDataSource localDataSource;

  ProductUnitRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ProductUnitEntity>>> getAllUnits() async {
    try {
      final units = await localDataSource.getAllUnits();
      return Right(units);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProductUnitEntity>> getUnitById(int id) async {
    try {
      final unit = await localDataSource.getUnitById(id);
      return Right(unit);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createUnit(ProductUnitEntity unit) async {
    try {
      final model = unit is ProductUnitModel
          ? unit
          : ProductUnitModel.fromEntity(unit);
      final id = await localDataSource.insertUnit(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUnit(ProductUnitEntity unit) async {
    try {
      final model = unit is ProductUnitModel
          ? unit
          : ProductUnitModel.fromEntity(unit);
      await localDataSource.updateUnit(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUnit(int id) async {
    try {
      await localDataSource.deleteUnit(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductUnitEntity>>> searchUnits(String query) async {
    try {
      final units = await localDataSource.searchUnits(query);
      return Right(units);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
