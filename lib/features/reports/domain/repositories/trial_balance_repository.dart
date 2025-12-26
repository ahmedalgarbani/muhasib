import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';

abstract class TrialBalanceRepository {
  Future<Either<Failure, List<TrialBalanceEntity>>> getTrialBalance({
    required ReportFilter filter,
  });

  Future<Either<Failure, TrialBalanceSummary>> getTrialBalanceSummary({
    required ReportFilter filter,
  });
}
