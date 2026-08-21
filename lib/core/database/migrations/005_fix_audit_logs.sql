-- Migration: Fix audit_log vs audit_logs duplication (C4)
-- Version: 005
-- Date: 2026-08-21

-- If audit_log (singular) exists and audit_logs (plural) doesn't exist, rename it
-- SQLite doesn't support IF EXISTS for RENAME, so we handle via creation and data copy

-- Create audit_logs table if not exists (correct schema from AuditLogsTable)
CREATE TABLE IF NOT EXISTS audit_logs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NULL DEFAULT 1,
  action_type TEXT NULL,
  action TEXT NULL,
  table_name TEXT NULL,
  entity_type TEXT NULL,
  record_id INTEGER NULL,
  entity_id INTEGER NULL,
  old_values TEXT NULL,
  new_values TEXT NULL,
  ip_address TEXT NULL,
  user_agent TEXT NULL,
  creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
  created_at INTEGER NULL,
  description TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_time ON audit_logs(creation_time);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);

-- Migrate data from old audit_log (singular) to audit_logs (plural) if exists
-- Map old schema (id, table_name, record_id, operation, user_id, username, timestamp, old_values, new_values, ip_address, notes, transaction_id)
-- to new schema
INSERT OR IGNORE INTO audit_logs (id, user_id, action_type, table_name, record_id, old_values, new_values, ip_address, creation_time, description)
SELECT id, user_id, operation as action_type, table_name, record_id, old_values, new_values, ip_address, timestamp as creation_time, notes as description
FROM audit_log
WHERE EXISTS (SELECT name FROM sqlite_master WHERE type='table' AND name='audit_log');

-- Create view for backward compatibility so old code reading audit_log still works
CREATE VIEW IF NOT EXISTS audit_log_view AS SELECT * FROM audit_logs;

-- Optionally drop old singular table after migration (commented for safety - keep for now)
-- DROP TABLE IF EXISTS audit_log;

-- Trigger to keep audit_log view in sync (SQLite updatable view not needed, we use audit_logs directly)
