import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/account_statement_entity.dart';

abstract class AccountStatementRepository {
  Future<Either<Failure, List<AccountStatementEntity>>> getAccountStatement({
    required int accountId,
    required ReportFilter filter,
  });

  Future<Either<Failure, AccountStatementSummary>> getAccountStatementSummary({
    required int accountId,
    required ReportFilter filter,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getAllAccounts();
}
