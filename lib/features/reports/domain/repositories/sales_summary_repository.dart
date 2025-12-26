import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/sales_summary_entity.dart';

abstract class SalesSummaryRepository {
  Future<Either<Failure, SalesSummaryEntity>> getSalesSummary({
    required ReportFilter filter,
  });
}
