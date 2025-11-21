import 'table_schema.dart';

class CategoryMovsTable implements TableSchema {
  @override
  String get tableName => 'category_movs';

  @override
  String get createTable => '''
    CREATE TABLE category_movs (
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      doc_no INTEGER NOT NULL,
      trans_doc_type INTEGER NOT NULL,
      trans_in_out INTEGER NOT NULL DEFAULT 1 CHECK (trans_in_out IN (0, 1)),
      trans_date INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      category_id INTEGER NOT NULL REFERENCES categories (id),
      unit_id INTEGER NOT NULL REFERENCES categories_units (id),
      group_id INTEGER NOT NULL REFERENCES categories_groups (id),
      category_sub_unit_id INTEGER NOT NULL REFERENCES category_sub_units (id),
      stock_id INTEGER NOT NULL REFERENCES stocks (id),
      quantity REAL NULL,
      quantity_in REAL NOT NULL,
      quantity_out REAL NOT NULL,
      cost_amount REAL NULL,
      cost_local_amount REAL NULL,
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      sell_amount REAL NULL,
      sell_local_amount REAL NULL,
      refrenc_no TEXT NOT NULL,
      statement TEXT NOT NULL,
      reference_number TEXT NULL,
      u_no TEXT NULL,
      barcode_no TEXT NULL,
      expire_date INTEGER NULL,
      customer_id INTEGER NULL REFERENCES customers (id),
      PRIMARY KEY (doc_no, trans_doc_type, trans_in_out, category_id)
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_category_movs_date ON category_movs(trans_date);',
    'CREATE INDEX idx_category_movs_category ON category_movs(category_id);',
  ];
}
