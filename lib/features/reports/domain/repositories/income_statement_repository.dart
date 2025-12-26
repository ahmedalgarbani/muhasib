import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';

abstract class IncomeStatementRepository {
  Future<Either<Failure, List<IncomeStatementEntity>>> getIncomeStatementData({
    required ReportFilter filter,
  });

  Future<Either<Failure, IncomeStatementSummary>> getIncomeStatementSummary({
    required ReportFilter filter,
  });
}
