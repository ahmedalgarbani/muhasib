import 'table_schema.dart';

class CustomerPointsTable implements TableSchema {
  @override
  String get tableName => 'customer_points';

  @override
  String get createTable => '''
    CREATE TABLE customer_points (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
      points_balance REAL NOT NULL DEFAULT 0,
      total_earned REAL NOT NULL DEFAULT 0,
      total_redeemed REAL NOT NULL DEFAULT 0,
      last_activity_time INTEGER NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [];
}
