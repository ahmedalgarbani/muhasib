import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecases/usecase.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/repositories/reports_repository.dart';

/// Generic use case that delegates to [ReportsRepository] based on [GetReportDataParams.reportKey].
/// At least one generic `GetReportData` as required by task.
class GetReportData implements UseCase<List<Map<String, dynamic>>, GetReportDataParams> {
  final ReportsRepository repository;

  GetReportData(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required GetReportDataParams params,
  }) async {
    switch (params.reportKey) {
      case ReportKeys.salesAggregatesByParty:
        return repository.getSalesAggregatesByParty(
          invoiceType: params.invoiceType!,
          filter: params.filter,
        );
      case ReportKeys.salesAggregatesByProduct:
        return repository.getSalesAggregatesByProduct(
          invoiceType: params.invoiceType!,
          filter: params.filter,
        );
      case ReportKeys.salesAggregatesDaily:
        return repository.getSalesAggregatesDaily(
          invoiceType: params.invoiceType!,
          filter: params.filter,
        );
      case ReportKeys.purchaseSummaryTotals:
        return repository.getPurchaseSummaryTotals(filter: params.filter);
      case ReportKeys.purchaseTopSuppliers:
        return repository.getPurchaseTopSuppliers(filter: params.filter);
      case ReportKeys.partyBalances:
        return repository.getPartyBalances(
          customerType: params.customerType!,
          filter: params.filter,
        );
      case ReportKeys.journalEntries:
        return repository.getJournalEntries(filter: params.filter);
      case ReportKeys.journalEntryLines:
        return repository.getJournalEntryLines(
          journalEntryId: params.journalEntryId!,
        );
      case ReportKeys.invoiceList:
        return repository.getInvoiceList(
          filter: params.filter,
          invoiceTypes: params.invoiceTypes ?? const [],
        );
      case ReportKeys.generalLedgerSummary:
        return repository.getGeneralLedgerSummary(filter: params.filter);
      case ReportKeys.generalLedgerDetails:
        return repository.getGeneralLedgerDetails(
          accountId: params.accountId!,
          filter: params.filter,
        );
      case ReportKeys.cashFlow:
        return repository.getCashFlow(filter: params.filter);
      case ReportKeys.cashFlowGrouped:
        return repository.getCashFlowGrouped(
          startSeconds: params.startSeconds!,
          endSeconds: params.endSeconds!,
          accountIds: params.accountIds!,
        );
      case ReportKeys.balanceSheetAccounts:
        return repository.getBalanceSheetAccounts(asOfSeconds: params.asOfSeconds!);
      case ReportKeys.balanceSheetNetIncome:
        return repository.getBalanceSheetNetIncome(asOfSeconds: params.asOfSeconds!);
      case ReportKeys.agedReceivables:
        return repository.getAgedReceivables(
          filter: params.filter,
          customerType: params.customerType!,
          invoiceTypes: params.invoiceTypes ?? const [],
        );
      case ReportKeys.stockMovements:
        return repository.getStockMovements();
      case ReportKeys.categoryMovs:
        return repository.getCategoryMovs();
      case ReportKeys.lowStock:
        return repository.getLowStock();
      case ReportKeys.inventoryValuation:
        return repository.getInventoryValuation();
      case ReportKeys.accountTransactions:
        return repository.getAccountTransactions(
          accountId: params.accountId!,
          startDate: params.startDate,
          endDate: params.endDate,
        );
      case ReportKeys.currenciesForRevaluation:
        return repository.getCurrenciesForRevaluation();
      case ReportKeys.accountsForRevaluation:
        return repository.getAccountsForRevaluation();
      case ReportKeys.accountsForExchange:
        return repository.getAccountsForExchange();
      default:
        return Left(ValidationFailure(message: 'Unknown reportKey: ${params.reportKey}'));
    }
  }
}

/// Keys for generic report dispatcher.
class ReportKeys {
  static const salesAggregatesByParty = 'salesAggregatesByParty';
  static const salesAggregatesByProduct = 'salesAggregatesByProduct';
  static const salesAggregatesDaily = 'salesAggregatesDaily';
  static const purchaseSummaryTotals = 'purchaseSummaryTotals';
  static const purchaseTopSuppliers = 'purchaseTopSuppliers';
  static const partyBalances = 'partyBalances';
  static const journalEntries = 'journalEntries';
  static const journalEntryLines = 'journalEntryLines';
  static const invoiceList = 'invoiceList';
  static const generalLedgerSummary = 'generalLedgerSummary';
  static const generalLedgerDetails = 'generalLedgerDetails';
  static const cashFlow = 'cashFlow';
  static const cashFlowGrouped = 'cashFlowGrouped';
  static const balanceSheetAccounts = 'balanceSheetAccounts';
  static const balanceSheetNetIncome = 'balanceSheetNetIncome';
  static const agedReceivables = 'agedReceivables';
  static const stockMovements = 'stockMovements';
  static const categoryMovs = 'categoryMovs';
  static const lowStock = 'lowStock';
  static const inventoryValuation = 'inventoryValuation';
  static const accountTransactions = 'accountTransactions';
  static const currenciesForRevaluation = 'currenciesForRevaluation';
  static const accountsForRevaluation = 'accountsForRevaluation';
  static const accountsForExchange = 'accountsForExchange';
}

