/// Centralized database configuration and schema constants.
class DatabaseConfig {
  DatabaseConfig._();

  /// Default database file name
  static const String databaseName = 'pos_system.db';

  /// Current database schema version
  static const int databaseVersion = 9;

  // ---------------------------------------------------------------------------
  // Core & Master Table Names
  // ---------------------------------------------------------------------------
  static const String tableCurrencies = 'currencies';
  static const String tableUsers = 'users';
  static const String tableAppUsers = 'app_users';
  static const String tableUserPermissions = 'user_permissions';
  static const String tableUserDataPermissions = 'user_data_permissions';
  static const String tableSettings = 'settings';

  // ---------------------------------------------------------------------------
  // Accounting Table Names
  // ---------------------------------------------------------------------------
  static const String tableAccounts = 'accounts';
  static const String tableAccountLimits = 'account_limits';
  static const String tableAccountLimitLogs = 'account_limit_logs';
  static const String tableAccountCurrencies = 'account_currencies';
  static const String tableAccountConnects = 'account_connects';
  static const String tableJournalEntries = 'journal_entries';
  static const String tableJournalEntryLines = 'journal_entry_lines';
  static const String tableVouchers = 'vouchers';
  static const String tableVoucherLines = 'voucher_lines';
  static const String tableFiscalPeriods = 'fiscal_periods';
  static const String tableNumberSequences = 'number_sequences';

  // ---------------------------------------------------------------------------
  // Sales, Purchases & Partners
  // ---------------------------------------------------------------------------
  static const String tableCustomers = 'customers';
  static const String tableSuppliers = 'suppliers';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceLines = 'invoice_lines';
  static const String tableSalesInvoices = 'sales_invoices';
  static const String tableSalesInvoiceItems = 'sales_invoice_items';
  static const String tablePurchaseInvoices = 'purchase_invoices';
  static const String tablePurchaseInvoiceItems = 'purchase_invoice_items';

  // ---------------------------------------------------------------------------
  // Inventory & Products
  // ---------------------------------------------------------------------------
  static const String tableProducts = 'products';
  static const String tableCategories = 'categories';
  static const String tableCategoryUnits = 'categories_units';
  static const String tableCategorySubUnits = 'category_sub_units';
  static const String tableCategoryGroups = 'categories_groups';
  static const String tableCategoryPrices = 'categories_prices';
  static const String tableStocks = 'stocks';
  static const String tableInventories = 'inventories';
  static const String tableInventoryLines = 'inventory_lines';
  static const String tableStockTransfers = 'stock_transfers';
  static const String tableStockTransferLines = 'stock_transfer_lines';
  static const String tableStockMovements = 'stock_movements';

  // ---------------------------------------------------------------------------
  // Common Column Names
  // ---------------------------------------------------------------------------
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnCreationTime = 'creation_time';
  static const String columnLastModificationTime = 'last_modification_time';
  static const String columnCreatorId = 'creator_id';
  static const String columnLastModifierId = 'last_modifier_id';
  static const String columnConcurrencyStamp = 'concurrency_stamp';
  static const String columnIsActive = 'is_active';
  static const String columnName = 'name';
  static const String columnCode = 'code';
}

