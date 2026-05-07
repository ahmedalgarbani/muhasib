-- Migration: Add Fiscal Periods Table
-- Version: 001
-- Date: 2026-04-16

CREATE TABLE IF NOT EXISTS fiscal_periods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  year INTEGER NOT NULL,
  period INTEGER NOT NULL,  -- 0 = full year, 1-12 = months
  start_date INTEGER NOT NULL,  -- Unix timestamp (seconds)
  end_date INTEGER NOT NULL,
  status INTEGER DEFAULT 0,  -- 0 = open, 1 = closed, 2 = locked
  is_closed INTEGER DEFAULT 0,
  closed_by INTEGER,
  closed_at INTEGER,
  notes TEXT,
  creation_time INTEGER NOT NULL,
  last_modification_time INTEGER NOT NULL,
  UNIQUE(year, period)
);

CREATE INDEX IF NOT EXISTS idx_fiscal_periods_year ON fiscal_periods(year);
CREATE INDEX IF NOT EXISTS idx_fiscal_periods_status ON fiscal_periods(status);
CREATE INDEX IF NOT EXISTS idx_fiscal_periods_dates ON fiscal_periods(start_date, end_date);

-- Create current fiscal year (2026)
INSERT OR IGNORE INTO fiscal_periods 
  (year, period, start_date, end_date, status, is_closed, creation_time, last_modification_time)
VALUES 
  (2026, 0, strftime('%s', '2026-01-01'), strftime('%s', '2026-12-31'), 0, 0, strftime('%s', 'now'), strftime('%s', 'now'));
