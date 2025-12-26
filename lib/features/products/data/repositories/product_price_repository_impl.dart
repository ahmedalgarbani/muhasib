import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/data/datasources/product_price_local_datasource.dart';
import 'package:muhasib/features/products/data/models/product_price_model.dart';
import 'package:muhasib/features/products/domain/entities/product_price_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_price_repository.dart';

class ProductPriceRepositoryImpl implements ProductPriceRepository {
  final ProductPriceLocalDataSource localDataSource;

  ProductPriceRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ProductPriceEntity>>> getAllPrices() async {
    try {
      final prices = await localDataSource.getAllPrices();
      return Right(prices);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductPriceEntity>>> getPricesBySubUnit(int subUnitId) async {
    try {
      final prices = await localDataSource.getPricesBySubUnit(subUnitId);
      return Right(prices);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductPriceEntity?>> getPriceBySubUnitAndLevel(int subUnitId, int priceLevel) async {
    try {
      final price = await localDataSource.getPriceBySubUnitAndLevel(subUnitId, priceLevel);
      return Right(price);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> savePrice(ProductPriceEntity price) async {
    try {
      final model = ProductPriceModel.fromEntity(price);
      
      // Check if price already exists for this sub unit and level
      final existing = await localDataSource.getPriceBySubUnitAndLevel(
        price.categorySubUnitId!,
        price.priceLevel,
      );
      
      if (existing != null) {
        // Update existing
        final updatedModel = ProductPriceModel(
          id: existing.id,
          categorySubUnitId: price.categorySubUnitId,
          priceLevel: price.priceLevel,
          bidAmount: price.bidAmount,
          bidLocalAmount: price.bidLocalAmount,
          bidCurrencyCode: price.bidCurrencyCode,
          bidExchangeRate: price.bidExchangeRate,
          bidCurrencyId: price.bidCurrencyId,
          minQuantity: price.minQuantity,
        );
        await localDataSource.updatePrice(updatedModel);
        return Right(existing.id!);
      } else {
        // Insert new
        final id = await localDataSource.insertPrice(model);
        return Right(id);
      }
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePrice(int id) async {
    try {
      await localDataSource.deletePrice(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
