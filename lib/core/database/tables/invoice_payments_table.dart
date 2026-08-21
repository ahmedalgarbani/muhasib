import 'package:muhasib/core/enums/payment_method.dart' as core_payment;
import 'table_schema.dart';

/// Table for tracking multiple payment methods per invoice
/// Supports: Cash, Bank Transfer, Credit (Accounts Receivable), and combinations
class InvoicePaymentsTable implements TableSchema {
  @override
  String get tableName => 'invoice_payments';

  @override
  String get createTable => '''
    CREATE TABLE invoice_payments (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- Invoice reference
      invoice_id INTEGER NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
      
      -- Payment details
      payment_number INTEGER NOT NULL DEFAULT 1,
      payment_date INTEGER NOT NULL,
      payment_method INTEGER NOT NULL DEFAULT 0,
      -- payment_method: 0=Cash, 1=Credit(A/R), 2=Bank Transfer, 3=Check, 4=Card
      
      -- Amounts
      amount REAL NOT NULL,
      local_amount REAL NOT NULL,
      
      -- Currency
      currency_id INTEGER NULL REFERENCES currencies (id),
      currency_code TEXT NULL,
      exchange_rate REAL NOT NULL DEFAULT 1.0,
      
      -- Account references
      payment_account_id INTEGER NULL REFERENCES accounts (id),
      -- For cash: cashbox account, for bank: bank account, for credit: customer account
      
      -- Additional info
      bank_id INTEGER NULL REFERENCES banks (id),
      check_number TEXT NULL,
      check_date INTEGER NULL,
      card_transaction_ref TEXT NULL,
      
      -- Journal entry reference
      journal_entry_id INTEGER NULL REFERENCES journal_entries (id),
      
      -- Status: 0=pending, 1=completed, 2=bounced, 3=cancelled
      status INTEGER NOT NULL DEFAULT 1,
      notes TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_invoice_payments_invoice_id ON invoice_payments (invoice_id)',
    'CREATE INDEX idx_invoice_payments_date ON invoice_payments (payment_date)',
    'CREATE INDEX idx_invoice_payments_method ON invoice_payments (payment_method)',
  ];
}

/// @Deprecated — use [core_payment.PaymentMethod] from lib/core/enums/payment_method.dart
/// Kept for backward compatibility — delegates to central enum.
class PaymentMethod {
  static const int cash = 0;
  static const int credit = 1;      // Accounts Receivable
  static const int bankTransfer = 2;
  static const int check = 3;
  static const int card = 4;
  
  static String getName(int method) =>
      core_payment.PaymentMethod.tryFromValue(method)?.labelAr ?? 'غير محدد';
}
