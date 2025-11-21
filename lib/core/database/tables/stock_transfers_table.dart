import 'table_schema.dart';

class StockTransfersTable implements TableSchema {
  @override
  String get tableName => 'stock_transfers';

  @override
  String get createTable => '''
    CREATE TABLE stock_transfers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number TEXT NOT NULL,
      date INTEGER NOT NULL,
      statement TEXT NOT NULL,
      parent_number TEXT NULL,
      parent_id INTEGER NULL,
      status INTEGER NOT NULL DEFAULT 0,
      from_stock_id INTEGER NULL REFERENCES stocks (id),
      to_stock_id INTEGER NULL REFERENCES stocks (id),
      u_no TEXT NULL,
      transfer_type INTEGER NOT NULL DEFAULT 0,
      total_value REAL NULL DEFAULT 0.0
    );
  ''';

  @override
  List<String> get indexes => [];
}
