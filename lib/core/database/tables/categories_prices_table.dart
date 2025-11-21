import 'table_schema.dart';

class CategoriesPricesTable implements TableSchema {
  @override
  String get tableName => 'categories_prices';

  @override
  String get createTable => '''
    CREATE TABLE categories_prices (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      bid_amount REAL NULL,
      bid_local_amount REAL NULL,
      bid_currency_code TEXT NULL,
      bid_exchange_rate REAL NULL,
      bid_currency_id INTEGER NULL REFERENCES currencies (id),
      category_sub_unit_id INTEGER NULL REFERENCES category_sub_units (id) ON DELETE CASCADE,
      price_level INTEGER NOT NULL DEFAULT 1,
      min_quantity REAL NULL DEFAULT 1.0
    );
  ''';

  @override
  List<String> get indexes => [];
}
