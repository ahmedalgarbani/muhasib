import 'table_schema.dart';

class PurchaseInvoiceItemsTable implements TableSchema {
  @override
  String get tableName => 'purchase_invoice_items';

  @override
  String get createTable => '''
    CREATE TABLE purchase_invoice_items (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL REFERENCES purchase_invoices(id) ON DELETE CASCADE,
      product_id INTEGER NOT NULL REFERENCES products(id),
      product_name TEXT NOT NULL,
      barcode TEXT NULL,
      description TEXT NULL,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      unit_price REAL NOT NULL,
      total_price REAL NOT NULL,
      discount_amount REAL NULL DEFAULT 0.0,
      discount_percent REAL NULL DEFAULT 0.0,
      tax_amount REAL NULL DEFAULT 0.0,
      tax_percent REAL NULL DEFAULT 0.0,
      expiry_date INTEGER NULL,
      batch_number TEXT NULL,
      serial_number TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_purchase_invoice_items_invoice ON purchase_invoice_items(invoice_id);',
    'CREATE INDEX idx_purchase_invoice_items_product ON purchase_invoice_items(product_id);',
  ];
}
