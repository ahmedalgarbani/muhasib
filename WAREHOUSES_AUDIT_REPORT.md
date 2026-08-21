# تقرير تدقيق قسم المخازن — التحويل المخزني والجرد والتسوية

> **التاريخ:** 21 أغسطس 2026  
> **النطاق:** `lib/features/stores/**` (≈ 62 ملف) + `lib/core/database/{migrations,tables}` + `lib/core/helpers/get_it.dart` + `lib/core/route/app_router.dart`  
> **الأبعاد:** برمجي + محاسبي + تصميمي/واجهات  
> **المنهجية:** قراءة مباشرة لكل ملف (لا اعتماد على التخمين)، مع تتبع التنفيذ من الـ Cubit → Repository → DataSource → DB → المحاسبة → الواجهة. تم التحقق يدوياً عبر `Read` لكل ملف مذكور أدناه.

---

## ملخص تنفيذي

تم رصد **~71 مشكلة** موزعة كالتالي:

| البُعد | حرج (Critical) | عالي (High) | متوسط (Medium) | منخفض (Low) |
|---|---|---|---|---|
| **برمجي** | 10 | 19 | 9 | 4 |
| **محاسبي** | 10 | 8 | 2 | 1 |
| **واجهات/تصميم** | — | 10 | 9 | 5 |

**أخطر النتائج:**
1. `stock_transfer_repository_impl.dart:79-98` — `createTransfer()` مجرد stub يُرجع `Right(1)` ولا يكتب أي شيء في DB → كل التحويلات تضيع.
2. `warehouses_inventory_page.dart:332` — الجرد يستخدم `product.quantity` (إجمالي كل المخازن) بدلاً من `warehouse_stocks.quantity` للمخزن المحدد → فروقات الجرد خاطئة تماماً في بيئة متعددة المخازن.
3. `warehouse_validation_service_impl.dart:89` — اسم أعمدة خاطئ `from_warehouse_id` بدل `from_stock_id` → استعلام يرمي `no such column` ويمنع/يكسر حذف المخزن.
4. تضارب محاسبي خطير: مساران مختلفان يستخدمان حسابات مختلفة لنفس الحدث (`4200/5200` مقابل `4900/5900`) — ميزان المراجعة غير قابل للمقارنة.
5. عدم ذرّية (Atomicity) في `stock_transfer_local_datasource.dart:90-116` و `inventory_local_datasource.dart:130-152` → حالة `completed` قد تُحفظ بينما حركة المخزون تفشل → عدم اتساق دفتري.

> **الخلاصة:** القسم يعمل ظاهرياً في السيناريو الأحادي (مخزن واحد، كميات صغيرة) لكنه **غير آمن محاسبياً وبرمجياً** في التشغيل الحقيقي متعدد المخازن/المستخدمين.

---

## 1) الأخطاء البرمجية

### 1.1 حرج (Critical)

#### P-CRIT-01 — `stock_transfer_repository_impl.dart:79-98` — `createTransfer` لا يكتب في DB
```dart
// final model = StockTransferModel.fromEntity(transfer);
// final id = await localDataSource.createTransfer(model);
return Right(1);
```
- الأثر: `StockTransferPage:367,374` يظن النجاح دائماً بـ `id=1`، ثم يستدعي `updateTransferStatus(1, completed)` على سجل خاطئ أو غير موجود. المسودات تضيع صامتة.
- الدليل: `stock_transfer_local_datasource.dart:70-87` سليم ويعمل بـ transaction، لكن الـ Repository لا يستدعيه.
- الإصلاح: فك التعليق وتمرير `model` الحقيقي وإرجاع `id` الفعلي.

#### P-CRIT-02 — ازدواج تعريف `StockTransferLineModel`
- `lib/features/stores/data/models/stock_transfer_model.dart:4-81` يعرف `StockTransferLineModel`
- `lib/features/stores/data/models/stock_transfer_line_model.dart:3-80` يعرف **نفس الاسم** مرة ثانية (نسخة مصححة لـ `cost_amount as num?`).
- الأثر: تضارب استيراد، ملف ميت، وانحراف مستقبلي. `stock_transfer_model.dart:48` يستخدم `as double?` (يفشل إذا القيمة int)، بينما الملف الثاني يستخدم `(as num?)?.toDouble()` الصحيح.
- الإصلاح: حذف أحدهما وجعل الآخر هو المصدر الوحيد (مع re-export إن لزم).

