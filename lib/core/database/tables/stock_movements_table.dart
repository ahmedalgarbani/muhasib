import 'table_schema.dart';

/// Table for tracking all stock/inventory movements
/// Records every change to product quantities in warehouses
class StockMovementsTable implements TableSchema {
  @override
  String get tableName => 'stock_movements';

  @override
  String get createTable => '''
    CREATE TABLE stock_movements (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- Product and location
      product_id INTEGER NOT NULL REFERENCES categories (id),
      warehouse_id INTEGER NOT NULL REFERENCES stocks (id),
      
      -- Movement type: sale, purchase, return_sale, return_purchase, transfer_in, transfer_out, adjustment, initial
      movement_type TEXT NOT NULL,
      
      -- Quantity (positive for in, negative for out)
      quantity REAL NOT NULL,
      unit_cost REAL NOT NULL DEFAULT 0.0,
      total_cost REAL NOT NULL DEFAULT 0.0,
      
      -- Balance tracking
      balance_before REAL NULL,
      balance_after REAL NOT NULL,
      
      -- Reference to source document
      reference_type TEXT NULL,
      -- sales_invoice, purchase_invoice, transfer, adjustment, return, etc.
      reference_id INTEGER NULL,
      reference_number TEXT NULL,
      
      -- Additional info
      batch_number TEXT NULL,
      expiry_date INTEGER NULL,
      notes TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_stock_movements_product ON stock_movements (product_id)',
    'CREATE INDEX idx_stock_movements_warehouse ON stock_movements (warehouse_id)',
    'CREATE INDEX idx_stock_movements_type ON stock_movements (movement_type)',
    'CREATE INDEX idx_stock_movements_reference ON stock_movements (reference_type, reference_id)',
    'CREATE INDEX idx_stock_movements_date ON stock_movements (creation_time DESC)',
  ];
}

/// Table for warehouse stock balances (current inventory levels)
class WarehouseStocksTable implements TableSchema {
  @override
  String get tableName => 'warehouse_stocks';

  @override
  String get createTable => '''
    CREATE TABLE warehouse_stocks (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      
      -- Product and location
      product_id INTEGER NOT NULL REFERENCES categories (id),
      warehouse_id INTEGER NOT NULL REFERENCES stocks (id),
      
      -- Current quantities and costs
      quantity REAL NOT NULL DEFAULT 0.0,
      reserved_quantity REAL NOT NULL DEFAULT 0.0,
      available_quantity REAL GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
      
      -- Cost tracking (for COGS calculation)
      avg_cost REAL NOT NULL DEFAULT 0.0,
      last_cost REAL NOT NULL DEFAULT 0.0,
      total_value REAL GENERATED ALWAYS AS (quantity * avg_cost) STORED,
      
      -- Reorder settings
      min_level REAL NULL DEFAULT 0.0,
      max_level REAL NULL,
      reorder_point REAL NULL,
      reorder_quantity REAL NULL,
      
      -- Unique constraint: one record per product-warehouse combination
      UNIQUE (product_id, warehouse_id)
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_warehouse_stocks_product ON warehouse_stocks (product_id)',
    'CREATE INDEX idx_warehouse_stocks_warehouse ON warehouse_stocks (warehouse_id)',
    'CREATE INDEX idx_warehouse_stocks_low ON warehouse_stocks (quantity) WHERE quantity <= min_level',
  ];
}
