import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/transaction_entity.dart';

abstract class TransactionsReportRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required ReportFilter filter,
    String? transactionType,
    String? sortBy,
    bool isAscending = false,
  });

  Future<Either<Failure, Map<String, dynamic>>> getTransactionsSummary({
    required ReportFilter filter,
    String? transactionType,
  });

  Future<Either<Failure, TransactionEntity>> getTransactionDetails(int transactionId);

  Future<Either<Failure, List<TransactionEntity>>> searchTransactions({
    required String query,
    ReportFilter? filter,
  });
}