#### P-CRIT-03 — ازدواج كيان `StockTransferLineEntity` بشكلين غير متوافقين
- `stock_transfer_entity.dart:4-57` : `quantity, statement, costAmount, categoryId?, groupId, unitId, categorySubUnitId, stockTransferId?`
- `stock_transfer_line_entity.dart:3-87` : `stockTransferId!, categoryId!, categoryName?, cost!, totalAmount!, subUnitId? ...`
- نفس اسم الكلاس، حقول وأنواع مختلفة (`cost` مقابل `costAmount`). أي استيراد خاطئ يكسر الـ mapping. يتم الالتفاف عبر `lines.cast<StockTransferLineEntity>()` في `stock_transfer_local_datasource.dart:30`.
- الإصلاح: حذف `stock_transfer_line_entity.dart` أو إعادة تسميته بوضوح (مثلاً `LegacyTransferLine`).

#### P-CRIT-04 — `stock_transfer_repository_impl.dart:65-70` — `updateTransfer` يُنشئ سجلاً جديداً بدل التحديث
```dart
await localDataSource.createTransfer(model); // لا يوجد updateTransfer في DataSource
```
- يُولّد صفوفاً مكررة ويترك المسودة القديمة يتيمة. يخرق idempotency.

#### P-CRIT-05 — `warehouse_validation_service_impl.dart:87-91` — أسماء أعمدة خاطئة
```sql
WHERE (from_warehouse_id = ? OR to_warehouse_id = ?)
```
- الجدول الحقيقي `stock_transfers_table.dart:23` يستخدم `from_stock_id / to_stock_id`. الاستعلام يرمي `no such column` ويُحوّل إلى `Left(CacheFailure)` — حذف المخزن يبدو ممنوعاً أو ينهار.

#### P-CRIT-06 — `stock_transfer_local_datasource.dart:90-116` — تحديث الحالة وحركة المخزون غير ذريّين
- `database.update(status=completed)` في السطر 103 **خارج** الـ transaction، ثم `database.transaction(_processTransferCompletion)` في 161. إذا فشلت الثانية (نقص مخزون، CHECK)، تبقى الحالة `completed` بلا حركة → حاجز `if(current.status==completed)` في 98 يمنع إعادة المحاولة → سجل عالق.

#### P-CRIT-07 — `inventory_local_datasource.dart:130-152` — نفس مشكلة الذرّية + سباق (Race)
- الحارس `if(status==completed)` خارج الـ transaction (136)، والتحديث داخلها (141). بين `getInventory(id)` في 132 وبداية الـ transaction قد يمر طلبان متزامنان ويجتازان الحارس معاً → قيدين مكررين وحركة مضاعفة.

#### P-CRIT-08 — `warehouse_local_datasource.dart:186-210` — `setMainWarehouse()` غير محمي بـ transaction
- تحديثان متتاليان `UPDATE stocks SET is_main_stock=0` ثم `=1`. إذا انقطع التنفيذ بعد الأول → صفر مخازن رئيسية. تزامن استدعاءين → مخزنان رئيسيان لحظياً.

#### P-CRIT-09 — `inventory_local_datasource.dart:157-158` — قراءة المخزون بمفتاح منتج خاطئ
- `warehouse_stocks` مفتاحه `product_id = categoryId ?? 0`. إذا `categoryId == null` (مسموح في المخطط)، يُحسب الفرق لمنتج وهمي `0` ويُنشئ صفوف `warehouse_stocks(product_id=0)`.

#### P-CRIT-10 — `warehouses_inventory_page.dart:309-341` — كمية النظام المستخدمة في الجرد **إجمالية** وليست per-warehouse
```dart
quantity: product.quantity, // = SUM(warehouse_stocks.quantity) عبر كل المخازن — انظر product_local_datasource.dart:50
actualQuantity: 1,
difference: 1 - product.quantity,
```
- مستند الجرد per-warehouse (`stockId`) يجب أن يقرأ `warehouse_stocks WHERE warehouse_id=selected`. استخدام الإجمالي يولّد فائض/عجز وهمي وتقييم محاسبي خاطئ لأي منتج موزع على أكثر من مخزن. **هذا أخطر خطأ وظيفي في الجرد.**

---

### 1.2 عالي (High)

