-- Migration: Fix tolerance from 0.02 to 0.01 (C6)
-- Version: 007
-- Date: 2026-08-21

-- SQLite cannot ALTER CHECK constraint, so we enforce via triggers
DROP TRIGGER IF EXISTS trg_journal_entries_tolerance_insert;
DROP TRIGGER IF EXISTS trg_journal_entries_tolerance_update;

CREATE TRIGGER trg_journal_entries_tolerance_insert
BEFORE INSERT ON journal_entries
WHEN ABS(NEW.total_debit - NEW.total_credit - NEW.difference) >= 0.01 OR ABS(NEW.difference) >= 0.01
BEGIN
  SELECT RAISE(ABORT, 'القيد غير متوازن: الفرق يجب أن يكون أقل من 0.01');
END;

CREATE TRIGGER trg_journal_entries_tolerance_update
BEFORE UPDATE ON journal_entries
WHEN ABS(NEW.total_debit - NEW.total_credit - NEW.difference) >= 0.01 OR ABS(NEW.difference) >= 0.01
BEGIN
  SELECT RAISE(ABORT, 'القيد غير متوازن: الفرق يجب أن يكون أقل من 0.01');
END;
