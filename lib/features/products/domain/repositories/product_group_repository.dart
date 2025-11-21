import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';

abstract class ProductGroupRepository {
  Future<Either<Failure, List<ProductGroupEntity>>> getAllGroups();
  Future<Either<Failure, ProductGroupEntity>> getGroupById(int id);
  Future<Either<Failure, int>> createGroup(ProductGroupEntity group);
  Future<Either<Failure, void>> updateGroup(ProductGroupEntity group);
  Future<Either<Failure, void>> deleteGroup(int id);
  Future<Either<Failure, List<ProductGroupEntity>>> searchGroups(String query);
  Future<Either<Failure, List<ProductGroupEntity>>> getGroupsByParent(int? parentId);
}
