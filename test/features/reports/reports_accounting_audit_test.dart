import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/database/database_initializer_io.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_limits_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/customers_table.dart';
import 'package:muhasib/core/database/tables/suppliers_table.dart';
import 'package:muhasib/core/database/tables/classifications_table.dart';
import 'package:muhasib/core/database/tables/banks_table.dart';
import 'package:muhasib/core/database/tables/stocks_table.dart';
import 'package:muhasib/core/database/tables/categories_table.dart';
import 'package:muhasib/core/database/tables/categories_groups_table.dart';
import 'package:muhasib/core/database/tables/categories_units_table.dart';
import 'package:muhasib/core/database/tables/category_sub_units_table.dart';
import 'package:muhasib/core/database/tables/invoices_table.dart';
import 'package:muhasib/core/database/tables/invoice_lines_table.dart';
import 'package:muhasib/core/database/tables/stock_movements_table.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/core/database/tables/settings_table.dart';
import 'package:muhasib/core/database/tables/taxes_table.dart';
import 'package:muhasib/core/database/tables/payment_methods_table.dart';
import 'package:muhasib/core/database/tables/unified_payments_table.dart';
import 'package:muhasib/core/database/tables/funds_table.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/database/seeders/settings_seeder.dart';
import 'package:muhasib/core/database/seeders/tax_seeder.dart';
import 'package:muhasib/core/database/seeders/currency_seeder.dart';
import 'package:muhasib/core/database/seeders/payment_methods_seeder.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/datasources/account_statement_datasource.dart';
import 'package:muhasib/features/reports/data/datasources/income_statement_datasource.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/reports/data/datasources/trial_balance_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/pages/balance_sheet_report_page.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_line_model.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';

class MockDatabaseService implements DatabaseService {
  final Database _db;
  MockDatabaseService(this._db);
  @override
  Future<Database> get database async => _db;
  @override
  Future<void> close() async => _db.close();
}

