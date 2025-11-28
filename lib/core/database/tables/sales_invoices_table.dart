import 'table_schema.dart';

class SalesInvoicesTable implements TableSchema {
  @override
  String get tableName => 'sales_invoices';

  @override
  String get createTable => '''
    CREATE TABLE sales_invoices (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT NOT NULL UNIQUE,
      customer_id INTEGER NULL REFERENCES customers(id),
      invoice_date INTEGER NOT NULL,
      subtotal REAL NOT NULL DEFAULT 0.0,
      discount_type TEXT NULL CHECK(discount_type IN ('amount', 'percent')),
      discount_value REAL NULL DEFAULT 0.0,
      discount_amount REAL NULL DEFAULT 0.0,
      other_charges REAL NULL DEFAULT 0.0,
      total_amount REAL NOT NULL,
      paid_amount REAL NOT NULL DEFAULT 0.0,
      remaining_amount REAL NOT NULL DEFAULT 0.0,
      payment_status INTEGER NOT NULL DEFAULT 0 CHECK(payment_status IN (0, 1, 2)),
      notes TEXT NULL,
      warehouse TEXT NULL,
      currency TEXT NULL DEFAULT 'ريال سعودي',
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_sales_invoices_customer ON sales_invoices(customer_id);',
    'CREATE INDEX idx_sales_invoices_date ON sales_invoices(invoice_date);',
    'CREATE INDEX idx_sales_invoices_number ON sales_invoices(invoice_number);',
  ];
}
