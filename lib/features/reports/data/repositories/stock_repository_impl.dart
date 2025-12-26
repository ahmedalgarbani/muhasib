import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/data/datasources/stock_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/stock_entity.dart';
import 'package:muhasib/features/reports/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  final StockDataSource dataSource;

  StockRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<StockEntity>>> getStockReport({
    int? warehouseId,
    String? searchQuery,
    String? categoryId,
  }) async {
    try {
      final result = await dataSource.getStockReport(
        warehouseId: warehouseId,
        searchQuery: searchQuery,
        categoryId: categoryId,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل تقرير المخزون: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StockSummary>> getStockSummary({
    int? warehouseId,
  }) async {
    try {
      final result = await dataSource.getStockSummary(
        warehouseId: warehouseId,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل ملخص المخزون: ${e.toString()}'));
    }
  }
}
