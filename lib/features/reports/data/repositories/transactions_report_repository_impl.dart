import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/data/datasources/transactions_report_data_source.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/transaction_entity.dart';
import 'package:muhasib/features/reports/domain/repositories/transactions_report_repository.dart';

class TransactionsReportRepositoryImpl implements TransactionsReportRepository {
  final TransactionsReportDataSource _dataSource;

  TransactionsReportRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required ReportFilter filter,
    String? transactionType,
    String? sortBy,
    bool isAscending = false,
  }) async {
    try {
      final transactions = await _dataSource.getTransactions(
        filter: filter,
        transactionType: transactionType,
        sortBy: sortBy,
        isAscending: isAscending,
      );
      return Right(transactions);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTransactionsSummary({
    required ReportFilter filter,
    String? transactionType,
  }) async {
    try {
      final summary = await _dataSource.getTransactionsSummary(
        filter: filter,
        transactionType: transactionType,
      );
      return Right(summary);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionDetails(int transactionId) async {
    try {
      final transaction = await _dataSource.getTransactionDetails(transactionId);
      return Right(transaction);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> searchTransactions({
    required String query,
    ReportFilter? filter,
  }) async {
    try {
      final transactions = await _dataSource.searchTransactions(
        query: query,
        filter: filter,
      );
      return Right(transactions);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
