import 'table_schema.dart';

class PosHeldOrdersTable implements TableSchema {
  @override
  String get tableName => 'pos_held_orders';

  @override
  String get createTable => '''
    CREATE TABLE pos_held_orders (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL,
      last_modification_time INTEGER NOT NULL,
      customer_id INTEGER NULL,
      customer_name TEXT NULL,
      note TEXT NULL,
      items_json TEXT NOT NULL
    );
  ''';

  @override
  List<String> get indexes => [
        'CREATE INDEX IF NOT EXISTS idx_pos_held_orders_created ON pos_held_orders(creation_time);',
      ];
}
