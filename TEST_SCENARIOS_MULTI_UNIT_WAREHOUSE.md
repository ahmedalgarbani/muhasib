# سيناريوهات اختبار - نظام تعدد الوحدات واختيار المخزن
# Test Scenarios - Multi-Unit & Warehouse Selection

> الغرض: توثيق سيناريوهات اختبار يدوي/آلي للتغيرات الأخيرة في الفواتير (مبيعات/مشتريات/POS) وتعدد الوحدات والحساب المستودعي.
> Purpose: Manual/Automated test scenarios for recent invoice/POS/multi-unit/warehouse changes.

---

## 1. إعداد البيانات الأولية | Preconditions

### 1.1 إنشاء وحدات قياس
- **الخطوة:** الإعدادات > الأصناف > الوحدات > إضافة `حبة` (مختصر: حب)، `درزن` (12)، `كرتون` (24)، `بكت` (6)
- **المتوقع:** تحفظ بنجاح، `conversion_factor` افتراضي 1.0

### 1.2 إنشاء مخازن
- **الخطوة:** المخازن > إضافة `المخزن الرئيسي` (رئيسي)، `مخزن الفرع`
- **المتوقع:** `stocks.is_main_stock=1` للرئيسي، كل مخزن له `account_id` اختياري للمحاسبة المستودعية

### 1.3 إنشاء صنف متعدد الوحدات
- **الخطوة:** الأصناف > منتج جديد
  - الاسم: `مياه 330مل`، الباركود الأساسي: `1000001`
  - الوحدة الأساسية: `حبة`، تكلفة: `10`، بيع: `15`
  - الوحدات الإضافية:
    - `درزن`: تحتوي على `12`، سعر بيع `170`، باركود `1000001-DZ`، افتراضي بيع ✓
    - `كرتون`: `24`، سعر بيع `320`، تكلفة `220`، باركود `1000001-CT`، افتراضي شراء ✓
- **المتوقع:** `category_sub_units` يحوي صفين، `is_default_sale/purchase` موزعة، `totalConversionFactor = packaging*conversionRate`، الرصيد الافتتاحي بالوحدة الأساسية فقط

---

## 2. المشتريات | Purchases

### 2.1 فاتورة مشتريات بوحدة كرتون + مخزن الفرع
- **الخطوات:**
  1. مشتريات > فاتورة جديدة
  2. اختر المورد + المخزن: `مخزن الفرع`
  3. أضف بند: اختر `مياه 330مل` → اختر الوحدة `كرتون` → الكمية `5` → تأكد أن السعر تغير تلقائياً إلى `320` (أو `220` تكلفة إن وجد) والإجمالي `5*320=1600`، والكمية الأساسية المعروضة `120 حبة`
  4. احفظ
- **المتوقع:**
  - `invoices.stock_id = مخزن الفرع`
  - `invoice_lines.quantity=5, packaging=24, conversionRate=1, base_quantity=120, unit_id=كرتون, category_sub_unit_id=كرتون, stockId=مخزن الفرع`
  - `warehouse_stocks (product=مياه, warehouse=فرع) quantity=120 avg_cost≈220/24≈9.16 أو 10` حسب المنطق، `stock_movements.quantity=120, original_quantity=5, unit_id=كرتون`
  - التقرير: رصيد `مخزن الفرع = 5 كرتون (120 حبة)`، `المخزن الرئيسي = 0`

### 2.2 تغيير الوحدة داخل بند مشتريات
- **الخطوات:** في نفس الفاتورة قبل الحفظ، غيّر الوحدة من `كرتون` إلى `حبة`
- **المتوقع:** السعر يتغير تلقائياً إلى `10` (أو `15` بيع لكن مشتريات تستخدم تكلفة)، الإجمالي يعاد `5*10=50`، الكمية الأساسية `5`

### 2.3 باركود ذكي مشتريات
- **الخطوات:** في `إضافة صنف مشتريات` امسح `1000001-CT`
- **المتوقع:** يختار تلقائياً `مياه 330مل` + وحدة `كرتون` + السعر `320`

### 2.4 تغيير مخزن الفاتورة بعد إضافة بنود
- **الخطوات:** أضف بندين بمخزن `الرئيسي`، ثم غيّر هيدر المخزن إلى `الفرع` واحفظ
- **المتوقع:** جميع البنود تُزامن `stockId=الفرع` (`syncedLines` في `purchase_form_widgets.dart:130`)، المخزون يُضاف للفرع فقط

---

## 3. المبيعات | Sales