| # | الملف:السطر | الوصف |
|---|---|---|
| P-HIGH-01 | `warehouse_local_datasource.dart:137-183` | فحوصات الحذف `COUNT(*)` ثم `DELETE` خارج transaction → TOCTOU race، قد يُدرج سطر جديد بين الفحص والحذف. |
| P-HIGH-02 | `stock_transfer_local_datasource.dart:154-155` | `_processTransferCompletion` يقرأ `getTransfer` خارج الـ transaction (يستخدم `database.query` لا `txn.query`) → لقطة قديمة تحت التزامن. |
| P-HIGH-03 | `stock_adjustment_local_datasource.dart:371-378` | `_getAdjustmentLines` يُقرأ خارج transaction أثناء `postAdjustment` → سطور قديمة. |
| P-HIGH-04 | `inventory_local_datasource.dart:239-247` | عند عدم وجود `warehouse_stocks` يُدرج `quantity: difference` وقد تكون سالبة → ينتهك `CHECK(quantity>=0)` ويُسقط الـ transaction بخطأ غامض. |
| P-HIGH-05 | `stock_adjustment_local_datasource.dart:230-238` | لا تحقق من توفر الكمية قبل `newQty = currentQty + quantity` (سالب للخصم) → قد يُدرج كمية سالبة. |
| P-HIGH-06 | `stock_transfer_local_datasource.dart:189-194` | `rawUpdate quantity-?` إذا لم يوجد صف المصدر (الكمية 0) → `availableQty=0` ثم `rawUpdate` يؤثر على 0 صفوف بصمت، لكن حركتي `stock_movements` تُسجلان → تضخم مخزني. |
| P-HIGH-07 | `warehouse_local_datasource.dart:19` vs `stock_adjustment_local_datasource.dart:19` | خلط حقن `Database` مباشرة مقابل `DatabaseService`. المقبض قد يصبح قديماً إذا أُعيد فتح DB. |
| P-HIGH-08 | `get_it.dart:652-701` + `stock_adjustment_accounting_template.dart:11` | القالب المحاسبي غير مسجل في DI (كود ميت). `StockAdjustmentValidationService` بلا Implementation ولا تسجيل — `checkDailyLimit/hasAdjustmentPermission` لا تُستدعى أبداً. |
| P-HIGH-09 | `stock_adjustment_repository_impl.dart:91-93` | `approveAdjustment` تستدعي `postAdjustment` خطأً — الاعتماد يجب أن يسبق الترحيل، الآن يُنشئ قيداً قبل الموافقة. |
| P-HIGH-10 | `stock_transfer_local_datasource.dart:28-31` و `inventory_local_datasource.dart:30-33` و `stock_adjustment_local_datasource.dart:32-35` | نمط N+1: `getTransfers()` تطلق `1+N` استعلاماً (واحد لكل مستند) → بطء مع 100 مستند. |
| P-HIGH-11 | `stock_transfer_model.dart:48` و `warehouse_model.dart:53-55` | `map['cost_amount'] as double?` يرمي إذا القيمة int. الملف المكرر يصلحها بـ `(as num?)?.toDouble()` — عدم اتساق. |
| P-HIGH-12 | `stock_transfer_local_datasource.dart:91-93` | تحويل الحالة عبر `e.name == status` هش؛ الجدول يخزن `value` عددياً، والـ Repository يمرر `status.name` نصاً. |
| P-HIGH-13 | `stock_adjustment_local_datasource.dart:483-488` و `inventory_local_datasource.dart:524-531` | `number LIKE '$prefix-%'` بتركيب نصي مباشر (SQL injection نظرياً) وهشاشة `SUBSTR(number, ${prefix.length+2})` مع صيغ يدوية `TRF-123`. |
| P-HIGH-14 | `inventory_local_datasource.dart:379-380` | `_resolveCurrencyId` قد ترجع `null` وتُدرج `currency_id: null` في `journal_entry_lines` بينما الـ FK يتوقع NOT NULL في بعض المخططات. |
| P-HIGH-15 | `inventory_local_datasource.dart:593-599` | حذف جرد مرحّل يعكس الكمية عبر `quantity + reverseDelta` دون إعادة حساب `avg_cost` → انحراف تقييم بعد الحذف. |
| P-HIGH-16 | `stock_transfer_local_datasource.dart:293` و `inventory_local_datasource.dart:213` | `currency_id: 1` مُصلّب في كل مكان — يتجاهل العملات المتعددة. |
| P-HIGH-17 | `stock_transfer_local_datasource.dart:277-320` | `trans_doc_type` أرقام سحرية `5` للتحويل و `6` للجرد بلا Enum/ثوابت. |
| P-HIGH-18 | `inventory_repository_impl.dart:101-105` | `getCurrentStock()` ترجع `[]` دائماً — الواجهة لا تستطيع تعبئة الكميات المتوقعة. |
| P-HIGH-19 | تسمية `warehouse_id` مقابل `stock_id` | خلط `warehouse_stocks.warehouse_id` و `invoices.stock_id` و `stock_transfers.from_stock_id` بينما الكيانات تستخدم `warehouseId/stockId` بالتبادل — يخفي أخطاء mapping. |

