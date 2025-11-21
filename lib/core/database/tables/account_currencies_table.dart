import 'table_schema.dart';

class AccountCurrenciesTable implements TableSchema {
  @override
  String get tableName => 'account_currencies';

  @override
  String get createTable => '''
    CREATE TABLE account_currencies (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      account_id INTEGER NULL REFERENCES accounts (id) ON DELETE CASCADE,
      currency_id INTEGER NULL REFERENCES currencies (id) ON DELETE CASCADE,
      statement TEXT NULL,
      UNIQUE(account_id, currency_id)
    );
  ''';

  @override
  List<String> get indexes => [];
}
