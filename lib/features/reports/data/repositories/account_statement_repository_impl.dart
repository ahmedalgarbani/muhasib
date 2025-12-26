import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/data/datasources/account_statement_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/account_statement_entity.dart';
import 'package:muhasib/features/reports/domain/repositories/account_statement_repository.dart';

class AccountStatementRepositoryImpl implements AccountStatementRepository {
  final AccountStatementDataSource dataSource;

  AccountStatementRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<AccountStatementEntity>>> getAccountStatement({
    required int accountId,
    required ReportFilter filter,
  }) async {
    try {
      final result = await dataSource.getAccountStatement(
        accountId: accountId,
        filter: filter,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل كشف الحساب: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountStatementSummary>> getAccountStatementSummary({
    required int accountId,
    required ReportFilter filter,
  }) async {
    try {
      final result = await dataSource.getAccountStatementSummary(
        accountId: accountId,
        filter: filter,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل ملخص الحساب: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllAccounts() async {
    try {
      final result = await dataSource.getAllAccounts();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل في تحميل قائمة الحسابات: ${e.toString()}'));
    }
  }
}
