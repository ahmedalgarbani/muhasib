import 'table_schema.dart';

class SalesInvoiceItemsTable implements TableSchema {
  @override
  String get tableName => 'sales_invoice_items';

  @override
  String get createTable => '''
    CREATE TABLE sales_invoice_items (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL REFERENCES sales_invoices(id) ON DELETE CASCADE,
      product_id INTEGER NOT NULL REFERENCES products(id),
      product_name TEXT NOT NULL,
      barcode TEXT NULL,
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      total_price REAL NOT NULL,
      unit TEXT NULL,
      discount_amount REAL NULL DEFAULT 0.0,
      tax_amount REAL NULL DEFAULT 0.0
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_sales_invoice_items_invoice ON sales_invoice_items(invoice_id);',
    'CREATE INDEX idx_sales_invoice_items_product ON sales_invoice_items(product_id);',
  ];
}
