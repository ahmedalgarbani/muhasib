import 'table_schema.dart';

class StockSettlementsTable implements TableSchema {
  @override
  String get tableName => 'stock_settlements';

  @override
  String get createTable => '''
    CREATE TABLE stock_settlements (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number TEXT NOT NULL,
      date INTEGER NOT NULL,
      type INTEGER NOT NULL,
      total_amount REAL NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      statement TEXT NOT NULL,
      parent_number TEXT NULL,
      parent_id INTEGER NULL,
      status INTEGER NOT NULL DEFAULT 0,
      stock_id INTEGER NULL REFERENCES stocks (id),
      u_no TEXT NULL,
      settlement_reason TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
