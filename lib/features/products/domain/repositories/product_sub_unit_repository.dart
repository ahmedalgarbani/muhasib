import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';

abstract class ProductSubUnitRepository {
  Future<Either<Failure, List<ProductSubUnitEntity>>> getAllSubUnits();
  Future<Either<Failure, List<ProductSubUnitEntity>>> getSubUnitsByProduct(int categoryId);
  Future<Either<Failure, ProductSubUnitEntity>> getSubUnitById(int id);
  Future<Either<Failure, int>> createSubUnit(ProductSubUnitEntity subUnit);
  Future<Either<Failure, void>> updateSubUnit(ProductSubUnitEntity subUnit);
  Future<Either<Failure, void>> deleteSubUnit(int id);
  Future<Either<Failure, void>> setMainUnit(int categoryId, int subUnitId);
}