### 1.3 متوسط (Medium)

- **P-MED-01** ارتباك وحدات الزمن: `millisecondsSinceEpoch ~/1000` في الواجهات مقابل `strftime('%s')` في DB — بلا helper موحد.
- **P-MED-02** `warehouse_model.dart:66-83` `toMap` يحذف الحقول الـ null انتقائياً — `fromMap` يرمي بدل المعالجة اللطيفة.
- **P-MED-03** `stock_transfer_model.dart:131` `lines = const []` قائمة ثابتة مشتركة قابلة للمشاركة بالخطأ.
- **P-MED-04** تكرار كود picker المنتجات ومنطق الكميات في 3 صفحات (`Transfer`, `Adjustment`, `Inventory`).
- **P-MED-05** `_getUsageStats` يحسب `stock_movements` و `invoice_lines` بينما `warehouse_local_datasource` يحسب `warehouse_stocks` و `stock_transfers` — حارسان مختلفان لنفس قرار الحذف → تناقض.
- **P-MED-06** `warehouses_cubit.dart:40-50` يبث `WarehouseCreated(id)` ثم فوراً `loadWarehouses()` → الحالة الأولى تُفقد قبل أن يلتقطها `warehouse_form_page.dart:121-134`.
- **P-MED-07** كل Cubits يبث `Loading` في كل عملية ويمسح القائمة → وميض وفقدان حالة البحث.
- **P-MED-08** لا ترقيم صفحات (Pagination) — `getTransfers()` يحمّل كل الصفوف في الذاكرة.
- **P-MED-09** حقن `Database` مباشرة يتجاوز دورة حياة `DatabaseService`.

### 1.4 منخفض (Low)

- تعليق به خطأ إملائي `inventory_line_entity.dart:102` `mathod`.
- `database_service.dart:146-152` يبتلع أخطاء إنشاء الجداول `catch (_) {}` ويخفي فشل الترحيل.
- تسمية ملفات غير متسقة: `stock_adjustment_model.dart` يحوي الموديل والسطر معاً بينما `stock_adjustment_line_model.dart` مكرر.

---

## 2) الأخطاء المحاسبية

### 2.1 حرج (Critical)

#### A-CRIT-01 — تقييم التحويل يستخدم `costAmount` المدخل يدوياً بدل متوسط المصدر
`stock_transfer_local_datasource.dart:213`
```dart
newAvgCost = ((destQty*destAvg)+(qty*costAmount))/newQty
```
يجب أن يكون النقل بسعر **المتوسط المرجح للمصدر**، لا إدخال المستخدم. الحالي يسمح بتضخيم/تقليص قيمة المخزون عبر التحويل دون قيد محاسبي.

#### A-CRIT-02 — التحويل بلا قيد محاسبي (صحيح مبدئياً) لكن بلا قيد إعادة تقييم بين حسابات مخزون مختلفة
المخطط `stocks.account_id` لكل مخزن (`stocks_table.dart:23`) — إذا كان المخزنان يمثلان حسابي أستاذ مختلفين (فروع)، يجب إنشاء قيد: `من حـ/ مخزون الوجهة إلى حـ/ مخزون المصدر`. الحالي يتجاهل `account_id` تماماً.

#### A-CRIT-03 — تضارب حسابات الإيراد/المصروف للتسويات
- المسار الساخن `stock_adjustment_local_datasource.dart:269-283` و `inventory_local_datasource.dart:310-323` : `4200` إيراد، `5200` خسارة
- القالب الميت `stock_adjustment_accounting_template.dart:138-181` : `4900` إيراد، `5900` خسارة
- نفس الحدث الاقتصادي يضرب حسابات مختلفة → ميزان المراجعة غير قابل للمقارنة عبر المسارات.

#### A-CRIT-04 — الجرد ينشئ **تسوية واحدة لكل سطر** بدل تسوية واحدة بأسطر متعددة
`inventory_local_datasource.dart:185-218` حلقة تُنشئ N من `stock_settlements` + N من `stock_settlement_lines`. الصحيح: مستند تسوية واحد. الحالي يجزّئ التسلسل، ورقم `ADJ-INV-$id-$categoryId` قد يتصادم إذا تكرر نفس المنتج.

#### A-CRIT-05 — خلط نوع التسوية في الجرد المختلط
جرد واحد فيه زيادة ونقص ينشئ تسويات من نوعين متعاكسين، لكن القيد المحاسبي يجمع `totalIncrease/totalDecrease` إجمالياً — التقارير التي تفلتر حسب `type` ستظهر مستندات مجزأة مربكة.

