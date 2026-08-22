# تقرير التدقيق المحاسبي الشامل - محاسب / muhasib

> تاريخ: 2026-08-23  
> النطاق: فحص كامل المشروع ميزة ميزة وملف ملف  
> المنهج: IFRS / IAS2 (المخزون)، VAT السعودية 15%، الجرد المستمر، القيد المزدوج المتوازن  
> الحالة: تم إصلاح محور المشتريات/مردود المشتريات - باقي المحاور قيد انتظار موافقتك قبل الإصلاح

---

## 0) ما تم إصلاحه مسبقاً (للمرجع)

| الملف | السطر | الإصلاح | الأثر |
|---|---|---|---|
| `lib/features/sales/data/datasources/invoice_local_datasource.dart:440` | `_increaseStockForPurchaseLines` | توزيع وزني للخصم الترويسي والرسوم + كشف التكرار (خطأ مضاعفة) + WAC صافي | تكلفة المخزون مطابقة للدفتر |
| `...:1693` | `_postPurchaseInvoiceToJournal` | perpetual صافي `netInventory = subtotal - totalDiscount + fee` + ض.مدخلات 1170 + مخزن خاص بالمستودع + فحص فترة مقفلة وتكرار رقم | ميزانية صحيحة |
| `...:1925` | `_postPurchaseReturnToJournal` | عكس صافي المخزون + ضريبة مدخلات | مردود متوازن |
| `...:634` | `_reduceStockForPurchaseReturnLines` | منع السالب إذا `!allowNegativeStock` | حماية كمية |
| `lib/core/services/purchase_invoice_accounting_service.dart:85/315` | محاسبة مشتريات | نفس IAS2 | توحيد |
| `lib/features/purchases/domain/templates/purchases_accounting_template.dart` | قوالب | صافي بدل إجمالي | اختبارات 1035/2070 |
| `lib/features/purchases/presentation/pages/purchase_form_widgets.dart:64` | إجماليات | كشف التكرار + تقريب قرشين + Clamp ضريبة | عرض صحيح |
| `lib/features/purchases/presentation/widgets/purchase_form_totals_and_notes.dart` | حقول | السماح بالكسور `^\d*\.?\d*` | UX |
| `lib/features/purchases/presentation/pages/select_purchase_for_return_page.dart:38` | مردود جزئي | اختيار كميات لكل بند + توزيع وزني | يمنع تجاوز الأصلي |
| `lib/features/purchases/presentation/pages/purchase_returns_page.dart` + `purchase_returns_widgets.dart` | بحث وإحصائيات حية | تصفية + `total/avg/thisMonth` | تصميم |

اختبارات: `purchases_accounting_audit_test.dart` 5/5 و `accounting_fixes_test.dart` 14/14 ناجحة.

---

## 1) المبيعات - فاتورة عادية وسريعة (invoice_type 1 و 6)

### ملفات الفحص
- `lib/features/sales/data/datasources/invoice_local_datasource.dart:_postSalesInvoiceToJournal` (الأسطر ~1007-1417)
- `lib/features/sales/presentation/pages/improved_sales_invoice_screen.dart`
- `lib/features/sales/presentation/widgets/sale_page_body.dart` + `sales_invoice_screen.dart`
- `lib/core/services/sales_invoice_accounting_service.dart`

### مشاكل محاسبية مشتبه بها (تحتاج موافقتك قبل الإصلاح)
1. **COGS والمخزون:** هل `_reduceStockForSalesLines` + `Debit COGS / Credit Inventory` يستخدم نفس `avg_cost` الحالي أم `cost_price` المحفوظ بالسطر؟ قد يوجد ازدواج إذا كان `cost_price=0`.
2. **الضريبة:** `410` مبيعات + `2140` ضرائب أم `2170` مخرجات؟ حالياً `_postSalesInvoiceToJournal` يستخدم `taxes` 4، بينما `sales_invoice_accounting_service` يستخدم `outputVAT` 18 - ازدواج.
3. **الخصم المسموح به:** هل `discountAllowed 3150` يُسجّل كمدين contra-revenue أم يُخفّض الإيراد مباشرة؟ حالياً مدين منفصل.
4. **الرسوم الإضافية `other_fee_amt`:** هل تُسجّل كإيراد آخر `4120` أم تُضاف للإيراد؟ قد لا تُحتسب في `finalAmt` بشكل متسق.
5. **الدفع المجزأ `paid_amount/bank_paid_amount`:** تقسيم نقدي/بنك/آجل في `_postSalesInvoiceToJournal` يوزع بشكل صحيح لكن قد لا يُحدث `customers.current_balance` إذا كان الدفع بنكي جزئي.
6. **العملة:** `currency_id` و `exchange_rate` هل تُحفظ في `journal_entry_lines.currency_id` ويُحدّث `account_limits`؟

