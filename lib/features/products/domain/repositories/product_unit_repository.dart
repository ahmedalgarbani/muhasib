import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/domain/entities/product_unit_entity.dart';

abstract class ProductUnitRepository {
  Future<Either<Failure, List<ProductUnitEntity>>> getAllUnits();
  Future<Either<Failure, ProductUnitEntity>> getUnitById(int id);
  Future<Either<Failure, int>> createUnit(ProductUnitEntity unit);
  Future<Either<Failure, void>> updateUnit(ProductUnitEntity unit);
  Future<Either<Failure, void>> deleteUnit(int id);
  Future<Either<Failure, List<ProductUnitEntity>>> searchUnits(String query);
}
