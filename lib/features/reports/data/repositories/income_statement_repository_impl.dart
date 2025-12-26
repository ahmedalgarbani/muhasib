import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/data/datasources/income_statement_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';
import 'package:muhasib/features/reports/domain/repositories/income_statement_repository.dart';

class IncomeStatementRepositoryImpl implements IncomeStatementRepository {
  final IncomeStatementDataSource dataSource;

  IncomeStatementRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<IncomeStatementEntity>>> getIncomeStatementData({
    required ReportFilter filter,
  }) async {
    try {
      final result = await dataSource.getIncomeStatementData(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل قائمة الدخل: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, IncomeStatementSummary>> getIncomeStatementSummary({
    required ReportFilter filter,
  }) async {
    try {
      final result = await dataSource.getIncomeStatementSummary(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل ملخص قائمة الدخل: ${e.toString()}'));
    }
  }
}
