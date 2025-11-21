import 'table_schema.dart';

class StockSettlementLinesTable implements TableSchema {
  @override
  String get tableName => 'stock_settlement_lines';

  @override
  String get createTable => '''
    CREATE TABLE stock_settlement_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      category_id INTEGER NOT NULL REFERENCES categories (id),
      group_id INTEGER NOT NULL REFERENCES categories_groups (id),
      unit_id INTEGER NOT NULL REFERENCES categories_units (id),
      category_sub_unit_id INTEGER NOT NULL REFERENCES category_sub_units (id),
      quantity REAL NOT NULL,
      statement TEXT NOT NULL,
      amount REAL NOT NULL,
      total_amount REAL NOT NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      stock_id INTEGER NOT NULL REFERENCES stocks (id),
      stock_settlement_id INTEGER NULL REFERENCES stock_settlements (id) ON DELETE CASCADE,
      expire_date INTEGER NULL,
      reason TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