### 3.1 فاتورة مبيعات باختيار مخزن + وحدات
- **الخطوات:**
  1. مبيعات > فاتورة جديدة (`/sales/add-invoice`) → تحقق أن الشاشة تفتح (كانت تفشل قبل الإصلاح بسبب `WarehousesCubit` الناقص)
  2. اختر العميل + المخزن `مخزن الفرع` (يجب أن يظهر `المخزون سيُخصم من هذا المخزن محاسبياً`)
  3. أضف `مياه 330مل`: إن ظهر picker اختر `كرتون` (يجب عرض `كرتون (24 حبة) - السعر 320`)
  4. الكمية `2` → الإجمالي `640`، المخزون المتاح معروض `120 حبة` (أو `5 كرتون`)
  5. احفظ
- **المتوقع:**
  - `invoices.stock_id=مخزن الفرع`
  - `invoice_lines.quantity=2, base_quantity=48, packaging=24`
  - `warehouse_stocks (فرع) 120→72 (خصم 48)`، `stock_movements quantity=-48 original_quantity=2`
  - القيد المحاسبي: إن كان للمخزن `account_id` مخصص استُخدم، وإلا `المخزون 1130`، `تكلفة البضاعة 3160` بـ `totalCogs = 48*avg_cost`

### 3.2 منع البيع بالسالب لكل مخزن (محاسبياً)
- **الخطوات:** حاول بيع `10 كرتون (240 حبة)` من `مخزن الفرع` والمتاح `72`
- **المتوقع:** فشل الحفظ مع `الكمية غير كافية: المتاح 72، المطلوب 240` (تحقق في `_reduceStockForSalesLines:757`)، لا ينشأ قيد ولا حركة

### 3.3 عرض فاتورة محفوظة مع وحدتها
- **الخطوات:** افتح تفاصيل الفاتورة السابقة
- **المتوقع:** سطر المنتج يظهر `الكمية: 2 (24x) × 320 (48 حبة أساس)` via `quotation_detail_components:244` (إن لم يظهر، تحقق أن `InvoiceLineEntity` يحوي `packaging`)

### 3.4 مرتجع مبيعات لنفس المخزن
- **الخطوات:** من الفاتورة أنشئ مرتجع `1 كرتون`
- **المتوقع:** `stock_movements.quantity=+24` في `مخزن الفرع`، رصيد يعود `72→96`، قيد عكسي `تكلفة البضاعة` دائن و`المخزون` مدين بمقدار `1*avg_cost`، `warehouseId` نفس مخزن الفاتورة الأصلية (`return_invoice_form_page:638`)

---

## 4. نقطة البيع POS

### 4.1 اختيار مخزن في POS
- **الخطوات:**
  1. POS → أعلى شاشة اختيار الأصناف يظهر ودجت `المخزن: [المخزن الرئيسي ▼] محاسبي`
  2. غيّر إلى `مخزن الفرع` والسلة غير فارغة → يظهر حوار `تغيير المخزن سيفرغ السلة` → وافق
  3. السلة فُزِّغت
- **المتوقع:** `_selectedWarehouseId` تغير، `_cart.clear()`، toast

### 4.2 إضافة صنف بوحدات في POS مع picker
- **الخطوات:** اضغط كارت `مياه 330مل` (له درزن+كرتون)
- **المتوقع:** يظهر `BottomSheet` `اختر الوحدة` (حبة، درزن 12 حبة، كرتون 24 حبة) مع الأسعار المحسوبة `resolveUnitPrice` ورموز ★ للافتراضي، اختيار `كرتون` يضيف للسلة `line.unitDisplay=كرتون, unitPrice=320, quantity=1, baseQuantity=24`

### 4.3 تغيير وحدة بند في سلة POS
- **الخطوات:** في سلة POS (الخطوة 2)، بجانب كل بند اضغط `320 ر.س / كرتون ↹` لفتح picker، اختر `درزن`
- **المتوقع:** السعر يتغير إلى `170`، الإجمالي `170*1`، `الأساس: 12 حبة` يظهر تحت السعر، `_changeLineUnit` يستدعي `resolveUnitPrice`

### 4.4 باركود ذكي POS
- **الخطوات:** اضغط أيقونة الماسح → امسح `1000001-DZ`
- **المتوقع:** `_scanBarcode` عبر `UnitConversionService.lookupByBarcode` يضيف `مياه + درزن` مباشرة مع toast `تمت إضافة: مياه (درزن)`

### 4.5 حفظ فاتورة POS بمخزن محدد
- **الخطوات:** أضف `2 كرتون`، اختر عميل، أكمل الدفع نقداً، احفظ
- **المتوقع:** `InvoiceEntity.stockId = _selectedWarehouseId` وليس `SettingsCache.defaultWarehouse`، `lines.stockId = نفس المخزن`، حركة مخزون `-48` في المخزن المختار

