import 'table_schema.dart';

class AccountLimitsTable implements TableSchema {
  @override
  String get tableName => 'account_limits';

  @override
  String get createTable => '''
    CREATE TABLE account_limits (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      account_id INTEGER NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      debit_limit REAL NOT NULL DEFAULT 0.0,
      credit_limit REAL NOT NULL DEFAULT 0.0,
      current_debit REAL NOT NULL DEFAULT 0.0,
      current_credit REAL NOT NULL DEFAULT 0.0,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      UNIQUE(account_id, currency_id)
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_account_limits_account ON account_limits(account_id);',
    'CREATE INDEX idx_account_limits_currency ON account_limits(currency_id);',
    'CREATE INDEX idx_account_limits_active ON account_limits(is_active);',
  ];
}
