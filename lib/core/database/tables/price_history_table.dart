import 'table_schema.dart';

class PriceHistoryTable implements TableSchema {
  @override
  String get tableName => 'price_history';

  @override
  String get createTable => '''
    CREATE TABLE price_history (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
      old_price REAL NOT NULL,
      new_price REAL NOT NULL,
      change_type TEXT NOT NULL,
      reason TEXT NULL,
      creator_id INTEGER REFERENCES app_users (id),
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [];
}