#### A-CRIT-06 — أساس التكلفة للعجز/الفائض غير متسق
- الجرد `inventory_local_datasource.dart:176` : `unitCost = line.costAmount ?? currentAvg` — العجز يُقيّم بسعر العد (قد يكون 0) بدل المتوسط الدفتري → يقلل الخسارة.
- التسوية `stock_adjustment_local_datasource.dart:212-214` : تستخدم `currentAvg` للخصم (صحيح). **الاثنان يجب أن يتوحدا على المتوسط للخصم.**

#### A-CRIT-07 — تسوية الخصم قد تحاول إدراج `warehouse_stocks.quantity` سالبة
عند عدم وجود مخزون، `newQty = -qty` سالبة → ينتهك `CHECK(quantity>=0)` والـ trigger `006_prevent_negative_stock` → الـ transaction كلها تتراجع بلا رسالة مفهومة للمستخدم.

#### A-CRIT-08 — عدم تطابق `total_amount` بين الرأس والسطور والقيد
`stock_settlements.total_amount = differenceValue` لكل سطر، لكن القيد يجمع `unitCost * diff.abs`. فرق تقريب عائم بسيط يسبب انحراف `total_debit != total_credit` نظرياً.

#### A-CRIT-09 — منطق `balance` يتجاهل الطبيعة المدينة/الدائنة ويوحّد العملتين
`_applyAccountBalanceDelta` في `inventory_local_datasource.dart:483-508` و `stock_adjustment_local_datasource.dart:442-467`:
```dart
newBalance = current + delta; // +amount للمدين، -amount للدائن
```
يخزن `balance` و `local_balance` نفس القيمة. لحساب إيراد (طبيعته دائن) فإن `-amount` يجعل رصيده سالباً (كأنه مدين) → ميزان المراجعة يظهر الإيراد سالباً. كما يضيع فرق العملة الأجنبية.

#### A-CRIT-10 — حقول حالة القيد غير متسقة
- مسار الجرد/التسوية: `status:2, is_posted:1` (`inventory_local_datasource.dart:379-380`)
- مسار القالب: `status:0, is_posted:0` (`stock_adjustment_accounting_template.dart:50-51`) → قيود القالب غير مرئية في تقارير `is_posted=1`.

### 2.2 عالي (High)

| # | الملف:السطر | الوصف |
|---|---|---|
| A-HIGH-01 | `inventory_local_datasource.dart:425-469` | `getOrCreateAccount` يبحث بالكود ثم بالاسم — إذا وُجد بالاسم بكود مختلف يرجع id خاطئ. |
| A-HIGH-02 | كل `post*` | لا فحص للفترة المالية المغلقة — يجب استشارة `FiscalPeriodDataSource` (مسجل في `get_it.dart:230`). |
| A-HIGH-03 | `stock_adjustment_local_datasource.dart:261` | إذا `totalValue <=0.001` يتخطى القيد لكن حركة المخزون حدثت → كمية بلا أثر قيمة. |
| A-HIGH-04 | `stock_transfer_local_datasource.dart:277-320` | `category_movs` تُسجل `quantity` الخام دون تحويل الوحدات الفرعية → `quantity_in/out` غير دقيقة. |
| A-HIGH-05 | `inventory_local_datasource.dart:190-192` | `currency_code/exchange_rate` دائماً null → تقييم متعدد العملات مستحيل. |
| A-HIGH-06 | `stock_transfer_local_datasource.dart:165` | `costAmount ?? 0` للتحويل يخفّض المتوسط نحو الصفر إذا كان أول إدخال للوجهة. |
| A-HIGH-07 | `inventory_local_datasource.dart:604-606` | حذف جرد مرحّل يحذف `category_movs` لكن التحويل المكتمل لا يُعكس — لا حذف عكسي للتحويل. |
| A-HIGH-08 | `inventory_model.dart:84-86` | `total_difference/total_value` المخزنة تصبح قديمة بعد الترحيل لأن القيم أُعيد حسابها من المتوسط الحي. |

### 2.3 متوسط/منخفض

- **A-MED-01** ملاحظات `stock_transfer_local_datasource.dart:256` تخزن ID لا اسم المخزن → تدقيق غير مقروء.
- **A-MED-02** `stock_movements.movement_type` قيم نصية حرة `transfer_out/in`, `adjustment`, `inventory_adjustment` بلا Enum → تقارير مجزأة.
- **A-LOW-01** رقم القيد `SA-yyyyMMddHHmmss` قد يتصادم في نفس الثانية.

---

## 3) أخطاء التصميم والواجهات

### 3.1 عالي (High)