**أسئلة لك:**
- هل تريد COGS = `cost_price * qty` المحفوظة بالسطر أم `avg_cost` لحظة البيع؟
- هل الضريبة مخرجات 2170 أم ضرائب 2140؟
- هل الخصم والرسوم صافي أم منفصل؟

---

## 2) مردود المبيعات (invoice_type 4)

### ملفات
- `lib/features/sales/data/datasources/invoice_local_datasource.dart:_postSalesReturnToJournal` (~1419-1662) + `createReturnInvoice` (~3648-3902)
- `lib/features/sales/presentation/pages/returns_page.dart` + `return_invoice_form_page.dart`

### مشاكل
1. **عكس COGS:** `cogs_reversal` يُحتسب من `line.cost_price` أو `avg_cost`؟ قد يختلف عن COGS الأصلي.
2. **الكمية التراكمية:** يوجد فحص `returnedBaseSum + baseQty > origBaseSum` لكنه لا يراعي `unit conversion` بشكل كامل في بعض المسارات القديمة.
3. **الضريبة والخصم:** نفس ازدواج المبيعات.
4. **السالب:** عند حذف مردود يُعاد المخزون `+returnQty` بدون فحص سالب (حذف المردود يقلل المخزون).
5. **الربط `parent_invoice_id`:** هل يُمسح عند حذف المردود بشكل صحيح؟ يوجد `next_invoice_id` لكن ليس `parent`.

**سؤال:** هل مردود المبيعات يجب أن يعيد المخزون بسعر `avg_cost` الحالي أم بسعر البيع الأصلي؟

---

## 3) عروض الأسعار (invoice_type 3)

### ملفات
- `invoice_local_datasource.dart: convertQuotationToInvoice` + `updateInvoice/deleteInvoice` حماية القفل
- `lib/features/sales/presentation/pages/quotations_page.dart`

### مشاكل
1. **القيد:** عرض السعر لا يُنشئ قيداً - صحيح، لكن عند التحويل هل يُنشأ قيد مبيعات + مخزون ذري مع `is_locked=1`؟ نعم لكن قد يفتقد فحص `valid_until`.
2. **الموافقة:** `approval_status` 0 draft 1 pending 2 approved 3 rejected - هل التحويل يسمح فقط لـ approved؟
3. **التكرار:** فحص `next_invoice_id` موجود لكن لا يوجد فحص ضريبة/خصم في العرض.

**سؤال:** هل تسمح بتحويل عرض منتهي `valid_until` مع تحذير أم تمنعه؟

---

## 4) أوامر الشراء (invoice_type 3 + transType 1)

### ملفات
- `invoice_local_datasource.dart:convertPurchaseOrderToInvoice` (~3496-3646)
- `lib/features/purchases/presentation/pages/purchase_orders_page.dart`
- `lib/features/purchases/data/repositories/purchase_repository_impl.dart:convertOrderToInvoice`

### مشاكل
1. **القيد:** أمر الشراء لا يُنشئ قيداً - صحيح (التزام غير مالي)، لكن عند التحويل هل يُنشأ قيد مشتريات + مخزون ذري؟ نعم.
2. **القفل:** `is_locked` بعد التحويل صحيح.
3. **المخزن:** هل أمر الشراء يستخدم `stock_id` نفسه عند التحويل أم قد يتغير؟

**سؤال:** هل أمر الشراء يحتاج تكلفة متوقعة `expected_cost` مختلفة عن الفاتورة الفعلية؟

---

## 5) المخزون والمستودعات

### ملفات
- `lib/features/stores/data/datasources/inventory_local_datasource.dart`
- `lib/features/stores/data/datasources/stock_adjustment_local_datasource.dart`
- `lib/features/stores/data/datasources/stock_transfer_local_datasource.dart`
- `lib/features/stores/data/datasources/warehouse_local_datasource.dart`
- `lib/core/services/unit_conversion_service.dart`
- `lib/features/products/data/datasources/product_local_datasource.dart`

