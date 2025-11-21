import 'table_schema.dart';

class InventoriesTable implements TableSchema {
  @override
  String get tableName => 'inventories';

  @override
  String get createTable => '''
    CREATE TABLE inventories (
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
      stock_id INTEGER NULL REFERENCES stocks (id),
      inventory_type INTEGER NOT NULL DEFAULT 0,
      total_difference REAL NULL DEFAULT 0.0,
      total_value REAL NULL DEFAULT 0.0
    );
  ''';

  @override
  List<String> get indexes => [];
}