class GetReportDataParams extends Equatable {
  final String reportKey;
  final ReportFilter filter;
  final int? invoiceType;
  final int? customerType;
  final List<int>? invoiceTypes;
  final int? accountId;
  final int? journalEntryId;
  final int? asOfSeconds;
  final int? startSeconds;
  final int? endSeconds;
  final List<int>? accountIds;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetReportDataParams({
    required this.reportKey,
    this.filter = const ReportFilter(),
    this.invoiceType,
    this.customerType,
    this.invoiceTypes,
    this.accountId,
    this.journalEntryId,
    this.asOfSeconds,
    this.startSeconds,
    this.endSeconds,
    this.accountIds,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        reportKey,
        filter,
        invoiceType,
        customerType,
        invoiceTypes,
        accountId,
        journalEntryId,
        asOfSeconds,
        startSeconds,
        endSeconds,
        accountIds,
        startDate,
        endDate,
      ];
}

// ──────────────────────────────────────────────────────────
// Specific use cases (examples) — at least one specific as per task
// ──────────────────────────────────────────────────────────

class GetSalesAggregatesUseCase implements UseCase<List<Map<String, dynamic>>, GetSalesAggregatesParams> {
  final ReportsRepository repository;
  GetSalesAggregatesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required GetSalesAggregatesParams params,
  }) {
    switch (params.variant) {
      case SalesAggregateVariant.byParty:
        return repository.getSalesAggregatesByParty(
          invoiceType: params.invoiceType,
          filter: params.filter,
        );
      case SalesAggregateVariant.byProduct:
        return repository.getSalesAggregatesByProduct(
          invoiceType: params.invoiceType,
          filter: params.filter,
        );
      case SalesAggregateVariant.daily:
        return repository.getSalesAggregatesDaily(
          invoiceType: params.invoiceType,
          filter: params.filter,
        );
    }
  }
}

enum SalesAggregateVariant { byParty, byProduct, daily }

class GetSalesAggregatesParams extends Equatable {
  final int invoiceType;
  final ReportFilter filter;
  final SalesAggregateVariant variant;

  const GetSalesAggregatesParams({
    required this.invoiceType,
    required this.filter,
    required this.variant,
  });

  @override
  List<Object?> get props => [invoiceType, filter, variant];
}

class GetPurchaseSummaryUseCase implements UseCase<List<Map<String, dynamic>>, ReportFilter> {
  final ReportsRepository repository;
  GetPurchaseSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required ReportFilter params,
  }) {
    return repository.getPurchaseSummaryTotals(filter: params);
  }
}

class GetPartyBalancesUseCase implements UseCase<List<Map<String, dynamic>>, GetPartyBalancesParams> {
  final ReportsRepository repository;
  GetPartyBalancesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required GetPartyBalancesParams params,
  }) {
    return repository.getPartyBalances(
      customerType: params.customerType,
      filter: params.filter,
    );
  }
}

class GetPartyBalancesParams extends Equatable {
  final int customerType;
  final ReportFilter filter;
  const GetPartyBalancesParams({required this.customerType, required this.filter});
  @override
  List<Object?> get props => [customerType, filter];
}

class GetJournalEntriesUseCase implements UseCase<List<Map<String, dynamic>>, ReportFilter> {
  final ReportsRepository repository;
  GetJournalEntriesUseCase(this.repository);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call({required ReportFilter params}) {
    return repository.getJournalEntries(filter: params);
  }
}

class GetGeneralLedgerUseCase implements UseCase<List<Map<String, dynamic>>, GetGeneralLedgerParams> {
  final ReportsRepository repository;
  GetGeneralLedgerUseCase(this.repository);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call({required GetGeneralLedgerParams params}) {
    if (params.accountId == null) {
      return repository.getGeneralLedgerSummary(filter: params.filter);
    }
    return repository.getGeneralLedgerDetails(accountId: params.accountId!, filter: params.filter);
  }
}

class GetGeneralLedgerParams extends Equatable {
  final ReportFilter filter;
  final int? accountId;
  const GetGeneralLedgerParams({required this.filter, this.accountId});
  @override
  List<Object?> get props => [filter, accountId];
}

class GetAgedReceivablesUseCase implements UseCase<List<Map<String, dynamic>>, GetAgedReceivablesParams> {
  final ReportsRepository repository;
  GetAgedReceivablesUseCase(this.repository);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call({required GetAgedReceivablesParams params}) {
    return repository.getAgedReceivables(
      filter: params.filter,
      customerType: params.customerType,
      invoiceTypes: params.invoiceTypes,
    );
  }
}

class GetAgedReceivablesParams extends Equatable {
  final ReportFilter filter;
  final int customerType;
  final List<int> invoiceTypes;
  const GetAgedReceivablesParams({
    required this.filter,
    required this.customerType,
    required this.invoiceTypes,
  });
  @override
  List<Object?> get props => [filter, customerType, invoiceTypes];
}
