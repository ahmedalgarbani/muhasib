import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';

abstract class ReportsRepository {
  // Sales aggregates
  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesAggregatesByParty({
    required int invoiceType,
    required ReportFilter filter,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesAggregatesByProduct({
    required int invoiceType,
    required ReportFilter filter,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesAggregatesDaily({
    required int invoiceType,
    required ReportFilter filter,
  });

  // Purchase summary
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseSummaryTotals({
    required ReportFilter filter,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseTopSuppliers({
    required ReportFilter filter,
  });

  // Party balances
  Future<Either<Failure, List<Map<String, dynamic>>>> getPartyBalances({
    required int customerType,
    required ReportFilter filter,
  });

  // Journal
  Future<Either<Failure, List<Map<String, dynamic>>>> getJournalEntries({
    required ReportFilter filter,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getJournalEntryLines({
    required int journalEntryId,
  });

  // Invoices list
  Future<Either<Failure, List<Map<String, dynamic>>>> getInvoiceList({
    required ReportFilter filter,
    required List<int> invoiceTypes,
  });

  // General ledger
  Future<Either<Failure, List<Map<String, dynamic>>>> getGeneralLedgerSummary({
    required ReportFilter filter,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getGeneralLedgerDetails({
    required int accountId,
    required ReportFilter filter,
  });

  // Cash flow
  Future<Either<Failure, List<Map<String, dynamic>>>> getCashAccountIds();

  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlowOpeningBalance({
    required int startSeconds,
    required List<int> accountIds,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlowActualBalance({
    required int endSeconds,
    required List<int> accountIds,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlowGrouped({
    required int startSeconds,
    required int endSeconds,
    required List<int> accountIds,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlow({
    required ReportFilter filter,
  });

  // Balance sheet
  Future<Either<Failure, List<Map<String, dynamic>>>> getBalanceSheetAccounts({
    required int asOfSeconds,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getBalanceSheetNetIncome({
    required int asOfSeconds,
  });

  // Aged
  Future<Either<Failure, List<Map<String, dynamic>>>> getAgedReceivables({
    required ReportFilter filter,
    required int customerType,
    required List<int> invoiceTypes,
  });

  // Inventory extra
  Future<Either<Failure, List<Map<String, dynamic>>>> getStockMovements();

  Future<Either<Failure, List<Map<String, dynamic>>>> getCategoryMovs();

  Future<Either<Failure, List<Map<String, dynamic>>>> getLowStock();

  Future<Either<Failure, List<Map<String, dynamic>>>> getInventoryValuation();

  // Extra 3
  Future<Either<Failure, List<Map<String, dynamic>>>> getAccountTransactions({
    required int accountId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getCurrenciesForRevaluation();

  Future<Either<Failure, List<Map<String, dynamic>>>> getAccountsForRevaluation();

  Future<Either<Failure, List<Map<String, dynamic>>>> getAccountsForExchange();
}
