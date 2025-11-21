import 'table_schema.dart';

class CategorySubUnitsTable implements TableSchema {
  @override
  String get tableName => 'category_sub_units';

  @override
  String get createTable => '''
    CREATE TABLE category_sub_units (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      packaging INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      is_main_unit INTEGER NOT NULL DEFAULT 0 CHECK (is_main_unit IN (0, 1)),
      category_id INTEGER NULL REFERENCES categories (id) ON DELETE CASCADE,
      unit_id INTEGER NULL REFERENCES categories_units (id),
      conversion_rate REAL NOT NULL DEFAULT 1.0
    );
  ''';

  @override
  List<String> get indexes => [];
}