### مشاكل
1. **WAC ازدواج:** `warehouse_stocks.avg_cost` يُحدث في `_increaseStockForPurchaseLines` (صافي) لكن `categories.cost_amount` قد لا يُحدث - ازدواج تكلفة.
2. **التحويل بين المستودعات:** هل القيد `Debit Inventory (dest) / Credit Inventory (src)` بمتوسط التكلفة أم بسعر محدد؟ قد لا يُنشأ قيد محاسبي أصلاً.
3. **التسوية الجردية:** `stock_adjustment` هل تُسجّل `5200 خسائر / 4200 إيرادات تسوية` بشكل متوازن؟ قد تسجل فقط كمية بدون قيد.
4. **الخدمات:** `categories.track_inventory=0` هل تُستثنى من `warehouse_stocks` و `COGS`؟ في المبيعات يوجد فحص لكن في المشتريات لا.
5. **الباركود متعدد الوحدات:** `category_sub_units.conversion_rate/packaging` هل `base_quantity` تُحسب دائماً `qty*packaging*conversion`؟

**أسئلة:**
- هل تسوية المخزون بالزيادة تُقيم بسعر `avg_cost` أم `last_cost`؟
- هل تحويل المخزون يحتاج قيداً محاسبياً؟

---

## 6) دليل الحسابات والربط

### ملفات
- `lib/core/database/tables/seeders.dart` (~96-159)
- `lib/core/services/account_config_service.dart`
- `lib/core/enums/account_connect_type.dart`
- `lib/features/accounts/data/datasources/account_local_datasource.dart`

### مشاكل
1. **ازدواج المخزون:** `c_id 1130` (المخزون) و `1180` (المخزون في _seedExpenses) - نفس الحساب بمعرفين مختلفين، قد يسبب ربط خاطئ.
2. **الربط الناقص:** `account_connects` لا تُنشأ لـ 11 salesReturns, 12 purchaseReturns, 13 COGS, 17 inputVAT, 18 outputVAT - يتم إنشاؤها تلقائياً عند أول قيد لكن `c_id` قد لا يتطابق مع `accounts`.
3. **نوع الحساب:** `accounts.type` 0 أصل 1 التزام 3 إيراد 4 مصروف - بعض البذور تستخدم `type=2` لحقوق الملكية قد لا تظهر في الميزانية.
4. **العملة المحلية:** `local_balance` هل يُحدث دائماً `balance * exchange_rate`؟ في `_applyAccountBalanceDelta` يُحدّث لكن في `purchase_invoice_accounting_service._applyBalanceDelta` يُستخدم `exchangeRate=1` ثابت.

**سؤال:** هل نحذف `1180` ونوحّد على `1130`؟ وهل نُجبر كل `account_connect_type` على بذرة إجبارية؟

---

## 7) القيود اليومية والسندات

### ملفات
- `lib/features/accounts/data/datasources/journal_local_datasource.dart`
- `lib/features/accounts/data/datasources/voucher_local_datasource.dart`
- `lib/core/services/accounting_service.dart`

### مشاكل
1. **التوازن:** `journal_entries.total_debit/total_credit` يُحتسب لكن `difference` قد لا يُفحص عند الإدخال اليدوي.
2. **الترقيم:** `_nextJournalNumber` يستخدم `MAX(id)+1` وليس `number_sequences` - قد يتكرر عند الحذف.
3. **الإلغاء:** `_reverseJournalEntryEffects` ينشئ قيد عكسي `status=2` لكن الأصلي يبقى `status=2` بينما التقارير تفلتر `status=1` فقط - قد تُستبعد الأرصدة الصحيحة.
4. **السندات:** `vouchers` هل تُنشئ قيداً مزدوجاً؟ قد تُسجل حركة صندوق فقط بدون مقابل مورد/عميل.

**سؤال:** هل السند يجب أن ينشئ قيداً تلقائياً أم حركة صندوق فقط؟

---

## 8) الأرصدة الافتتاحية والإقفال السنوي

### ملفات
- `lib/features/initial/data/datasources/initial_local_datasource.dart`
- `lib/core/services/closing_entries_service.dart`
- `lib/features/accounts/presentation/pages/open_balance_page.dart`

### مشاكل
1. **الافتتاحي:** `opening_entry` بـ `reference_type='opening_entry'` قد يُستبعد من `balance_sheet` إذا فلتر `NOT IN ('opening_entry')` كما في `cash_flow`.
2. **الإقفال:** هل يُقفل `3110 مشتريات` و `4110 مبيعات` و `3190 COGS` في `2120 رأس مال` أم في `حساب أرباح مرحلة`؟ قد لا يُصفّر.

**سؤال:** هل تريد إقفالاً بنهاية السنة يصفّر الإيرادات/المصروفات؟

---

## 9) العملات وأسعار الصرف

