import 'table_schema.dart';

class PaymentsTable implements TableSchema {
  @override
  String get tableName => 'payments';

  @override
  String get createTable => '''
    CREATE TABLE payments (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL REFERENCES sales_invoices(id) ON DELETE CASCADE,
      payment_method TEXT NOT NULL CHECK(payment_method IN ('cash', 'bank', 'deferred', 'credit_card', 'cheque')),
      amount REAL NOT NULL,
      payment_date INTEGER NOT NULL,
      details TEXT NULL,
      reference_number TEXT NULL,
      bank_name TEXT NULL,
      cash_box TEXT NULL,
      due_date INTEGER NULL,
      status TEXT NULL DEFAULT 'completed' CHECK(status IN ('pending', 'completed', 'cancelled', 'refunded')),
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_payments_invoice ON payments(invoice_id);',
    'CREATE INDEX idx_payments_date ON payments(payment_date);',
    'CREATE INDEX idx_payments_method ON payments(payment_method);',
  ];
}
