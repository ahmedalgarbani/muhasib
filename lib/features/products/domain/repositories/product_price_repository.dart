import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/domain/entities/product_price_entity.dart';

abstract class ProductPriceRepository {
  Future<Either<Failure, List<ProductPriceEntity>>> getAllPrices();
  Future<Either<Failure, List<ProductPriceEntity>>> getPricesBySubUnit(int subUnitId);
  Future<Either<Failure, ProductPriceEntity?>> getPriceBySubUnitAndLevel(int subUnitId, int priceLevel);
  Future<Either<Failure, int>> savePrice(ProductPriceEntity price);
  Future<Either<Failure, void>> deletePrice(int id);
}
