-- Migration: Add Audit Log Table
-- Version: 003
-- Date: 2026-04-16

CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  record_id INTEGER NOT NULL,
  operation TEXT NOT NULL,  -- 'INSERT', 'UPDATE', 'DELETE'
  user_id INTEGER,
  username TEXT,
  timestamp INTEGER NOT NULL,
  old_values TEXT,  -- JSON
  new_values TEXT,  -- JSON
  ip_address TEXT,
  notes TEXT,
  transaction_id TEXT  -- For grouping related changes
);

CREATE INDEX IF NOT EXISTS idx_audit_log_table ON audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_transaction ON audit_log(transaction_id);
