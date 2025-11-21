import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/data/datasources/product_local_datasource.dart';
import 'package:muhasib/features/products/data/models/product_model.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    try {
      final products = await localDataSource.getProducts();
      return Right(products);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(int id) async {
    try {
      final product = await localDataSource.getProductById(id);
      return Right(product);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createProduct(ProductEntity product) async {
    try {
      final model = product is ProductModel
          ? product
          : ProductModel.fromEntity(product);
      final id = await localDataSource.insertProduct(model);
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    try {
      final model = product is ProductModel
          ? product
          : ProductModel.fromEntity(product);
      await localDataSource.updateProduct(model);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      await localDataSource.deleteProduct(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(String query) async {
    try {
      final products = await localDataSource.searchProducts(query);
      return Right(products);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByGroup(int groupId) async {
    try {
      final products = await localDataSource.getProductsByGroup(groupId);
      return Right(products);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByStock(int stockId) async {
    try {
      final products = await localDataSource.getProductsByStock(stockId);
      return Right(products);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