---

## 5. المخازن والتحويلات

### 5.1 تحويل مخزني بوحدة كرتون
- **الخطوات:** مخازن > تحويل > من `الفرع` إلى `الرئيسي`، أضف `1 كرتون مياه`
- **المتوقع:** `stock_transfer_lines.base_quantity=24`, `warehouse_stocks` المصدر `96→72`، الوجهة `0→24`، `avg_cost` منقول بنفس متوسط المصدر، `stock_movements` سطران `transfer_out -24` و `transfer_in +24` مع `original_quantity=1`

### 5.2 كمية أكبر من المتاح في التحويل
- **الخطوات:** حاول تحويل `10 كرتون` من الفرع والمتاح `3 كرتون`
- **المتوقع:** رفض `الكمية المتوفرة ... أقل من المطلوبة` (اختبار `stores_audit_test`).

---

## 6. التقارير والطباعة

### 6.1 تقرير حركة الصنف
- **الخطوات:** تقارير > حركة الأصناف > فلتر `مياه`
- **المتوقع:** كل حركة تظهر `quantityDisplay`: مثل `2 كرتون (48 حبة)` إن كانت الحركة بوحدة تعبئة، وإلا `48 حبة` (عبر `ItemMovementEntity.quantityDisplay` و `stock_movements.original_quantity/packaging`)

### 6.2 تقرير الأرصدة الهرمي
- **الخطوات:** تقارير > أرصدة الأصناف > بدون فلتر مخزن
- **المتوقع:** `hierarchicalDisplay`: مثل `4 كرتون و 2 حبة (98 حبة)` أو `10 كرتون` إن لا باقي، محسوب من `packaging*conversionRate` لأكبر وحدة غير أساسية

### 6.3 طباعة فاتورة
- **الخطوات:** افتح فاتورة مبيعات > طباعة
- **المتوقع:** جدول البنود يظهر `الكمية: 2 | الوحدة: كرتون | السعر: 320 | الإجمالي 640` مع سطر صغير `الأساس 48 حبة`

---

## 7. حالات حدية ودقة

### 7.1 كسور وتدوير
- **الخطوات:** وحدة `لتر` بمعامل `0.5` (لتر = 500مل)، بيع `1.5 لتر`
- **المتوقع:** `baseQuantity = roundQuantity(0.75)` → `0.75`، `total = roundCurrency(1.5*price)` بلا `0.3000000004`

### 7.2 توافق عكسي
- **الخطوات:** افتح قاعدة قديمة بدون صفوف `category_sub_units` إضافية
- **المتوقع:** `factor=1`, `baseQuantity=quantity`, الباركود القديم `categories.barcode_no` يعمل، لا أخطاء `CHECK`

### 7.3 مسار GoRouter
- **الخطوات:** من `/sales/list` اضغط `فاتورة جديدة` → `context.pushNamed(AppRoutes.salesAddInvoice)`، كذلك `POS` من القائمة
- **المتوقع:** لا `ProviderNotFoundException`، الشاشة تفتح مع `WarehousesCubit, ProductGroupsCubit, CurrenciesCubit` موفرة (تم إصلاح `app_router.dart:302`)

---

## 8. اختبارات آلية مقترحة (للإضافة إلى `flutter test`)

```dart
test('Multi-unit sale deducts base quantity per warehouse', () async {
  // purchase 5 cartons (120 base) into warehouse 2
  // sell 2 cartons (48 base) from same warehouse
  // expect warehouse_stocks.quantity 72 and stock_movements.original_quantity 2
});
test('Warehouse mismatch is prevented', () async { /* sell from empty warehouse throws */ });
test('POS unit picker resolves price', () async {
  final svc = UnitConversionService(db);
  final u = await svc.getDefaultSaleUnit(productId);
  expect(svc.resolveUnitPrice(baseSellPrice: 15, unit: u), 170); // drzn
});
```

---

## 9. قائمة الملفات الملموسة للتغيير (للمطور)

- `lib/core/database/migrations/008_multi_unit_enhancement.sql`, `category_sub_units_table.dart`, `stock_transfer_lines_table.dart`, `database_config.dart:9`, `database_service.dart: onUpgrade<9`
- `lib/core/services/precision_helper.dart`, `unit_conversion_service.dart`
- `lib/features/products/.../product_sub_unit_entity/model`, `product_form_page.dart`
- `lib/features/sales/presentation/pages/improved_sales_invoice_screen.dart`, `pos_page.dart`, `lib/features/purchases/.../add_line_dialog.dart`
- `lib/features/inventory_reports/.../item_movement`, `items_balance`
- `lib/core/route/app_router.dart` (providers)
```

