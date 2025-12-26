import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/data/datasources/sales_summary_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/sales_summary_entity.dart';
import 'package:muhasib/features/reports/domain/repositories/sales_summary_repository.dart';

class SalesSummaryRepositoryImpl implements SalesSummaryRepository {
  final SalesSummaryDataSource dataSource;

  SalesSummaryRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, SalesSummaryEntity>> getSalesSummary({
    required ReportFilter filter,
  }) async {
    try {
      final result = await dataSource.getSalesSummary(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل ملخص المبيعات: ${e.toString()}'));
    }
  }
}
