import 'package:muhasib/core/database/database_config.dart';
import 'package:muhasib/core/database/seeders/default_seeders.dart';
import 'package:muhasib/core/database/seeders/settings_seeder.dart';
import 'package:muhasib/core/database/seeders/tax_seeder.dart';
import 'package:muhasib/core/database/seeders/currency_seeder.dart';
import 'package:muhasib/core/database/tables/number_sequences_table.dart';
import 'package:muhasib/core/database/tables/fiscal_periods_table.dart';
import 'package:muhasib/core/database/tables/currency_exchange_rates_table.dart';
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
import 'package:muhasib/core/database/tables/pos_held_orders_table.dart';
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
import 'package:muhasib/core/database/tables/regions_table.dart';
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
import 'package:muhasib/core/database/tables/invoice_payments_table.dart';
import 'package:muhasib/core/database/tables/discount_codes_table.dart';
import 'package:muhasib/core/database/tables/sales_commissions_table.dart';
import 'package:muhasib/core/database/tables/stock_movements_table.dart';
import 'package:muhasib/core/database/tables/unified_payments_table.dart';
import 'package:muhasib/core/database/seeders/payment_methods_seeder.dart';
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
      onOpen: (db) async {
        await _ensureEssentialTables(db);
      },
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _ensureEssentialTables(Database db) async {
    final essentialTables = [
      NumberSequencesTable(),
      FiscalPeriodsTable(),
      CurrencyExchangeRatesTable(),
      AuditLogsTable(),
    ];
    for (final table in essentialTables) {
      try {
        await db.execute(table.createTable);
      } catch (_) {}
      for (final index in table.indexes) {
        try {
          await db.execute(index);
        } catch (_) {}
      }
    }

    // Ensure audit_logs columns exist if table was created in older migration
    final auditCols = [
      'entity_type TEXT NULL',
      'entity_id INTEGER NULL',
      'action TEXT NULL',
      'created_at INTEGER NULL',
      'action_type TEXT NULL',
      'table_name TEXT NULL',
      'record_id INTEGER NULL',
    ];
    for (final col in auditCols) {
      try {
        await db.execute('ALTER TABLE audit_logs ADD COLUMN $col');
      } catch (_) {}
    }

    try {
      await seedDefaultNumberSequences(db);
    } catch (_) {}
    try {
      await seedDefaultFiscalPeriods(db);
    } catch (_) {}
    try {
      await seedDefaultFunds(db);
    } catch (_) {}
    try {
      await seedDefaultBanks(db);
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final table in _tables) {
      batch.execute(table.createTable);

      for (final index in table.indexes) {
        batch.execute(index);
      }
    }
    await batch.commit(noResult: true);

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

    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN quotation_status INTEGER NULL',
      );
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE invoices ADD COLUMN paid_amount REAL NULL');
    }
    if (oldVersion < 6) {
      // Create regions table
      final regionsTable = RegionsTable();
      await db.execute(regionsTable.createTable);
      for (final index in regionsTable.indexes) {
        await db.execute(index);
      }

      // Add region_id to cities table
      // Check if column exists first to avoid error if re-running
      try {
        await db.execute(
          'ALTER TABLE cities ADD COLUMN region_id INTEGER NULL REFERENCES regions (id)',
        );
      } catch (e) {
        // Column might already exist, ignore
      }
    }

    if (oldVersion < 7) {
      // Bank payment split for invoices (cash + bank + credit)
      try {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN bank_paid_amount REAL NULL',
        );
      } catch (e) {
        // Column might already exist, ignore
      }
    }

    if (oldVersion < 8) {
      // Fix supplier opening-balance sign (debit-normal convention).
      // Legacy code stored the opening balance with the opposite sign for
      // suppliers; flip only the opening component for accounts that have
      // a posted opening-balance journal entry.
      try {
        await db.rawUpdate('''
          UPDATE accounts
          SET balance = balance - 2 * COALESCE((
                SELECT current_balance FROM customers
                WHERE customers.account_id = accounts.id AND customers.type = 2
              ), 0),
              local_balance = local_balance - 2 * COALESCE((
                SELECT current_balance FROM customers
                WHERE customers.account_id = accounts.id AND customers.type = 2
              ), 0)
          WHERE id IN (SELECT account_id FROM customers WHERE type = 2)
            AND EXISTS (
              SELECT 1 FROM journal_entries
              WHERE reference_type = 'opening_balance' AND reference_id = accounts.id
            )
        ''');
        await db.rawUpdate('''
          UPDATE customers
          SET current_balance = -current_balance
          WHERE type = 2 AND account_id IS NOT NULL
            AND EXISTS (
              SELECT 1 FROM journal_entries
              WHERE reference_type = 'opening_balance' AND reference_id = customers.account_id
            )
        ''');
      } catch (e) {
        // Ignore migration errors (e.g. fresh databases)
      }
    }

    if (oldVersion < 9) {
      // Multi-unit enhancement (008) - ensure columns exist for existing DBs
      final upgrades = [
        "ALTER TABLE category_sub_units ADD COLUMN barcode TEXT NULL",
        "ALTER TABLE category_sub_units ADD COLUMN cost_price REAL NULL",
        "ALTER TABLE category_sub_units ADD COLUMN sell_price REAL NULL",
        "ALTER TABLE category_sub_units ADD COLUMN wholesale_price REAL NULL",
        "ALTER TABLE category_sub_units ADD COLUMN is_default_sale INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE category_sub_units ADD COLUMN is_default_purchase INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE stock_transfer_lines ADD COLUMN base_quantity REAL NULL",
        "ALTER TABLE stock_transfer_lines ADD COLUMN conversion_rate REAL NULL DEFAULT 1.0",
        "ALTER TABLE stock_transfer_lines ADD COLUMN packaging INTEGER NULL DEFAULT 1",
        "ALTER TABLE inventory_lines ADD COLUMN base_quantity REAL NULL",
        "ALTER TABLE inventory_lines ADD COLUMN conversion_rate REAL NULL DEFAULT 1.0",
        "ALTER TABLE inventory_lines ADD COLUMN packaging INTEGER NULL DEFAULT 1",
        "ALTER TABLE stock_movements ADD COLUMN unit_id INTEGER NULL REFERENCES categories_units(id)",
        "ALTER TABLE stock_movements ADD COLUMN conversion_rate REAL NULL DEFAULT 1.0",
        "ALTER TABLE stock_movements ADD COLUMN original_quantity REAL NULL",
        "ALTER TABLE stock_movements ADD COLUMN packaging INTEGER NULL DEFAULT 1",
      ];
      for (final sql in upgrades) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }
      final indexes = [
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_category_sub_units_barcode ON category_sub_units(barcode) WHERE barcode IS NOT NULL AND barcode != ''",
        "CREATE INDEX IF NOT EXISTS idx_category_sub_units_product ON category_sub_units(category_id)",
        "CREATE INDEX IF NOT EXISTS idx_category_sub_units_unit ON category_sub_units(unit_id)",
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_category_sub_units_unique_product_unit ON category_sub_units(category_id, unit_id) WHERE unit_id IS NOT NULL",
        "CREATE INDEX IF NOT EXISTS idx_stock_movements_unit ON stock_movements(unit_id)",
      ];
      for (final idx in indexes) {
        try {
          await db.execute(idx);
        } catch (_) {}
      }
      // Seed default sub-units for existing products (if none)
      try {
        await db.rawInsert('''
          INSERT OR IGNORE INTO category_sub_units (category_id, unit_id, packaging, conversion_rate, is_main_unit, is_active, is_default_sale, is_default_purchase, creation_time, last_modification_time)
          SELECT c.id, c.unit_id, 1, 1.0, 1, 1, 1, 1, CAST(strftime('%s','now') AS INTEGER), CAST(strftime('%s','now') AS INTEGER)
          FROM categories c WHERE c.unit_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM category_sub_units csu WHERE csu.category_id = c.id AND csu.is_main_unit = 1)
        ''');
      } catch (_) {}
    }
  }

  final List<TableSchema> _tables = [
    // Core system
    CurrenciesTable(),
    AppUsersTable(),
    UserPermissionsTable(),
    UserDataPermissionsTable(),
    SettingsTable(),
    PosHeldOrdersTable(),

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
    RegionsTable(),
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

    // Unified Payments System (replaces old payment tables)
    PaymentMethodTypesTable(),
    UnifiedPaymentsTable(),
    PaymentAllocationsTable(),

    // Legacy payment tables (kept for migration/compatibility)
    PaymentsTable(),
    InvoicePaymentsTable(),

    // Discount codes & coupons
    DiscountCodesTable(),
    DiscountCodeUsageTable(),

    // Sales agents & commissions
    SalesAgentsTable(),
    SalesCommissionsTable(),

    // Purchases
    PurchaseInvoicesTable(),
    PurchaseInvoiceItemsTable(),
    PurchasePaymentsTable(),

    // Inventory & Stock Movements
    InventoryTransactionsTable(),
    StockMovementsTable(),
    WarehouseStocksTable(),

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
    NumberSequencesTable(),
    FiscalPeriodsTable(),
    CurrencyExchangeRatesTable(),
    ReportTemplatesTable(),
    SystemLogsTable(),
    BackupHistoryTable(),
  ];

  final List<Future<void> Function(Database)> _seeders = [
    SettingsSeeder.seed,
    TaxSeeder.seed,
    CurrencySeeder.seed,
    PaymentMethodsSeeder.seed,
    seedDefaultStocks,
    seedDefaultCustomers,
    seedDefaultAccounts,
    seedDefaultFunds,
    seedDefaultBanks,
    seedDefaultNumberSequences,
    seedDefaultFiscalPeriods,
  ];

  @override
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
