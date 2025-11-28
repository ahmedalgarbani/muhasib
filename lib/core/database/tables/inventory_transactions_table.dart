import 'table_schema.dart';

class InventoryTransactionsTable implements TableSchema {
  @override
  String get tableName => 'inventory_transactions';

  @override
  String get createTable => '''
    CREATE TABLE inventory_transactions (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL REFERENCES products(id),
      transaction_type TEXT NOT NULL CHECK(transaction_type IN ('purchase', 'sale', 'return', 'adjustment', 'transfer')),
      quantity REAL NOT NULL,
      unit_price REAL NULL,
      total_amount REAL NULL,
      balance_after REAL NOT NULL,
      warehouse_id INTEGER NULL,
      reference_type TEXT NULL,
      reference_id TEXT NULL,
      notes TEXT NULL,
      transaction_date INTEGER NOT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_inventory_transactions_product ON inventory_transactions(product_id);',
    'CREATE INDEX idx_inventory_transactions_date ON inventory_transactions(transaction_date);',
    'CREATE INDEX idx_inventory_transactions_type ON inventory_transactions(transaction_type);',
  ];
}