#### U-HIGH-01 — اختيار نفس المخزن للمصدر والوجهة ممكن
`stock_transfer_page.dart:161-165` يمسح الوجهة فقط إذا ساوت المصدر **الجديد**، لكن إذا اختار الوجهة أولاً ثم مصدراً مساوياً لها فلا مسح. `warehouse_page_sections.dart:342` يستخدم `where((w) => w != source)` (مقارنة هوية كائن لا `id`) → يفشل إذا كان نفس المخزن بكائنين مختلفين. التحقق النهائي فقط عند الإرسال `_validateInput():331`.

#### U-HIGH-02 — لا تغذية راجعة عن توفر الكمية قبل الإرسال
`stock_transfer_page.dart:307-323` يضيف أي منتج بكمية 1 دون عرض المتاح في مخزن المصدر. المستخدم يكتشف النقص فقط بعد ضغط ترحيل (استثناء داخل transaction). `product_picker_sheet.dart:173` يعرض `product.quantity` الإجمالي لا per-warehouse.

#### U-HIGH-03 — وضع الجرد الافتراضي يخفي الحقول
`warehouses_inventory_page.dart:48` `_isCountMode=false` يخفي العد. `inventory_lines_card.dart:63-91` تظهر `انتقل لوضع الجرد لبدء العد` بلا زر إجراء — المستخدم يجب أن يكتشف زر `Icons.inventory` في الـ AppBar. زر الحذف مخفي في وضع العد.

#### U-HIGH-04 — تسريب/إعادة إنشاء Controllers داخل `build`
- `stock_transfer_page.dart:266` `TextInputField(initialValue:...)` ينشئ controller جديد كل rebuild → فقدان التركيز.
- `warehouse_page_sections.dart:457-474` `TextEditingController(text:...)` داخل `build` → مؤشر الكتابة يقفز.

#### U-HIGH-05 — لا حالات تحميل/فارغ/خطأ لمحددات المخازن
`warehouse_page_sections.dart:303-358` و `inventory_warehouse_selector_card.dart:47-72` يعرضان dropdown فارغاً أثناء التحميل بلا spinner.

#### U-HIGH-06 — ويدجتان مكررتان لبطاقة المخزن
`warehouse_card.dart` مقابل `warehouse_card_widget.dart` — أيقونات وحشو مختلفان، إحداهما غير مستخدمة → تصميم غير متسق.

#### U-HIGH-07 — أرقام المستندات المولدة قد تتصادم
`stock_transfer_page.dart:76-79` و `stock_adjustment_page.dart:67-70` و `warehouses_inventory_page.dart:90-93` تستخدم `millisecondsSinceEpoch.substring(len-8)` (8 أرقام فقط → دورة كل ~27 ساعة). إنشاء متزامنان في نفس الميلي ثانية → `UNIQUE` violation كـ `LocalStorageFailure` عام.

#### U-HIGH-08 — دورة حياة الحوار `_pendingSubmit`
`StockTransferPage._pendingSubmit` يبقى عبر rebuilds لكن ليس عبر موت العملية؛ إذا غادر المستخدم قبل `TransferStatusUpdated` يُفقد، والـ Cubit يبث بعد dispose.

#### U-HIGH-09 — مشاكل RTL
- `warehouse_page_sections.dart:328-334` `Icons.arrow_forward` يشير يميناً في سياق RTL → يظهر عكسياً (المصدر→الوجهة تبدو معكوسة).
- `inventory_summary_card.dart:40-58` أرقام `+5` تُعرض LTR داخل RTL فتظهر الإشارة في الجهة الخاطئة.
- `product_picker_sheet.dart:56-58` `height*0.75` بلا `SafeArea/Padding(viewInsets)` → لوحة المفاتيح تغطي حقل البحث.

#### U-HIGH-10 — حذف جرد مرحّل بلا معاينة محاسبية
`inventory_local_datasource.dart:534-641` يعكس القيد والمخزون بصمت عند الحذف. لا تحذير "سيتم عكس القيد المحاسبي".

### 3.2 متوسط (Medium)

