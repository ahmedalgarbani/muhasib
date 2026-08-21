import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsLocalDataSource _dataSource;

  ReportsRepositoryImpl({required ReportsLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesAggregatesByParty({
    required int invoiceType,
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getSalesAggregatesByParty(
        invoiceType: invoiceType,
        filter: filter,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل مبيعات حسب الجهة: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesAggregatesByProduct({
    required int invoiceType,
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getSalesAggregatesByProduct(
        invoiceType: invoiceType,
        filter: filter,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل مبيعات حسب المنتج: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesAggregatesDaily({
    required int invoiceType,
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getSalesAggregatesDaily(
        invoiceType: invoiceType,
        filter: filter,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل المبيعات اليومية: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseSummaryTotals({
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getPurchaseSummaryTotals(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل ملخص المشتريات: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseTopSuppliers({
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getPurchaseTopSuppliers(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل أكثر الموردين: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPartyBalances({
    required int customerType,
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getPartyBalances(
        customerType: customerType,
        filter: filter,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل أرصدة الجهات: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getJournalEntries({
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getJournalEntries(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل قيود اليومية: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getJournalEntryLines({
    required int journalEntryId,
  }) async {
    try {
      final result = await _dataSource.getJournalEntryLines(
        journalEntryId: journalEntryId,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل سطور القيد: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getInvoiceList({
    required ReportFilter filter,
    required List<int> invoiceTypes,
  }) async {
    try {
      final result = await _dataSource.getInvoiceList(
        filter: filter,
        invoiceTypes: invoiceTypes,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل قائمة الفواتير: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getGeneralLedgerSummary({
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getGeneralLedgerSummary(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل دفتر الأستاذ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getGeneralLedgerDetails({
    required int accountId,
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getGeneralLedgerDetails(
        accountId: accountId,
        filter: filter,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل تفاصيل الأستاذ: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCashAccountIds() async {
    try {
      final result = await _dataSource.getCashAccountIds();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل حسابات النقدية: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlowOpeningBalance({
    required int startSeconds,
    required List<int> accountIds,
  }) async {
    try {
      final result = await _dataSource.getCashFlowOpeningBalance(
        startSeconds: startSeconds,
        accountIds: accountIds,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل الرصيد الافتتاحي: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlowActualBalance({
    required int endSeconds,
    required List<int> accountIds,
  }) async {
    try {
      final result = await _dataSource.getCashFlowActualBalance(
        endSeconds: endSeconds,
        accountIds: accountIds,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل الرصيد الختامي: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlowGrouped({
    required int startSeconds,
    required int endSeconds,
    required List<int> accountIds,
  }) async {
    try {
      final result = await _dataSource.getCashFlowGrouped(
        startSeconds: startSeconds,
        endSeconds: endSeconds,
        accountIds: accountIds,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل التدفقات المجمعة: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCashFlow({
    required ReportFilter filter,
  }) async {
    try {
      final result = await _dataSource.getCashFlow(filter: filter);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل التدفقات النقدية: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getBalanceSheetAccounts({
    required int asOfSeconds,
  }) async {
    try {
      final result = await _dataSource.getBalanceSheetAccounts(asOfSeconds: asOfSeconds);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل حسابات الميزانية: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getBalanceSheetNetIncome({
    required int asOfSeconds,
  }) async {
    try {
      final result = await _dataSource.getBalanceSheetNetIncome(asOfSeconds: asOfSeconds);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل صافي الدخل: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAgedReceivables({
    required ReportFilter filter,
    required int customerType,
    required List<int> invoiceTypes,
  }) async {
    try {
      final result = await _dataSource.getAgedReceivables(
        filter: filter,
        customerType: customerType,
        invoiceTypes: invoiceTypes,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل أعمار الديون: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getStockMovements() async {
    try {
      final result = await _dataSource.getStockMovements();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل حركة المخزون: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategoryMovs() async {
    try {
      final result = await _dataSource.getCategoryMovs();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل category_movs: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getLowStock() async {
    try {
      final result = await _dataSource.getLowStock();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل نواقص المخزون: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getInventoryValuation() async {
    try {
      final result = await _dataSource.getInventoryValuation();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل تقييم المخزون: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAccountTransactions({
    required int accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await _dataSource.getAccountTransactions(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل حركات الحساب: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCurrenciesForRevaluation() async {
    try {
      final result = await _dataSource.getCurrenciesForRevaluation();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل العملات: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAccountsForRevaluation() async {
    try {
      final result = await _dataSource.getAccountsForRevaluation();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل حسابات إعادة التقييم: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAccountsForExchange() async {
    try {
      final result = await _dataSource.getAccountsForExchange();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(message: 'فشل تحميل حسابات الصرف: ${e.toString()}'));
    }
  }
}
