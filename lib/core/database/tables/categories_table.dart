import 'table_schema.dart';

class CategoriesTable implements TableSchema {
  @override
  String get tableName => 'categories';

  @override
  String get createTable => '''
    CREATE TABLE categories (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      statement TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      cost_amount REAL NULL,
      cost_local_amount REAL NULL,
      cost_currency_code TEXT NULL,
      cost_exchange_rate REAL NULL,
      cost_currency_id INTEGER NULL REFERENCES currencies (id),
      group_id INTEGER NULL REFERENCES categories_groups (id),
      unit_id INTEGER NULL REFERENCES categories_units (id),
      sell_amount REAL NULL,
      sell_local_amount REAL NULL,
      sell_exchange_rate REAL NULL,
      quantity REAL NOT NULL DEFAULT 0.0,
      image_path TEXT NULL,
      barcode_no TEXT NOT NULL UNIQUE,
      expire_date INTEGER NULL,
      stock_id INTEGER NOT NULL REFERENCES stocks (id),
      u_no TEXT NULL,
      min_stock_level REAL NULL DEFAULT 0.0,
      max_stock_level REAL NULL,
      reorder_point REAL NULL,
      is_taxable INTEGER NOT NULL DEFAULT 1 CHECK (is_taxable IN (0, 1)),
      tax_id INTEGER NULL REFERENCES taxes (id)
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_categories_barcode ON categories(barcode_no);',
    'CREATE INDEX idx_categories_name ON categories(name);',
  ];
}
