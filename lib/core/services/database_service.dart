import 'package:muhasib/core/database/database_config.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/database/seeders/settings_seeder.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/core/database/tables/app_users_table.dart';
import 'package:muhasib/core/database/tables/user_permissions_table.dart';
import 'package:muhasib/core/database/tables/user_data_permissions_table.dart';
import 'package:muhasib/core/database/tables/settings_table.dart';
import 'package:muhasib/core/database/tables/account_limits_table.dart';
import 'package:muhasib/core/database/tables/account_currencies_table.dart';
import 'package:muhasib/core/database/tables/account_limit_logs_table.dart';
import 'package:muhasib/core/database/tables/old_docs_table.dart';
import 'package:muhasib/core/database/tables/old_doc_lines_table.dart';
import 'package:muhasib/core/database/tables/vouchers_table.dart';
import 'package:muhasib/core/database/tables/voucher_lines_table.dart';
import 'package:muhasib/core/database/tables/opening_entries_table.dart';
import 'package:muhasib/core/database/tables/opening_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/currency_exchanges_table.dart';
import 'package:muhasib/core/database/tables/exchange_rate_differences_table.dart';
import 'package:muhasib/core/database/tables/exchange_rate_difference_lines_table.dart';
import 'package:muhasib/core/database/tables/currencies_histories_table.dart';
import 'package:muhasib/core/database/tables/cities_table.dart';
import 'package:muhasib/core/database/tables/classifications_table.dart';
import 'package:muhasib/core/database/tables/customers_table.dart';
import 'package:muhasib/core/database/tables/suppliers_table.dart';
import 'package:muhasib/core/database/tables/banks_table.dart';
import 'package:muhasib/core/database/tables/payment_methods_table.dart';
import 'package:muhasib/core/database/tables/credit_cards_table.dart';
import 'package:muhasib/core/database/tables/credit_card_payment_methods_table.dart';
import 'package:muhasib/core/database/tables/taxes_table.dart';
import 'package:muhasib/core/database/tables/other_tools_table.dart';
import 'package:muhasib/core/database/tables/stocks_table.dart';
import 'package:muhasib/core/database/tables/categories_groups_table.dart';
import 'package:muhasib/core/database/tables/categories_units_table.dart';
import 'package:muhasib/core/database/tables/categories_table.dart';
import 'package:muhasib/core/database/tables/category_sub_units_table.dart';
import 'package:muhasib/core/database/tables/categories_prices_table.dart';
import 'package:muhasib/core/database/tables/inventories_table.dart';
import 'package:muhasib/core/database/tables/inventory_lines_table.dart';
import 'package:muhasib/core/database/tables/stock_transfers_table.dart';
import 'package:muhasib/core/database/tables/stock_transfer_lines_table.dart';
import 'package:muhasib/core/database/tables/invoices_table.dart';
import 'package:muhasib/core/database/tables/invoice_lines_table.dart';
import 'package:muhasib/core/database/tables/category_movs_table.dart';
import 'package:muhasib/core/database/tables/funds_table.dart';
import 'package:muhasib/core/database/tables/daily_constraints_table.dart';
import 'package:muhasib/core/database/tables/daily_constraint_lines_table.dart';
import 'package:muhasib/core/database/tables/stock_settlements_table.dart';
import 'package:muhasib/core/database/tables/stock_settlement_lines_table.dart';
import 'package:muhasib/core/database/tables/search_histories_table.dart';
import 'package:muhasib/core/database/tables/audit_logs_table.dart';
import 'package:muhasib/core/database/tables/promotions_table.dart';
import 'package:muhasib/core/database/tables/promotion_categories_table.dart';
import 'package:muhasib/core/database/tables/loyalty_programs_table.dart';
import 'package:muhasib/core/database/tables/customer_points_table.dart';
import 'package:muhasib/core/database/tables/point_transactions_table.dart';
import 'package:muhasib/core/database/tables/price_history_table.dart';
import 'package:muhasib/core/database/tables/stock_alerts_table.dart';
import 'package:muhasib/core/database/tables/contact_methods_table.dart';
import 'package:muhasib/core/database/tables/system_sequences_table.dart';
import 'package:muhasib/core/database/tables/report_templates_table.dart';
import 'package:muhasib/core/database/tables/system_logs_table.dart';
import 'package:muhasib/core/database/tables/backup_history_table.dart';
import 'package:muhasib/core/database/tables/purchase_invoices_table.dart';
import 'package:muhasib/core/database/tables/purchase_invoice_items_table.dart';
import 'package:muhasib/core/database/tables/purchase_payments_table.dart';
import 'package:muhasib/core/database/tables/sales_invoices_table.dart';
import 'package:muhasib/core/database/tables/sales_invoice_items_table.dart';
import 'package:muhasib/core/database/tables/payments_table.dart';
import 'package:muhasib/core/database/tables/inventory_transactions_table.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

