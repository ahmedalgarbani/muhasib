import 'table_schema.dart';

class PurchaseInvoicesTable implements TableSchema {
  @override
  String get tableName => 'purchase_invoices';

  @override
  String get createTable => '''
    CREATE TABLE purchase_invoices (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT NOT NULL UNIQUE,
      supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
      invoice_date INTEGER NOT NULL,
      subtotal REAL NOT NULL DEFAULT 0.0,
      discount_amount REAL NULL DEFAULT 0.0,
      discount_percent REAL NULL DEFAULT 0.0,
      tax_amount REAL NULL DEFAULT 0.0,
      tax_percent REAL NULL DEFAULT 0.0,
      shipping_cost REAL NULL DEFAULT 0.0,
      other_charges REAL NULL DEFAULT 0.0,
      total_amount REAL NOT NULL,
      paid_amount REAL NOT NULL DEFAULT 0.0,
      remaining_amount REAL NOT NULL DEFAULT 0.0,
      payment_status INTEGER NOT NULL DEFAULT 0 CHECK(payment_status IN (0, 1, 2)),
      invoice_type INTEGER NOT NULL DEFAULT 0 CHECK(invoice_type IN (0, 1, 2)),
      parent_invoice_id INTEGER NULL REFERENCES purchase_invoices(id),
      parent_invoice_number TEXT NULL,
      notes TEXT NULL,
      warehouse TEXT NULL,
      currency TEXT NULL DEFAULT 'ريال سعودي',
      due_date INTEGER NULL,
      is_posted INTEGER NOT NULL DEFAULT 0 CHECK(is_posted IN (0, 1)),
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_purchase_invoices_supplier ON purchase_invoices(supplier_id);',
    'CREATE INDEX idx_purchase_invoices_date ON purchase_invoices(invoice_date);',
    'CREATE INDEX idx_purchase_invoices_number ON purchase_invoices(invoice_number);',
    'CREATE INDEX idx_purchase_invoices_status ON purchase_invoices(payment_status);',
  ];
}
