import 'table_schema.dart';

class CurrenciesHistoriesTable implements TableSchema {
  @override
  String get tableName => 'currencies_histories';

  @override
  String get createTable => '''
    CREATE TABLE currencies_histories (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      currency_id INTEGER NOT NULL REFERENCES currencies (id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      code TEXT NOT NULL,
      min_exchange_rate REAL NOT NULL,
      max_exchange_rate REAL NOT NULL,
      exchange_rate REAL NOT NULL,
      is_local_currency INTEGER NOT NULL DEFAULT 0 CHECK (is_local_currency IN (0, 1)),
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
    );
  ''';

  @override
  List<String> get indexes => [];
}