abstract class IDatabaseService {
  Future<Database> get database;
  Future<void> close();
}

class DatabaseService implements IDatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  Database? _db;

  @override
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final String path = join(dbPath, DatabaseConfig.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final table in _tables) {
      await db.execute(table.createTable);

      for (final index in table.indexes) {
        await db.execute(index);
      }
    }

    for (final seed in _seeders) {
      await seed(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final newTables = [JournalEntriesTable(), JournalEntryLinesTable()];

      for (final table in newTables) {
        await db.execute(table.createTable);
        for (final index in table.indexes) {
          await db.execute(index);
        }
      }
    }

    if (oldVersion < 3) {
      final newTables = [AccountLimitLogsTable()];

      for (final table in newTables) {
        await db.execute(table.createTable);
        for (final index in table.indexes) {
          await db.execute(index);
        }
      }
    }
  }

  final List<TableSchema> _tables = [
    // Core system
    CurrenciesTable(),
    AppUsersTable(),
    UserPermissionsTable(),
    UserDataPermissionsTable(),
    SettingsTable(),

    // Accounting
    AccountsTable(),
    AccountLimitsTable(),
    AccountLimitLogsTable(),
    AccountCurrenciesTable(),
    AccountConnectsTable(),

    // Legacy docs
    OldDocsTable(),
    OldDocLinesTable(),

    // Journal entries
    JournalEntriesTable(),
    JournalEntryLinesTable(),

    // Voucher system
    VouchersTable(),
    VoucherLinesTable(),

    // Opening entries
    OpeningEntriesTable(),
    OpeningEntryLinesTable(),

    // Currency exchange
    CurrencyExchangesTable(),
    ExchangeRateDifferencesTable(),
    ExchangeRateDifferenceLinesTable(),
    CurrenciesHistoriesTable(),

    // Customer management
    CitiesTable(),
    ClassificationsTable(),
    CustomersTable(),
    SuppliersTable(),

    // Banking & payment
    BanksTable(),
    PaymentMethodsTable(),
    CreditCardsTable(),
    CreditCardPaymentMethodsTable(),

    // Taxes & tools
    TaxesTable(),
    OtherToolsTable(),

    // Inventory & stock master
    StocksTable(),
    CategoriesGroupsTable(),
    CategoriesUnitsTable(),
    CategoriesTable(),
    CategorySubUnitsTable(),
    CategoriesPricesTable(),

    // Inventory operations
    InventoriesTable(),
    InventoryLinesTable(),
    StockTransfersTable(),
    StockTransferLinesTable(),

    // Sales & invoicing
    InvoicesTable(),
    InvoiceLinesTable(),
    SalesInvoicesTable(),
    SalesInvoiceItemsTable(),
    PaymentsTable(),
    
    // Purchases
    PurchaseInvoicesTable(),
    PurchaseInvoiceItemsTable(),
    PurchasePaymentsTable(),
    
    // Inventory
    InventoryTransactionsTable(),

    // Category movements
    CategoryMovsTable(),

    // Funds & daily constraints
    FundsTable(),
    DailyConstraintsTable(),
    DailyConstraintLinesTable(),

    // Stock settlements
    StockSettlementsTable(),
    StockSettlementLinesTable(),

    // Search & audit
    SearchHistoriesTable(),
    AuditLogsTable(),

    // Promotions & loyalty
    PromotionsTable(),
    PromotionCategoriesTable(),
    LoyaltyProgramsTable(),
    CustomerPointsTable(),
    PointTransactionsTable(),

    // Price management
    PriceHistoryTable(),
    StockAlertsTable(),

    // Contact & system
    ContactMethodsTable(),
    SystemSequencesTable(),
    ReportTemplatesTable(),
    SystemLogsTable(),
    BackupHistoryTable(),
  ];

  final List<Future<void> Function(Database)> _seeders = [
    SettingsSeeder.seed,
    seedDefaultStocks,
    seedDefaultCustomers,
    seedDefaultAccounts,
    // seedDefaultCurrency,
  ];

  @override
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}

/*
like this tree 

 */
