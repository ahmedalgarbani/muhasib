CREATE TABLE IF NOT EXISTS pos_held_orders (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  creator_id INTEGER NULL DEFAULT 1,
  creation_time INTEGER NOT NULL,
  last_modification_time INTEGER NOT NULL,
  customer_id INTEGER NULL,
  customer_name TEXT NULL,
  note TEXT NULL,
  items_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_pos_held_orders_created ON pos_held_orders(creation_time);
