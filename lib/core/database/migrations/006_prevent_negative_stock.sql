-- Migration: Prevent negative stock (C3) + enforce CHECK
-- Version: 006
-- Date: 2026-08-21

-- Create trigger to prevent negative quantity on insert/update
CREATE TRIGGER IF NOT EXISTS trg_warehouse_stocks_no_negative_insert
BEFORE INSERT ON warehouse_stocks
WHEN NEW.quantity < 0
BEGIN
  SELECT RAISE(ABORT, 'الكمية لا يمكن أن تكون سالبة - المخزون غير كافٍ');
END;

CREATE TRIGGER IF NOT EXISTS trg_warehouse_stocks_no_negative_update
BEFORE UPDATE OF quantity ON warehouse_stocks
WHEN NEW.quantity < 0
BEGIN
  SELECT RAISE(ABORT, 'الكمية لا يمكن أن تكون سالبة - المخزون غير كافٍ');
END;

-- Also prevent negative on categories.quantity fallback
CREATE TRIGGER IF NOT EXISTS trg_categories_no_negative_update
BEFORE UPDATE OF quantity ON categories
WHEN NEW.quantity < 0
BEGIN
  SELECT RAISE(ABORT, 'كمية الصنف لا يمكن أن تكون سالبة');
END;
