import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/product_price_report_entity.dart';

abstract class ProductPriceReportRepository {
  Future<Either<Failure, List<ProductPriceReportEntity>>> getPrices({
    List<int>? productIds, // null/empty = الكل
    String? searchQuery,
  });

  Future<Either<Failure, List<ProductPriceReportEntity>>> getAllPrices();
}
