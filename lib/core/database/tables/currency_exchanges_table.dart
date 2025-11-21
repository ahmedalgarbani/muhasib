import 'table_schema.dart';

class CurrencyExchangesTable implements TableSchema {
  @override
  String get tableName => 'currency_exchanges';

  @override
  String get createTable => '''
    CREATE TABLE currency_exchanges (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number INTEGER NOT NULL,
      credit_amount REAL NOT NULL,
      credit_local_amount REAL NOT NULL,
      credit_currency_code TEXT NOT NULL,
      credit_exchange_rate REAL NOT NULL,
      credit_currency_id INTEGER NOT NULL REFERENCES currencies (id),
      credit_account_id INTEGER NOT NULL REFERENCES accounts (id),
      debit_amount REAL NOT NULL,
      debit_local_amount REAL NOT NULL,
      debit_currency_code TEXT NOT NULL,
      debit_exchange_rate REAL NOT NULL,
      debit_currency_id INTEGER NOT NULL REFERENCES currencies (id),
      debit_account_id INTEGER NOT NULL REFERENCES accounts (id),
      date INTEGER NOT NULL,
      statement TEXT NOT NULL,
      parent_number TEXT NULL,
      parent_id INTEGER NULL,
      status INTEGER NOT NULL DEFAULT 0,
      u_no TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
