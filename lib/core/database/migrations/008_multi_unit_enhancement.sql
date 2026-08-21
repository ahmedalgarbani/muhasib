-- Migration 008: Multi-Unit & Packaging Hierarchy Enhancement
-- Date: 2026-08-22
-- Description: يضيف حقول تعدد الوحدات (باركود، أسعار، افتراضيات البيع/الشراء) ويدعم فصل كمية الوحدة عن الكمية الأساسية
-- Backward compatible: جميع الحقول الجديدة nullable أو بقيم افتراضية

-- 1) توسيع جدول الوحدات الفرعية category_sub_units
-- إضافة باركود خاص بكل وحدة (للبيع عبر الماسح)
ALTER TABLE category_sub_units ADD COLUMN barcode TEXT NULL;
ALTER TABLE category_sub_units ADD COLUMN cost_price REAL NULL;
ALTER TABLE category_sub_units ADD COLUMN sell_price REAL NULL;
ALTER TABLE category_sub_units ADD COLUMN wholesale_price REAL NULL;
ALTER TABLE category_sub_units ADD COLUMN is_default_sale INTEGER NOT NULL DEFAULT 0 CHECK(is_default_sale IN (0,1));
ALTER TABLE category_sub_units ADD COLUMN is_default_purchase INTEGER NOT NULL DEFAULT 0 CHECK(is_default_purchase IN (0,1));

-- فهارس للباركود والبحث
CREATE UNIQUE INDEX IF NOT EXISTS idx_category_sub_units_barcode ON category_sub_units(barcode) WHERE barcode IS NOT NULL AND barcode != '';
CREATE INDEX IF NOT EXISTS idx_category_sub_units_product ON category_sub_units(category_id);
CREATE INDEX IF NOT EXISTS idx_category_sub_units_unit ON category_sub_units(unit_id);
CREATE INDEX IF NOT EXISTS idx_category_sub_units_default_sale ON category_sub_units(category_id, is_default_sale) WHERE is_default_sale = 1;
CREATE INDEX IF NOT EXISTS idx_category_sub_units_default_purchase ON category_sub_units(category_id, is_default_purchase) WHERE is_default_purchase = 1;

-- ضمان عدم تكرار نفس الوحدة لنفس الصنف (حبة لا تتكرر مرتين)
CREATE UNIQUE INDEX IF NOT EXISTS idx_category_sub_units_unique_product_unit ON category_sub_units(category_id, unit_id) WHERE unit_id IS NOT NULL;

-- Trigger: عند تعيين وحدة كافتراضية للبيع: إلغاء الافتراض عن باقي وحدات نفس الصنف
DROP TRIGGER IF EXISTS trg_category_sub_units_default_sale_unique;
CREATE TRIGGER trg_category_sub_units_default_sale_unique
AFTER UPDATE OF is_default_sale ON category_sub_units
WHEN NEW.is_default_sale = 1
BEGIN
  UPDATE category_sub_units SET is_default_sale = 0
  WHERE category_id = NEW.category_id AND id != NEW.id AND is_default_sale = 1;
END;

DROP TRIGGER IF EXISTS trg_category_sub_units_default_sale_insert;
CREATE TRIGGER trg_category_sub_units_default_sale_insert
AFTER INSERT ON category_sub_units
WHEN NEW.is_default_sale = 1
BEGIN
  UPDATE category_sub_units SET is_default_sale = 0
  WHERE category_id = NEW.category_id AND id != NEW.id AND is_default_sale = 1;
END;

-- Trigger للافتراضي شراء
DROP TRIGGER IF EXISTS trg_category_sub_units_default_purchase_unique;
CREATE TRIGGER trg_category_sub_units_default_purchase_unique
AFTER UPDATE OF is_default_purchase ON category_sub_units
WHEN NEW.is_default_purchase = 1
BEGIN
  UPDATE category_sub_units SET is_default_purchase = 0
  WHERE category_id = NEW.category_id AND id != NEW.id AND is_default_purchase = 1;
END;

DROP TRIGGER IF EXISTS trg_category_sub_units_default_purchase_insert;
CREATE TRIGGER trg_category_sub_units_default_purchase_insert
AFTER INSERT ON category_sub_units
WHEN NEW.is_default_purchase = 1
BEGIN
  UPDATE category_sub_units SET is_default_purchase = 0
  WHERE category_id = NEW.category_id AND id != NEW.id AND is_default_purchase = 1;