| # | الملف:السطر | الوصف |
|---|---|---|
| U-MED-01 | `stock_transfer_page.dart:179` vs `stock_adjustment_page.dart:467-493` vs `inventory_action_buttons.dart` | ثلاث أنماط مختلفة لأزرار الإجراءات. |
| U-MED-02 | `stock_transfer_page.dart:391-407` | حوارات وهمية `يمكن عرض السجل من الصفحة الرئيسية` — تنقل ميت. |
| U-MED-03 | `warehouse_form_page.dart:53-55` | `context.read<AccountsCubit>().loadAllAccounts()` في `initState` قبل توفر الـ Provider → لا أثر. |
| U-MED-04 | `warehouse_form_page.dart:152-159` | فلترة الحسابات بـ `name.contains('مخزون')` تفشل إذا كانت الأسماء إنجليزية أو بصياغة مختلفة. |
| U-MED-05 | `warehouse_form_page.dart:148-160` | تعيين `_accounts` داخل `BlocBuilder.builder` (أثر جانبي أثناء البناء). |
| U-MED-06 | `stock_level_indicator.dart:163-184` | `MediaQuery.size.width * percentage` بلا قيود → overflow داخل `Row/Card`. |
| U-MED-07 | `warehouses_list_page.dart:88-93` | حالة فارغة بلا زر إعادة محاولة أو إنشاء. |
| U-MED-08 | `inventory_product_count_card.dart:55` | `onSubmitted` يفتح الـ picker حتى لو الاستعلام فارغ. |
| U-MED-09 | كل صفحات التحويل/الجرد | لا `FormField.validator` لمحدد المخزن — الاعتماد على toast بدل خطأ inline. |

### 3.3 منخفض (Low)

- ألوان مُصلّبة `Colors.grey[400]` تتجاوز `AppColors`.
- `inventory_item_card.dart:66-76` عنوان عام `صنف` بدل اسم المنتج.
- `warehouse_selector_dropdown.dart:174-347` `OverlayEntry` بلا حارس `if(!mounted)` أو `Overlay.of(context)==null`.
- خلط `withOpacity(0.1)` و `withValues(alpha:0.1)` (الأول deprecated).
- نصوص عربية غير موحدة: `تحويل عادي` مقابل Enum بلا ترجمة.

---

## 4) قاعدة البيانات والـ DI والتوجيه

### قاعدة البيانات
- الجداول `stocks`, `stock_transfers`, `stock_transfer_lines`, `inventories`, `inventory_lines`, `stock_settlements`, `stock_settlement_lines`, `warehouse_stocks`, `stock_movements` موجودة في `database_service.dart:335-392` — **سليمة**.
- الـ triggers `006_prevent_negative_stock.sql` موجودة وتكمل التحقق التطبيقي.
- **ناقص:** فهارس على `stock_transfers.from_stock_id`, `stock_settlements.stock_id` — استعلامات حسب المخزن بطيئة (`indexes => []`).

### الترحيلات (`migration_runner.dart:21-29`)
- القائمة مُصلّبة 7 ترحيلات؛ أي عمود جديد يتطلب ملفاً جديداً + إضافة يدوية للقائمة — موثق لكن جداول المخازن غير مُنسخة بشكل منفصل.

### حقن التبعيات (`get_it.dart:652-701`)
- ✅ مسجل: `WarehouseLocalDataSource`, `StockTransferLocalDataSource`, `InventoryLocalDataSource`, `StockAdjustmentLocalDataSource` + المستودعات + 4 Cubits.
- ❌ مفقود: `StockAdjustmentAccountingTemplate` غير مسجل (كود ميت)، `StockAdjustmentValidationService` بلا Implementation.
- كل Cubits `registerFactory` — نسخة جديدة لكل صفحة، والصفحات تستدعي `getIt<Cubit>()` ثم `close()` في `dispose` (نمط مقبول لكن يخلط `context.read` مع `getIt`).

### التوجيه (`app_router.dart:449-484`)
- `warehouses` → `WarehousesMainPage` (hub)
- `warehouses/list` → `WarehousesListPage`
- `warehouseForm` يمرر `warehouse` عبر `state.extra as WarehouseEntity?` — صحيح
- `warehouses/inventory|adjustment|transfer` تُنشئ Cubits داخلياً عبر `getIt` (نسخة جديدة كل push)
- **ملاحظة:** `WarehousesMainPage:27` يستخدم `context.pushNamed('/warehouses/list')` بسلسلة مسار لا اسم route — هش (يعمل بالصدفة لأن الاسم == المسار).

---

## 5) خارطة الأولويات للإصلاح

