import 'table_schema.dart';

/// Table for sales agents/representatives
class SalesAgentsTable implements TableSchema {
  @override
  String get tableName => 'sales_agents';

  @override
  String get createTable => '''
    CREATE TABLE sales_agents (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- Agent details
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      phone TEXT NULL,
      email TEXT NULL,
      
      -- Commission settings
      commission_rate REAL NOT NULL DEFAULT 0.0,
      -- Default commission percentage
      commission_type INTEGER NOT NULL DEFAULT 0,
      -- 0=percentage of sales, 1=fixed per invoice
      
      -- Linked account for commission payables
      commission_account_id INTEGER NULL REFERENCES accounts (id),
      
      -- Status
      is_active INTEGER NOT NULL DEFAULT 1,
      
      -- Balance tracking
      current_balance REAL NOT NULL DEFAULT 0.0,
      -- Outstanding commissions owed to agent
      
      notes TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE UNIQUE INDEX idx_sales_agents_code ON sales_agents (code)',
    'CREATE INDEX idx_sales_agents_active ON sales_agents (is_active)',
  ];
}

/// Table for tracking sales commissions
class SalesCommissionsTable implements TableSchema {
  @override
  String get tableName => 'sales_commissions';

  @override
  String get createTable => '''
    CREATE TABLE sales_commissions (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- References
      invoice_id INTEGER NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
      sales_agent_id INTEGER NOT NULL REFERENCES sales_agents (id),
      
      -- Commission details
      invoice_amount REAL NOT NULL,
      commission_rate REAL NOT NULL,
      commission_amount REAL NOT NULL,
      
      -- Status: 0=pending, 1=approved, 2=paid, 3=cancelled
      status INTEGER NOT NULL DEFAULT 0,
      
      -- Payment info
      paid_date INTEGER NULL,
      payment_voucher_id INTEGER NULL REFERENCES vouchers (id),
      
      -- Journal entry for commission expense
      journal_entry_id INTEGER NULL REFERENCES journal_entries (id),
      
      notes TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_sales_commissions_invoice ON sales_commissions (invoice_id)',
    'CREATE INDEX idx_sales_commissions_agent ON sales_commissions (sales_agent_id)',
    'CREATE INDEX idx_sales_commissions_status ON sales_commissions (status)',
  ];
}
