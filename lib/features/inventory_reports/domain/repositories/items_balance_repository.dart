import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/items_balance_entity.dart';

abstract class ItemsBalanceRepository {
  Future<Either<Failure, List<ItemsBalanceEntity>>> getBalances({
    int? warehouseId,
    String? searchQuery,
  });

  Future<Either<Failure, ItemsBalanceEntity>> getBalanceForProduct(
    int productId, {
    int? warehouseId,
  });
}
