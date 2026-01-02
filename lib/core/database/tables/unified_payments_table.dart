import 'table_schema.dart';

/// Reference/Lookup table for payment method types
/// This is a master table to define available payment methods
class PaymentMethodTypesTable implements TableSchema {
  @override
  String get tableName => 'payment_method_types';

  @override
  String get createTable => '''
    CREATE TABLE payment_method_types (
      id INTEGER NOT NULL PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name_ar TEXT NOT NULL,
      name_en TEXT NOT NULL,
      
      -- Account linking
      default_account_id INTEGER NULL REFERENCES accounts (id),
      -- Default account for this payment type
      
      -- Configuration
      requires_bank INTEGER NOT NULL DEFAULT 0,
      requires_reference INTEGER NOT NULL DEFAULT 0,
      requires_due_date INTEGER NOT NULL DEFAULT 0,
      
      -- For accounting
      is_immediate INTEGER NOT NULL DEFAULT 1,
      -- 1 = immediate (cash, card), 0 = deferred (check, credit)
      
      -- Display
      icon TEXT NULL,
      color TEXT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      
      is_active INTEGER NOT NULL DEFAULT 1
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_payment_method_types_active ON payment_method_types (is_active)',
  ];
}

/// Unified payments table for all payment transactions
/// Supports: Invoices, Vouchers, Returns, and any future document types
class UnifiedPaymentsTable implements TableSchema {
  @override
  String get tableName => 'unified_payments';

  @override
  String get createTable => '''
    CREATE TABLE unified_payments (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- Unique payment number
      payment_number TEXT NOT NULL UNIQUE,
      
      -- Polymorphic reference to source document
      document_type TEXT NOT NULL,
      -- 'sales_invoice', 'purchase_invoice', 'sales_return', 'purchase_return', 
      -- 'voucher_receipt', 'voucher_payment', 'expense', 'refund'
      document_id INTEGER NOT NULL,
      document_number TEXT NULL,
      
      -- Payment type reference
      payment_method_type_id INTEGER NOT NULL REFERENCES payment_method_types (id),
      
      -- Party (customer/supplier)
      party_type TEXT NULL,
      -- 'customer', 'supplier', 'employee', 'other'
      party_id INTEGER NULL,
      party_name TEXT NULL,
      
      -- Payment details
      payment_date INTEGER NOT NULL,
      due_date INTEGER NULL,
      -- For checks and deferred payments
      
      -- Amounts
      amount REAL NOT NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      currency_code TEXT NULL,
      exchange_rate REAL NOT NULL DEFAULT 1.0,
      local_amount REAL NOT NULL,
      
      -- Account references
      from_account_id INTEGER NULL REFERENCES accounts (id),
      to_account_id INTEGER NULL REFERENCES accounts (id),
      
      -- Bank/Check details
      bank_id INTEGER NULL REFERENCES banks (id),
      bank_account_number TEXT NULL,
      check_number TEXT NULL,
      check_date INTEGER NULL,
      check_holder_name TEXT NULL,
      
      -- Card details
      card_type TEXT NULL,
      card_last_four TEXT NULL,
      transaction_reference TEXT NULL,
      authorization_code TEXT NULL,
      
      -- Transfer details
      transfer_reference TEXT NULL,
      sender_name TEXT NULL,
      receiver_name TEXT NULL,
      transfer_bank TEXT NULL,
      
      -- Commission/Fees
      commission_amount REAL NULL DEFAULT 0.0,
      commission_account_id INTEGER NULL REFERENCES accounts (id),
      
      -- Journal entry reference
      journal_entry_id INTEGER NULL REFERENCES journal_entries (id),
      
      -- Status tracking
      status INTEGER NOT NULL DEFAULT 1,
      -- 0=draft, 1=completed, 2=pending, 3=bounced, 4=cancelled, 5=refunded
      
      -- Reconciliation
      is_reconciled INTEGER NOT NULL DEFAULT 0,
      reconciled_date INTEGER NULL,
      reconciliation_reference TEXT NULL,
      
      -- Allocation tracking (for partial payments)
      allocated_amount REAL NOT NULL DEFAULT 0.0,
      unallocated_amount REAL NOT NULL DEFAULT 0.0,
      
      -- Notes and attachments
      notes TEXT NULL,
      attachment_path TEXT NULL,
      
      -- Soft delete
      is_deleted INTEGER NOT NULL DEFAULT 0,
      deleted_at INTEGER NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_unified_payments_document ON unified_payments (document_type, document_id)',
    'CREATE INDEX idx_unified_payments_party ON unified_payments (party_type, party_id)',
    'CREATE INDEX idx_unified_payments_date ON unified_payments (payment_date)',
    'CREATE INDEX idx_unified_payments_status ON unified_payments (status)',
    'CREATE INDEX idx_unified_payments_method ON unified_payments (payment_method_type_id)',
    'CREATE INDEX idx_unified_payments_bank ON unified_payments (bank_id) WHERE bank_id IS NOT NULL',
    'CREATE INDEX idx_unified_payments_check ON unified_payments (check_number) WHERE check_number IS NOT NULL',
    'CREATE INDEX idx_unified_payments_reconciled ON unified_payments (is_reconciled)',
    'CREATE INDEX idx_unified_payments_unallocated ON unified_payments (unallocated_amount) WHERE unallocated_amount > 0',
    
    // Triggers to calculate unallocated_amount (replacing GENERATED ALWAYS AS)
    'CREATE TRIGGER tr_unified_payments_insert_unallocated AFTER INSERT ON unified_payments BEGIN UPDATE unified_payments SET unallocated_amount = NEW.amount - NEW.allocated_amount WHERE id = NEW.id; END',
    'CREATE TRIGGER tr_unified_payments_update_unallocated AFTER UPDATE OF amount, allocated_amount ON unified_payments BEGIN UPDATE unified_payments SET unallocated_amount = NEW.amount - NEW.allocated_amount WHERE id = NEW.id; END',
  ];
}

