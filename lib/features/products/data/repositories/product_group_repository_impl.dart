import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/data/datasources/product_group_local_datasource.dart';
import 'package:muhasib/features/products/data/models/product_group_model.dart';
import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_group_repository.dart';

class ProductGroupRepositoryImpl implements ProductGroupRepository {
  final ProductGroupLocalDataSource localDataSource;

  ProductGroupRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ProductGroupEntity>>> getAllGroups() async {
    try {
      final groups = await localDataSource.getAllGroups();
      return Right(groups);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProductGroupEntity>> getGroupById(int id) async {
    try {
      final group = await localDataSource.getGroupById(id);
      return Right(group);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createGroup(ProductGroupEntity group) async {
    try {
      final model = group is ProductGroupModel
          ? group
          : ProductGroupModel.fromEntity(group);
      final id = await localDataSource.insertGroup(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateGroup(ProductGroupEntity group) async {
    try {
      final model = group is ProductGroupModel
          ? group
          : ProductGroupModel.fromEntity(group);
      await localDataSource.updateGroup(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup(int id) async {
    try {
      await localDataSource.deleteGroup(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductGroupEntity>>> searchGroups(String query) async {
    try {
      final groups = await localDataSource.searchGroups(query);
      return Right(groups);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductGroupEntity>>> getGroupsByParent(int? parentId) async {
    try {
      final groups = await localDataSource.getGroupsByParent(parentId);
      return Right(groups);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
