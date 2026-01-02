import 'table_schema.dart';

class InvoiceLinesTable implements TableSchema {
  @override
  String get tableName => 'invoice_lines';

  @override
  String get createTable => '''
    CREATE TABLE invoice_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      invoice_type INTEGER NOT NULL,
      amount REAL NOT NULL,
      total_amount REAL NOT NULL,
      tax_amt REAL NULL,
      tax_ratio INTEGER NULL,
      discount_amt REAL NULL,
      discount_ratio INTEGER NULL,
      other_fee_amt REAL NULL,
      other_fee_net_ratio INTEGER NULL,
      net_revenue_amt REAL NOT NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      quantity REAL NOT NULL,
      category_id INTEGER NULL REFERENCES categories (id),
      group_id INTEGER NOT NULL REFERENCES categories_groups (id),
      unit_id INTEGER NOT NULL REFERENCES categories_units (id),
      category_sub_unit_id INTEGER NOT NULL REFERENCES category_sub_units (id),
      stock_id INTEGER NOT NULL REFERENCES stocks (id),
      invoice_id INTEGER NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
      customer_id INTEGER NOT NULL REFERENCES customers (id),
      date INTEGER NOT NULL,
      expire_date INTEGER NULL,
      invoice_trans_type INTEGER NOT NULL DEFAULT 0,
      line_discount REAL NULL DEFAULT 0.0,
      
      -- Unit conversion tracking (for accurate inventory)
      base_quantity REAL NULL,
      conversion_rate REAL NULL DEFAULT 1.0,
      packaging INTEGER NULL DEFAULT 1,
      
      -- Cost tracking (for accurate COGS)
      cost_price REAL NULL,
      cost_total REAL NULL,
      
      -- Price tracking
      price REAL NULL,
      selling_price REAL NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_invoice_lines_invoice ON invoice_lines(invoice_id);',
    'CREATE INDEX idx_invoice_lines_category ON invoice_lines(category_id);',
    'CREATE INDEX idx_invoice_lines_stock ON invoice_lines(stock_id);',
  ];
}