### ملفات
- `lib/features/currencies/data/datasources/currency_local_datasource.dart`
- `lib/core/services/currency_exchange_service.dart`
- `lib/features/reports/data/datasources/reports_local_datasource.dart:getAccountsForRevaluation`

### مشاكل
1. **إعادة التقييم:** `currency_revaluation` هل تُنشئ قيد `4160 أرباح / 3170 خسائر` فروق عملة بشكل متوازن؟
2. **سعر الصرف بالسطر:** `invoice_line.exchange_rate` قد لا يُستخدم في `journal` (يُستخدم `currency_id` فقط).

**سؤال:** هل الفواتير بعملة أجنبية تُسجل بسعر الصرف لحظة الفاتورة أم بسعر الإقفال؟

---

## 10) المدفوعات وحدود الحسابات

### ملفات
- `lib/features/accounts/data/datasources/account_limit_local_datasource.dart`
- `lib/features/accounts/domain/interceptors/account_limit_interceptor.dart`

### مشاكل
1. **الحد:** `_validateAndUpdateAccountLimits` يُفحص `current_debit/credit` لكن بعد الحذف/العكس هل يُعاد `MAX(0, current- amount)` بشكل صحيح؟ نعم لكن قد لا يُراعي العملة.
2. **الدفع الآجل:** `invoice.payment_status` 0 غير مدفوعة 1 مدفوعة 2 جزئية - هل يُحدث عند إنشاء سند؟ قد لا يرتبط.

**سؤال:** هل تريد ربط السندات تلقائياً بحالة دفع الفاتورة؟

---

## 11) التقارير

### ملفات
- `lib/features/reports/data/datasources/reports_local_datasource.dart` (778 سطر)
- `lib/features/reports/presentation/pages/*.dart`
- `lib/features/reports/data/datasources/trial_balance_datasource.dart` + `income_statement_datasource.dart` + `stock_datasource.dart`

### مشاكل
1. **الميزان:** `getBalanceSheetAccounts` يحسب `net = SUM(debit-credit)` لكل حساب لكن لا يفصل `local_balance` عن `balance` للعملات.
2. **قائمة الدخل:** `getBalanceSheetNetIncome` تجمع `credit-debit` للإيرادات و `debit-credit` للمصروفات لكن قد تدرج `3110 مشتريات` كـ `cost_of_sales` مع `3190` مما يضاعف التكلفة إذا كان الجرد مستمر (المخزون أصل).
3. **التدفق النقدي:** `getCashFlow` يستبعد `opening_entry` لكن قد يستبعد أيضاً `purchase_invoice` النقدية إذا كان `paymentAccount` ليس من `account_connects 0,1`.
4. **مخزون:** `getInventoryValuation` يجمع `warehouse_stocks.quantity * avg_cost` لكن لا يطرح مردودات غير مرحلة.

**سؤال:** هل قائمة الدخل يجب أن تعرض `صافي المشتريات = المشتريات - مردودات` أم `COGS` فقط؟

---

## 12) الضرائب والإعدادات

### ملفات
- `lib/features/setting/data/repositories/settings_repository.dart`
- `lib/core/services/settings_cache.dart`
- `lib/core/database/seeders/tax_seeder.dart`

### مشاكل
1. **الضريبة الافتراضية:** `tax_seeder` قد تنشئ `15%` لكن `invoices.tax_ratio` قد تُخزن كنسبة 15 أو كقيمة 0.15 بشكل غير متسق.
2. **الإعدادات:** `stock_settings.default_warehouse` قد يكون `null` فيُستخدم `stocks.id=1` تلقائياً بدون تنبيه.

---

## كيف سنعمل (مهم)

1. سأبدأ بمحور واحد فقط بعد موافقتك.
2. لكل مشكلة سأكتب: **الوصف - الملف:السطر - الأثر المالي - الحل المقترح - هل أوافق؟**
3. لن أعدّل أي كود حتى تكتب **"وافق على إصلاح #X"**.
4. بعد الموافقة سأطبق الإصلاح ذريّاً داخل `transaction` مع اختبار `flutter test`.

### ماذا تريد أن نبدأ به أولاً؟

اختر رقماً واحداً للبدء:
- **1 المبيعات** - **2 مردود المبيعات** - **3 عروض الأسعار** - **4 المخزون** - **5 الحسابات/القيود** - **6 التقارير** - **7 العملات** - **أو اكتب "ابدأ بـ 1"**

> يمكنك أيضاً كتابة **"وافق على الكل perpetual صافي"** إذا تريد نفس منهج المشتريات (صافي، 1170/2170، مخزون خاص بالمستودع) على كل المحاور دون سؤال لكل مشكلة.

