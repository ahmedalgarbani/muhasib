class DatabaseConfig {
  static const String databaseName = 'pos_system.db';
  static const int databaseVersion = 9;

  // Table names
  static const String tableCurrencies = 'currencies';
  static const String tableUsers = 'users';
  static const String tableAccounts = 'accounts';
  static const String tableCustomers = 'customers';
  static const String tableProducts = 'products';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceLines = 'invoice_lines';
  static const String tableJournalEntries = 'journal_entries';
  static const String tableJournalEntryLines = 'journal_entry_lines';

  // Common column names
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnIsActive = 'is_active';
  static const String columnCreatorId = 'creator_id';
  static const String columnName = 'name';
  static const String columnCode = 'code';
}
