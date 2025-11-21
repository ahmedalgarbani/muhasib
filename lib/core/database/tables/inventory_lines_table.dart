import 'table_schema.dart';

class InventoryLinesTable implements TableSchema {
  @override
  String get tableName => 'inventory_lines';

  @override
  String get createTable => '''
    CREATE TABLE inventory_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      statement TEXT NOT NULL,
      quantity REAL NOT NULL,
      actual_quantity REAL NOT NULL,
      difference REAL NOT NULL DEFAULT 0.0,
      cost_amount REAL NULL,
      category_id INTEGER NULL REFERENCES categories (id),
      group_id INTEGER NOT NULL REFERENCES categories_groups (id),
      unit_id INTEGER NOT NULL REFERENCES categories_units (id),
      category_sub_unit_id INTEGER NOT NULL REFERENCES category_sub_units (id),
      inventory_id INTEGER NULL REFERENCES inventories (id) ON DELETE CASCADE
    );
  ''';

  @override
  List<String> get indexes => [];
}
