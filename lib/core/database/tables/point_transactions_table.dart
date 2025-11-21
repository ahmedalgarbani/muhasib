import 'table_schema.dart';

class PointTransactionsTable implements TableSchema {
  @override
  String get tableName => 'point_transactions';

  @override
  String get createTable => '''
    CREATE TABLE point_transactions (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
      transaction_type INTEGER NOT NULL,
      points REAL NOT NULL,
      remaining_balance REAL NOT NULL,
      reference_type TEXT NULL,
      reference_id INTEGER NULL,
      description TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [];
}
