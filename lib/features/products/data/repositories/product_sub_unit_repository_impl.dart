import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/data/datasources/product_sub_unit_local_datasource.dart';
import 'package:muhasib/features/products/data/models/product_sub_unit_model.dart';
import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_sub_unit_repository.dart';

class ProductSubUnitRepositoryImpl implements ProductSubUnitRepository {
  final ProductSubUnitLocalDataSource localDataSource;

  ProductSubUnitRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ProductSubUnitEntity>>> getAllSubUnits() async {
    try {
      final subUnits = await localDataSource.getAllSubUnits();
      return Right(subUnits);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductSubUnitEntity>>> getSubUnitsByProduct(int categoryId) async {
    try {
      final subUnits = await localDataSource.getSubUnitsByProduct(categoryId);
      return Right(subUnits);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProductSubUnitEntity>> getSubUnitById(int id) async {
    try {
      final subUnit = await localDataSource.getSubUnitById(id);
      return Right(subUnit);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createSubUnit(ProductSubUnitEntity subUnit) async {
    try {
      final model = subUnit is ProductSubUnitModel
          ? subUnit
          : ProductSubUnitModel.fromEntity(subUnit);
      final id = await localDataSource.insertSubUnit(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSubUnit(ProductSubUnitEntity subUnit) async {
    try {
      final model = subUnit is ProductSubUnitModel
          ? subUnit
          : ProductSubUnitModel.fromEntity(subUnit);
      await localDataSource.updateSubUnit(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSubUnit(int id) async {
    try {
      await localDataSource.deleteSubUnit(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setMainUnit(int categoryId, int subUnitId) async {
    try {
      await localDataSource.setMainUnit(categoryId, subUnitId);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
