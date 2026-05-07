-- Migration: Add Number Sequences Table
-- Version: 002
-- Date: 2026-04-16

CREATE TABLE IF NOT EXISTS number_sequences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sequence_type TEXT NOT NULL UNIQUE,  -- 'sales_invoice', 'purchase_invoice', 'journal_entry', etc.
  prefix TEXT,
  current_value INTEGER NOT NULL DEFAULT 0,
  min_value INTEGER DEFAULT 1,
  max_value INTEGER,
  increment_by INTEGER DEFAULT 1,
  padding_length INTEGER DEFAULT 6,  -- for leading zeros
  fiscal_year INTEGER,  -- for year-based reset
  reset_on_year_change INTEGER DEFAULT 0,
  last_reset_date INTEGER,
  creation_time INTEGER NOT NULL,
  last_modification_time INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_number_sequences_type ON number_sequences(sequence_type);

-- Insert default sequences
INSERT OR IGNORE INTO number_sequences 
  (sequence_type, prefix, current_value, padding_length, reset_on_year_change, fiscal_year, creation_time, last_modification_time)
VALUES 
  ('sales_invoice', 'INV', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now')),
  ('purchase_invoice', 'PINV', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now')),
  ('quotation', 'QT', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now')),
  ('journal_entry', 'JE', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now')),
  ('receipt_voucher', 'RV', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now')),
  ('payment_voucher', 'PV', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now')),
  ('sales_return', 'SRT', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now')),
  ('purchase_return', 'PRT', 0, 6, 0, NULL, strftime('%s', 'now'), strftime('%s', 'now'));