/// Table for allocating payments to specific invoices/documents
/// Supports partial payments and payment splitting
class PaymentAllocationsTable implements TableSchema {
  @override
  String get tableName => 'payment_allocations';

  @override
  String get createTable => '''
    CREATE TABLE payment_allocations (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- Payment reference
      payment_id INTEGER NOT NULL REFERENCES unified_payments (id) ON DELETE CASCADE,
      
      -- Target document
      target_document_type TEXT NOT NULL,
      target_document_id INTEGER NOT NULL,
      target_document_number TEXT NULL,
      
      -- Allocation amount
      allocated_amount REAL NOT NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      exchange_rate REAL NOT NULL DEFAULT 1.0,
      local_amount REAL NOT NULL,
      
      -- Discount applied during allocation
      discount_amount REAL NOT NULL DEFAULT 0.0,
      discount_account_id INTEGER NULL REFERENCES accounts (id),
      
      -- Write-off for small differences
      write_off_amount REAL NOT NULL DEFAULT 0.0,
      write_off_account_id INTEGER NULL REFERENCES accounts (id),
      
      -- Exchange gain/loss for foreign currency
      exchange_difference REAL NOT NULL DEFAULT 0.0,
      exchange_account_id INTEGER NULL REFERENCES accounts (id),
      
      -- Journal entry for this allocation
      journal_entry_id INTEGER NULL REFERENCES journal_entries (id),
      
      notes TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_payment_allocations_payment ON payment_allocations (payment_id)',
    'CREATE INDEX idx_payment_allocations_target ON payment_allocations (target_document_type, target_document_id)',
  ];
}

/// Payment status enum
class PaymentStatus {
  static const int draft = 0;
  static const int completed = 1;
  static const int pending = 2;
  static const int bounced = 3;
  static const int cancelled = 4;
  static const int refunded = 5;
  
  static String getName(int status) {
    switch (status) {
      case draft: return 'مسودة';
      case completed: return 'مكتمل';
      case pending: return 'قيد الانتظار';
      case bounced: return 'مرتجع';
      case cancelled: return 'ملغي';
      case refunded: return 'مسترد';
      default: return 'غير محدد';
    }
  }
}

/// Document types for payments
class PaymentDocumentType {
  static const String salesInvoice = 'sales_invoice';
  static const String purchaseInvoice = 'purchase_invoice';
  static const String salesReturn = 'sales_return';
  static const String purchaseReturn = 'purchase_return';
  static const String receiptVoucher = 'receipt_voucher';
  static const String paymentVoucher = 'payment_voucher';
  static const String expense = 'expense';
  static const String refund = 'refund';
  static const String advancePayment = 'advance_payment';
  static const String openingBalance = 'opening_balance';
}

/// Party types
class PartyType {
  static const String customer = 'customer';
  static const String supplier = 'supplier';
  static const String employee = 'employee';
  static const String other = 'other';
}
