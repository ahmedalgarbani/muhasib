import 'table_schema.dart';

class PurchasePaymentsTable implements TableSchema {
  @override
  String get tableName => 'purchase_payments';

  @override
  String get createTable => '''
    CREATE TABLE purchase_payments (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL REFERENCES purchase_invoices(id) ON DELETE CASCADE,
      payment_method TEXT NOT NULL CHECK(payment_method IN ('cash', 'bank', 'deferred', 'cheque')),
      amount REAL NOT NULL,
      payment_date INTEGER NOT NULL,
      reference_number TEXT NULL,
      bank_name TEXT NULL,
      account_number TEXT NULL,
      cheque_number TEXT NULL,
      cheque_date INTEGER NULL,
      cash_box TEXT NULL,
      due_date INTEGER NULL,
      notes TEXT NULL,
      details TEXT NULL,
      status TEXT NULL DEFAULT 'completed' CHECK(status IN ('pending', 'completed', 'cancelled', 'returned')),
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_purchase_payments_invoice ON purchase_payments(invoice_id);',
    'CREATE INDEX idx_purchase_payments_date ON purchase_payments(payment_date);',
    'CREATE INDEX idx_purchase_payments_method ON purchase_payments(payment_method);',
  ];
}
