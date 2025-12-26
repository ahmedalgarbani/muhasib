import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/domain/entities/stock_entity.dart';

abstract class StockRepository {
  Future<Either<Failure, List<StockEntity>>> getStockReport({
    int? warehouseId,
    String? searchQuery,
    String? categoryId,
  });

  Future<Either<Failure, StockSummary>> getStockSummary({
    int? warehouseId,
  });
}
