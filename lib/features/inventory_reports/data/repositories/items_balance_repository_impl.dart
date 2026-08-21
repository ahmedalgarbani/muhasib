import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/inventory_reports/data/datasources/items_balance_datasource.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/items_balance_entity.dart';
import 'package:muhasib/features/inventory_reports/domain/repositories/items_balance_repository.dart';

class ItemsBalanceRepositoryImpl implements ItemsBalanceRepository {
  final ItemsBalanceDataSource dataSource;

  ItemsBalanceRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<ItemsBalanceEntity>>> getBalances({
    int? warehouseId,
    String? searchQuery,
  }) async {
    try {
      final models = await dataSource.getBalances(warehouseId: warehouseId, searchQuery: searchQuery);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ItemsBalanceEntity>> getBalanceForProduct(int productId, {int? warehouseId}) async {
    try {
      final list = await dataSource.getBalances(warehouseId: warehouseId);
      final found = list.firstWhere((e) => e.productId == productId);
      return Right(found.toEntity());
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}