| الأولوية | الملف:السطر | الإصلاح | الأثر |
|---|---|---|---|
| **P0** | `stock_transfer_repository_impl.dart:79` | فك stub `createTransfer` وربطه بـ DataSource | التحويلات لا تُحفظ إطلاقاً |
| **P0** | `warehouse_validation_service_impl.dart:89` | `from_warehouse_id`→`from_stock_id` | حذف المخزن مكسور |
| **P0** | `stock_transfer_local_datasource.dart:90` | تغليف تحديث الحالة + الحركة في transaction واحدة | عدم اتساق دفتري |
| **P0** | `warehouses_inventory_page.dart:309-341` | قراءة `warehouse_stocks.quantity` per-warehouse بدل `product.quantity` | فروقات الجرد خاطئة |
| **P0** | `data/models/stock_transfer_model.dart` vs `stock_transfer_line_model.dart` | توحيد `StockTransferLineModel` | تضارب أنواع |
| **P1** | `warehouse_local_datasource.dart:186` | transaction لـ `setMainWarehouse` | صفر/اثنان رئيسيان |
| **P1** | كل مسارات التسعير | توحيد تسعير الخصم على `currentAvg` وإزالة `costAmount` للخصم | تقييم خاطئ للخسارة |
| **P1** | `stock_adjustment_accounting_template.dart` | حذف أو توحيد `4200/5200` مقابل `4900/5900` | ميزان مراجعة غير متسق |
| **P1** | `stock_transfer_local_datasource.dart:213` | النقل بسعر متوسط المصدر لا `costAmount` | تضخم قيمة |
| **P1** | `inventory_local_datasource.dart:185` | تسوية واحدة برأس واحد + N سطور | تدقيق مجزأ |
| **P2** | `product_picker_sheet` | عرض المتاح per-warehouse والتحقق المسبق | UX + منع أخطاء |
| **P2** | `*_page.dart:76` | استخدام جدول `number_sequences` بدل timestamp مقطوع | تصادم أرقام |
| **P2** | `get_it.dart` | تسجيل `StockAdjustmentValidationService` وتفعيل `checkDailyLimit` | تحكم وحوكمة |
| **P2** | `stock_transfer_local_datasource.dart:277` | استبدال `5/6` بثوابت/Enum لـ `trans_doc_type` | صيانة |

---

## 6) توصيات إضافية

1. **اختبارات تكاملية** لكل `post*` تتحقق من: `warehouse_stocks` + `stock_movements` + `journal_entries` + `accounts.balance` في transaction واحدة، مع سيناريو تزامن (محاكاة طلبين متزامنين).
2. **خدمة ترقيم موحدة** (`NumberSequenceService`) بدل `millisecondsSinceEpoch` — تمنع التصادم وتدعم التسلسل السنوي/الشهري.
3. **فترة مالية:** حقن `FiscalPeriodDataSource` في كل `post*` ورفض الترحيل إذا الفترة مغلقة.
4. **وحدة العملة:** تمرير `currencyId/exchangeRate` من إعدادات الفاتورة/المخزن بدل `1` المُصلّب.
5. **تصميم:** توحيد `WarehouseActionButtons` و `InventoryActionButtons` في ويدجت واحد، وإصلاح `TextEditingController` عبر `StatefulWidget` منفصل لكل سطر.

---

### الملاحق — الملفات التي تم فحصها

```
lib/features/stores/data/datasources/{warehouse,stock_transfer,inventory,stock_adjustment}_local_datasource.dart
lib/features/stores/data/repositories/{warehouse,stock_transfer,inventory,stock_adjustment}_repository_impl.dart
lib/features/stores/data/models/{warehouse,stock_transfer,stock_transfer_line,inventory,inventory_line,stock_adjustment,stock_adjustment_line}_model.dart
lib/features/stores/data/templates/stock_adjustment_accounting_template.dart
lib/features/stores/data/services/warehouse_validation_service_impl.dart
lib/features/stores/domain/entities/{warehouse,stock_transfer,stock_transfer_line,inventory,inventory_line,stock_adjustment}_entity.dart
lib/features/stores/domain/repositories/{warehouse,stock_transfer,inventory,stock_adjustment}_repository.dart
lib/features/stores/domain/services/{warehouse_validation,stock_adjustment_validation}_service.dart
lib/features/stores/domain/enums/stock_enums.dart
lib/features/stores/presentation/cubit/{warehouses,stores,stock_transfers,stock_adjustments,inventory}_{cubit,state}.dart
lib/features/stores/presentation/pages/{warehouses_main,warehouses_list,warehouse_form,warehouses_inventory,stock_transfer,stock_adjustment}_page.dart
lib/features/stores/presentation/widgets/{warehouse_selector_dropdown,warehouse_page_sections,warehouse_card,warehouses_list_widget,stock_level_indicator,product_picker_sheet,inventory_*}_*.dart
lib/core/database/{migration_runner,tables/*,migrations/*}
lib/core/helpers/get_it.dart
lib/core/route/app_router.dart
```

> **تنبيه منهجي:** كل خلل أعلاه موثق بـ `file:line` ويمكن التحقق منه مباشرة عبر `Read`. إذا ظهر تعارض بين هذا التقرير وادعاء سابق غير مدعوم بدليل، فهذا التقرير هو المرجع.

