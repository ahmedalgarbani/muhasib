import 'table_schema.dart';

/// Table for discount codes/coupons system
class DiscountCodesTable implements TableSchema {
  @override
  String get tableName => 'discount_codes';

  @override
  String get createTable => '''
    CREATE TABLE discount_codes (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- Code details
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      description TEXT NULL,
      
      -- Discount type: 0=percentage, 1=fixed_amount
      discount_type INTEGER NOT NULL DEFAULT 0,
      discount_value REAL NOT NULL,
      
      -- Maximum discount (for percentage type)
      max_discount_amount REAL NULL,
      
      -- Minimum order amount to apply
      min_order_amount REAL NULL DEFAULT 0,
      
      -- Usage limits
      max_uses INTEGER NULL,
      max_uses_per_customer INTEGER NULL DEFAULT 1,
      current_uses INTEGER NOT NULL DEFAULT 0,
      
      -- Validity dates
      valid_from INTEGER NULL,
      valid_to INTEGER NULL,
      
      -- Restrictions
      customer_id INTEGER NULL REFERENCES customers (id),
      -- If set, only this customer can use
      product_group_id INTEGER NULL REFERENCES product_groups (id),
      -- If set, only applies to products from this group
      
      -- Status: 0=inactive, 1=active, 2=expired
      status INTEGER NOT NULL DEFAULT 1,
      
      -- Account for discount tracking
      discount_account_id INTEGER NULL REFERENCES accounts (id)
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE UNIQUE INDEX idx_discount_codes_code ON discount_codes (code)',
    'CREATE INDEX idx_discount_codes_status ON discount_codes (status)',
    'CREATE INDEX idx_discount_codes_validity ON discount_codes (valid_from, valid_to)',
  ];
}

/// Table for tracking discount code usage
class DiscountCodeUsageTable implements TableSchema {
  @override
  String get tableName => 'discount_code_usage';

  @override
  String get createTable => '''
    CREATE TABLE discount_code_usage (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      discount_code_id INTEGER NOT NULL REFERENCES discount_codes (id),
      invoice_id INTEGER NOT NULL REFERENCES invoices (id),
      customer_id INTEGER NULL REFERENCES customers (id),
      
      discount_amount REAL NOT NULL,
      used_at INTEGER NOT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_discount_usage_code ON discount_code_usage (discount_code_id)',
    'CREATE INDEX idx_discount_usage_invoice ON discount_code_usage (invoice_id)',
    'CREATE INDEX idx_discount_usage_customer ON discount_code_usage (customer_id)',
  ];
}
