import 'table_schema.dart';

class InvoicesTable implements TableSchema {
  @override
  String get tableName => 'invoices';

  @override
  String get createTable => '''
    CREATE TABLE invoices (
      other_creator_id INTEGER NULL,
      other_id INTEGER NULL,
      other_number INTEGER NULL,
      other_creation_time INTEGER NULL,
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      invoice_type INTEGER NOT NULL,
      number TEXT NOT NULL,
      date INTEGER NOT NULL,
      statement TEXT NULL,
      amount REAL NOT NULL,
      total_amount REAL NULL,
      tax_amt REAL NULL,
      tax_ratio REAL NULL,
      discount_amt REAL NULL,
      discount_ratio REAL NULL,
      other_fee_amt REAL NULL,
      other_fee_net_ratio REAL NULL,
      net_revenue_amt REAL NULL,
      total_amount_after_discount REAL NULL,
      final_amt REAL NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      stock_id INTEGER NOT NULL REFERENCES stocks (id),
      customer_id INTEGER NOT NULL REFERENCES customers (id),
      tax_id INTEGER NULL REFERENCES taxes (id),
      other_fee_account_id INTEGER NULL REFERENCES accounts (id),
      invoice_trans_type INTEGER NOT NULL DEFAULT 0,
      parent_invoice_type INTEGER NULL,
      parent_invoice_id INTEGER NULL,
      parent_invoice_number TEXT NULL,
      next_invoice_type INTEGER NULL,
      next_invoice_id INTEGER NULL,
      next_invoice_number TEXT NULL,
      u_no TEXT NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      image_path TEXT NULL,
      payment_status INTEGER NOT NULL DEFAULT 0,
      shipping_address TEXT NULL,
      due_date INTEGER NULL,
      quotation_status INTEGER NULL,
      paid_amount REAL NULL,
      -- Amount paid in cash (for split payments: cash + credit)
      
      bank_paid_amount REAL NULL,
      -- Amount paid via bank (for split payments: cash + bank + credit)
      
      -- Quotation protection fields
      valid_until INTEGER NULL,
      -- Expiry date for quotations (timestamp)
      
      is_locked INTEGER NOT NULL DEFAULT 0,
      -- 1 = locked (cannot edit), 0 = editable
      
      locked_at INTEGER NULL,
      locked_by INTEGER NULL,
      locked_reason TEXT NULL,
      
      -- Approval workflow
      approval_status INTEGER NOT NULL DEFAULT 0,
      -- 0=draft, 1=pending_approval, 2=approved, 3=rejected, 4=expired
      
      approved_at INTEGER NULL,
      approved_by INTEGER NULL,
      approval_notes TEXT NULL,
      
      -- Versioning for audit trail
      version INTEGER NOT NULL DEFAULT 1,
      original_hash TEXT NULL
      -- Hash of original data to detect tampering
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_invoices_number ON invoices(number);',
    'CREATE UNIQUE INDEX idx_invoices_number_type_unique ON invoices(number, invoice_type);',
    'CREATE INDEX idx_invoices_date ON invoices(date);',
    'CREATE INDEX idx_invoices_customer ON invoices(customer_id);',
  ];
}
