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
      debt_limit_amount REAL NULL,
      local_debt_limit_amount REAL NULL,
      credit_limit_amount REAL NULL,
      local_credit_limit_amount REAL NULL,
      limit_currency_code TEXT NOT NULL,
      limit_exchange_rate REAL NULL,
      account_id INTEGER NULL REFERENCES accounts (id) ON DELETE CASCADE,
      currency_id INTEGER NULL REFERENCES currencies (id)
    );
  ''';

  @override
  List<String> get indexes => [];
}