Future<Database> createReportsTestDatabase() async {
  initializeDatabaseFactory();
  final tables = <TableSchema>[
    CurrenciesTable(),
    SettingsTable(),
    TaxesTable(),
    PaymentMethodTypesTable(),
    PaymentMethodsTable(),
    AccountsTable(),
    AccountLimitsTable(),
    AccountConnectsTable(),
    JournalEntriesTable(),
    JournalEntryLinesTable(),
    CustomersTable(),
    SuppliersTable(),
    ClassificationsTable(),
    FundsTable(),
    BanksTable(),
    StocksTable(),
    CategoriesGroupsTable(),
    CategoriesUnitsTable(),
    CategoriesTable(),
    CategorySubUnitsTable(),
    InvoicesTable(),
    InvoiceLinesTable(),
    StockMovementsTable(),
    WarehouseStocksTable(),
  ];

  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = OFF');
    },
    onCreate: (db, version) async {
      for (final table in tables) {
        await db.execute(table.createTable);
        for (final index in table.indexes) {
          try {
            await db.execute(index);
          } catch (_) {}
        }
      }

      await SettingsSeeder.seed(db);
      await TaxSeeder.seed(db);
      await CurrencySeeder.seed(db);
      await PaymentMethodsSeeder.seed(db);
      await seedDefaultStocks(db);
      await seedDefaultCustomers(db);
      await seedDefaultAccounts(db);
      await seedDefaultAccountConnects(db);

      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.insert('categories', {
        'name': 'منتج تقارير',
        'statement': 'منتج',
        'barcode_no': 'REP-001',
        'stock_id': 1,
        'quantity': 100,
        'cost_amount': 50.0,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
      await db.insert('warehouse_stocks', {
        'product_id': 1,
        'warehouse_id': 1,
        'quantity': 100,
        'avg_cost': 50.0,
        'last_cost': 50.0,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
    },
  );

  return db;
}

void main() {
  group('Reports Data Integrity & Accounting Auditing Tests', () {
    late Database db;
    late DatabaseService dbService;

    setUp(() async {
      db = await createReportsTestDatabase();
      dbService = MockDatabaseService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Trial Balance: Debits and Credits are strictly balanced', () async {
      final invoiceDs = InvoiceLocalDataSourceImpl(database: db);

      // 1. Create a Sales Invoice of 1000
      final salesLine = InvoiceLineModel(
        id: null,
        invoiceId: 0,
        invoiceType: 1,
        categoryId: 1,
        groupId: 1,
        unitId: 1,
        categorySubUnitId: 1,
        stockId: 1,
        customerId: 1,
        date: 1700000000,
        invoiceTransType: 0, // Cash
        amount: 1000.0,
        totalAmount: 1000.0,
        discountAmt: 0.0,
        taxAmt: 150.0,
        netRevenueAmt: 1000.0,
        quantity: 10.0,
        price: 100.0,
        costPrice: 50.0,
        costTotal: 500.0,
      );

      final salesInvoice = InvoiceModel(
        id: null,
        number: 'INV-TEST-001',
        date: 1700000000,
        customerId: 1,
        stockId: 1,
        amount: 1000.0,
        discountAmt: 0.0,
        taxAmt: 150.0,
        taxRatio: 15.0,
        finalAmt: 1150.0,
        invoiceType: 1,
        invoiceTransType: 0,
        paymentStatus: 1,
        lines: [salesLine],
      );

      await invoiceDs.insertInvoice(salesInvoice);

      // 2. Query Trial Balance
      final trialBalanceDs = TrialBalanceDataSourceImpl(
        databaseService: dbService,
      );
      final filter = ReportFilter();
      final summary = await trialBalanceDs.getTrialBalanceSummary(
        filter: filter,
      );

      expect(summary.isClosingBalanced, isTrue);
      expect(summary.closingDebit, equals(summary.closingCredit));
      expect(summary.closingDebit, isPositive);
    });

    test(
      'Income Statement: Correctly categorizes Revenue, Cost of Sales, Gross Profit, and Net Income',
      () async {
        final invoiceDs = InvoiceLocalDataSourceImpl(database: db);

        // Create a Cash Sales Invoice (Sales: 2000, Tax: 300, Total: 2300, COGS: 1000)
        final salesLine = InvoiceLineModel(
          id: null,
          invoiceId: 0,
          invoiceType: 1,
          categoryId: 1,
          groupId: 1,
          unitId: 1,
          categorySubUnitId: 1,
          stockId: 1,
          customerId: 1,
          date: 1700000000,
          invoiceTransType: 0,
          amount: 2000.0,
          totalAmount: 2000.0,
          discountAmt: 0.0,
          taxAmt: 300.0,
          netRevenueAmt: 2000.0,
          quantity: 20.0,
          price: 100.0,
          costPrice: 50.0,
          costTotal: 1000.0,
        );

        final salesInvoice = InvoiceModel(
          id: null,
          number: 'INV-TEST-002',
          date: 1700000000,
          customerId: 1,
          stockId: 1,
          amount: 2000.0,
          discountAmt: 0.0,
          taxAmt: 300.0,
          taxRatio: 15.0,
          finalAmt: 2300.0,
          invoiceType: 1,
          invoiceTransType: 0,
          paymentStatus: 1,
          lines: [salesLine],
        );

        await invoiceDs.insertInvoice(salesInvoice);

        // Query Income Statement
        final isDs = IncomeStatementDataSourceImpl(databaseService: dbService);
        final filter = ReportFilter();
        final summary = await isDs.getIncomeStatementSummary(filter: filter);

        expect(summary.totalRevenue, equals(2000.0));
        expect(summary.grossProfit, greaterThanOrEqualTo(0));
        expect(
          summary.netIncome,
          equals(
            summary.grossProfit -
                summary.totalOperatingExpenses -
                summary.totalOtherExpenses -
                summary.taxExpense,
          ),
        );
      },
    );

    test(
      'Account Statement: Correctly computes Credit-normal balance for Supplier and Debit-normal for Customer',
      () async {
        final statementDs = AccountStatementDataSourceImpl(
          databaseService: dbService,
        );

        // Customer account (1120) - Debit normal
        final custSummary = await statementDs.getAccountStatementSummary(
          accountId: 3, // Customers account in seeded DB
          filter: ReportFilter(),
        );
        expect(custSummary.accountName, isNotEmpty);

        // Supplier account (2110) - Credit normal
        final suppSummary = await statementDs.getAccountStatementSummary(
          accountId: 4, // Suppliers account in seeded DB
          filter: ReportFilter(),
        );
        expect(suppSummary.accountName, isNotEmpty);
      },
    );

    test(
      'Balance Sheet: liability accounts appear under liabilities (not assets)',
      () async {
        final reportsDs = ReportsLocalDataSourceImpl(databaseService: dbService);

        // Pick one asset (type 0) and one liability (type 1) account.
        final assetRow = await db.query(
          'accounts',
          columns: ['id', 'code', 'name'],
          where: 'type = ? AND is_active = 1 AND is_master = 0 AND code LIKE ?',
          whereArgs: [0, '1%'],
          limit: 1,
        );
        final liabRow = await db.query(
          'accounts',
          columns: ['id', 'code', 'name'],
          where: 'type = ? AND is_active = 1 AND is_master = 0',
          whereArgs: [1],
          limit: 1,
        );
        expect(assetRow, isNotEmpty);
        expect(liabRow, isNotEmpty);
        final assetId = assetRow.first['id'] as int;
        final liabId = liabRow.first['id'] as int;

        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final jeId = await db.insert('journal_entries', {
          'entry_date': nowSec,
          'description': 'BS classification test',
          'reference_type': 'test',
          'status': 1,
          'is_posted': 1,
          'total_debit': 240.0,
          'total_credit': 240.0,
          'difference': 0.0,
          'creation_time': nowSec,
          'last_modification_time': nowSec,
        });
        await db.insert('journal_entry_lines', {
          'journal_entry_id': jeId,
          'account_id': assetId,
          'debit_amount': 240.0,
          'credit_amount': 0.0,
          'description': 'asset',
        });
        await db.insert('journal_entry_lines', {
          'journal_entry_id': jeId,
          'account_id': liabId,
          'debit_amount': 0.0,
          'credit_amount': 240.0,
          'description': 'liability',
        });

        final accounts = await reportsDs.getBalanceSheetAccounts(
          asOfSeconds: nowSec,
        );
        final niRows = await reportsDs.getBalanceSheetNetIncome(
          asOfSeconds: nowSec,
        );
        final ni = (niRows.first['ni'] as num).toDouble();
        final result = computeBalanceSheet(accounts, ni);

        expect(result.isBalanced, isTrue);

        final liabIds = <int>{
          ...result.currentLiabilities.map((e) => e.id),
          ...result.longTermLiabilities.map((e) => e.id),
        };
        final assetIds = <int>{
          ...result.currentAssets.map((e) => e.id),
          ...result.fixedAssets.map((e) => e.id),
          ...result.otherAssets.map((e) => e.id),
        };
        // The type-1 liability must NOT be swallowed into assets.
        expect(liabIds, contains(liabId));
        expect(assetIds, isNot(contains(liabId)));
        expect(result.totalLiabilities, closeTo(240.0, 0.01));
      },
    );

    test(
      'Balance Sheet: equation balances after a cash sales invoice',
      () async {
        final invoiceDs = InvoiceLocalDataSourceImpl(database: db);
        final reportsDs = ReportsLocalDataSourceImpl(databaseService: dbService);

        final salesLine = InvoiceLineModel(
          id: null,
          invoiceId: 0,
          invoiceType: 1,
          categoryId: 1,
          groupId: 1,
          unitId: 1,
          categorySubUnitId: 1,
          stockId: 1,
          customerId: 1,
          date: 1700000000,
          invoiceTransType: 0,
          amount: 240.0,
          totalAmount: 240.0,
          discountAmt: 0.0,
          taxAmt: 0.0,
          netRevenueAmt: 240.0,
          quantity: 1.0,
          price: 240.0,
          costPrice: 0.0,
          costTotal: 0.0,
        );

        final salesInvoice = InvoiceModel(
          id: null,
          number: 'INV-BS-001',
          date: 1700000000,
          customerId: 1,
          stockId: 1,
          amount: 240.0,
          discountAmt: 0.0,
          taxAmt: 0.0,
          taxRatio: 0.0,
          finalAmt: 240.0,
          invoiceType: 1,
          invoiceTransType: 0,
          paymentStatus: 1,
          lines: [salesLine],
        );

        await invoiceDs.insertInvoice(salesInvoice);

        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final accounts = await reportsDs.getBalanceSheetAccounts(
          asOfSeconds: nowSec,
        );
        final niRows = await reportsDs.getBalanceSheetNetIncome(
          asOfSeconds: nowSec,
        );
        final ni = (niRows.first['ni'] as num).toDouble();
        final result = computeBalanceSheet(accounts, ni);

        expect(result.isBalanced, isTrue);
      },
    );
  });
}
