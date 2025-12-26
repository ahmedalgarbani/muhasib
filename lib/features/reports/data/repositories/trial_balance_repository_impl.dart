import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/data/datasources/trial_balance_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';
import 'package:muhasib/features/reports/domain/repositories/trial_balance_repository.dart';

class TrialBalanceRepositoryImpl implements TrialBalanceRepository {
  final TrialBalanceDataSource dataSource;

  TrialBalanceRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<TrialBalanceEntity>>> getTrialBalance({
    required ReportFilter filter,
  }) async {
    try {
      final result = await dataSource.getTrialBalance(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل ميزان المراجعة: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TrialBalanceSummary>> getTrialBalanceSummary({
    required ReportFilter filter,
  }) async {
    try {
      final result = await dataSource.getTrialBalanceSummary(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل ملخص ميزان المراجعة: ${e.toString()}'));
    }
  }
}
