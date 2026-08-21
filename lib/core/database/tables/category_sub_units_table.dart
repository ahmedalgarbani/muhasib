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
      packaging INTEGER NOT NULL CHECK(packaging > 0),
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      is_main_unit INTEGER NOT NULL DEFAULT 0 CHECK (is_main_unit IN (0, 1)),
      category_id INTEGER NULL REFERENCES categories (id) ON DELETE CASCADE,
      unit_id INTEGER NULL REFERENCES categories_units (id),
      conversion_rate REAL NOT NULL DEFAULT 1.0 CHECK(conversion_rate > 0),
      -- Multi-unit enhancement fields (008)
      barcode TEXT NULL,
      cost_price REAL NULL CHECK(cost_price IS NULL OR cost_price >= 0),
      sell_price REAL NULL CHECK(sell_price IS NULL OR sell_price >= 0),
      wholesale_price REAL NULL CHECK(wholesale_price IS NULL OR wholesale_price >= 0),
      is_default_sale INTEGER NOT NULL DEFAULT 0 CHECK(is_default_sale IN (0,1)),
      is_default_purchase INTEGER NOT NULL DEFAULT 0 CHECK(is_default_purchase IN (0,1))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_category_sub_units_barcode ON category_sub_units(barcode) WHERE barcode IS NOT NULL AND barcode != "";',
    'CREATE INDEX IF NOT EXISTS idx_category_sub_units_product ON category_sub_units(category_id);',
    'CREATE INDEX IF NOT EXISTS idx_category_sub_units_unit ON category_sub_units(unit_id);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_category_sub_units_unique_product_unit ON category_sub_units(category_id, unit_id) WHERE unit_id IS NOT NULL;',
  ];
}
