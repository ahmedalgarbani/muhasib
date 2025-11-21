import 'table_schema.dart';

class StockAlertsTable implements TableSchema {
  @override
  String get tableName => 'stock_alerts';

  @override
  String get createTable => '''
    CREATE TABLE stock_alerts (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
      min_quantity REAL NOT NULL,
      max_quantity REAL NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_notification_time INTEGER NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
