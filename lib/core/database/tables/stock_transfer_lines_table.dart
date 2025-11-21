import 'table_schema.dart';

class StockTransferLinesTable implements TableSchema {
  @override
  String get tableName => 'stock_transfer_lines';

  @override
  String get createTable => '''
    CREATE TABLE stock_transfer_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      quantity REAL NOT NULL,
      statement TEXT NOT NULL,
      cost_amount REAL NULL,
      category_id INTEGER NULL REFERENCES categories (id),
      group_id INTEGER NOT NULL REFERENCES categories_groups (id),
      unit_id INTEGER NOT NULL REFERENCES categories_units (id),
      category_sub_unit_id INTEGER NOT NULL REFERENCES category_sub_units (id),
      stock_transfer_id INTEGER NULL REFERENCES stock_transfers (id) ON DELETE CASCADE
    );
  ''';

  @override
  List<String> get indexes => [];
}
