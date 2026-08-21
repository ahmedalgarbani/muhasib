import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/inventory_reports/data/datasources/product_price_report_datasource.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/product_price_report_entity.dart';
import 'package:muhasib/features/inventory_reports/domain/repositories/product_price_report_repository.dart';

class ProductPriceReportRepositoryImpl implements ProductPriceReportRepository {
  final ProductPriceReportDataSource dataSource;

  ProductPriceReportRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<ProductPriceReportEntity>>> getPrices({
    List<int>? productIds,
    String? searchQuery,
  }) async {
    try {
      final models = await dataSource.getPrices(productIds: productIds, searchQuery: searchQuery);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductPriceReportEntity>>> getAllPrices() async {
    return getPrices();
  }
}