END;

-- التحقق من صحة معامل التحويل: يجب أن يكون موجباً
DROP TRIGGER IF EXISTS trg_category_sub_units_conversion_check_insert;
CREATE TRIGGER trg_category_sub_units_conversion_check_insert
BEFORE INSERT ON category_sub_units
WHEN NEW.conversion_rate <= 0 OR NEW.packaging <= 0
BEGIN
  SELECT RAISE(ABORT, 'معامل التحويل وكمية التعبئة يجب أن تكون موجبة');
END;

DROP TRIGGER IF EXISTS trg_category_sub_units_conversion_check_update;
CREATE TRIGGER trg_category_sub_units_conversion_check_update
BEFORE UPDATE OF conversion_rate, packaging ON category_sub_units
WHEN NEW.conversion_rate <= 0 OR NEW.packaging <= 0
BEGIN
  SELECT RAISE(ABORT, 'معامل التحويل وكمية التعبئة يجب أن تكون موجبة');
END;

-- 2) توسيع تحويلات المخزون لدعم كمية أساسية (base_quantity)
ALTER TABLE stock_transfer_lines ADD COLUMN base_quantity REAL NULL;
ALTER TABLE stock_transfer_lines ADD COLUMN conversion_rate REAL NULL DEFAULT 1.0;
ALTER TABLE stock_transfer_lines ADD COLUMN packaging INTEGER NULL DEFAULT 1;

-- Trigger: احتساب base_quantity تلقائياً عند عدم توفره (quantity * conversion_rate * packaging -> لكن نختصر)
DROP TRIGGER IF EXISTS trg_stock_transfer_lines_base_qty_insert;
CREATE TRIGGER trg_stock_transfer_lines_base_qty_insert
AFTER INSERT ON stock_transfer_lines
WHEN NEW.base_quantity IS NULL
BEGIN
  UPDATE stock_transfer_lines SET
    base_quantity = NEW.quantity * COALESCE(NEW.conversion_rate, 1.0) * COALESCE(NEW.packaging, 1),
    conversion_rate = COALESCE(NEW.conversion_rate, 1.0),
    packaging = COALESCE(NEW.packaging, 1)
  WHERE id = NEW.id;
END;

-- 3) توسيع الجرد و التسويات
ALTER TABLE inventory_lines ADD COLUMN base_quantity REAL NULL;
ALTER TABLE inventory_lines ADD COLUMN conversion_rate REAL NULL DEFAULT 1.0;
ALTER TABLE inventory_lines ADD COLUMN packaging INTEGER NULL DEFAULT 1;

-- 4) توسيع سجل حركات المخزون لدعم تتبع الوحدة الأصلية
ALTER TABLE stock_movements ADD COLUMN unit_id INTEGER NULL REFERENCES categories_units(id);
ALTER TABLE stock_movements ADD COLUMN conversion_rate REAL NULL DEFAULT 1.0;
ALTER TABLE stock_movements ADD COLUMN original_quantity REAL NULL;
ALTER TABLE stock_movements ADD COLUMN packaging INTEGER NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_stock_movements_unit ON stock_movements(unit_id);

-- 5) توسيع categories_prices: إضافة باركود للسعر إن رغب (اختياري مستقبلاً)
-- لا حاجة حالياً - الأسعار مرتبطة بالوحدة الفرعية و تحتوي على sell_price مباشرة

-- 6) تهيئة بيانات افتراضية: إنشاء وحدة أساسية لكل صنف لا يملك وحدة فرعية رئيسية
-- لكل صنف بدون سجل رئيسي، أنشئ سجلاً يربط وحدته الأساسية (unit_id) كوحدة رئيسية بمعامل 1
INSERT OR IGNORE INTO category_sub_units (category_id, unit_id, packaging, conversion_rate, is_main_unit, is_active, is_default_sale, is_default_purchase, creation_time, last_modification_time)
SELECT c.id, c.unit_id, 1, 1.0, 1, 1, 1, 1,
       CAST(strftime('%s','now') AS INTEGER),
       CAST(strftime('%s','now') AS INTEGER)
FROM categories c
WHERE c.unit_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM category_sub_units csu WHERE csu.category_id = c.id AND csu.is_main_unit = 1);

-- For products with no sub-unit at all, ensure at least one default exists derived from categories.unit_id
-- handled above
