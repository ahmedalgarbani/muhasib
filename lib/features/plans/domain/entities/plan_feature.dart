/// Feature switches that can be enabled or disabled per subscription plan.
///
/// Add new features here first, then reference them from
/// `PlansCatalog` and wrap the relevant screen with `FeatureGate`.
enum PlanFeature {
  pointOfSale('نقطة البيع'),
  salesInvoices('فواتير البيع'),
  salesReturns('مرتجعات البيع'),
  quotations('عروض الأسعار'),
  purchases('فواتير الشراء'),
  purchaseReturns('مرتجعات الشراء'),
  purchaseOrders('أوامر الشراء'),
  products('إدارة الأصناف'),
  multiUnit('تعدد وحدات القياس'),
  customers('العملاء'),
  suppliers('الموردون'),
  stockOperations('حركات المخزون (تحويلات وجرد)'),
  warehouses('تعدد المخازن'),
  accounting('القيود والسندات المحاسبية'),
  multiCurrency('تعدد العملات والصرف'),
  reportsBasic('التقارير الأساسية'),
  reportsAdvanced('التقارير المالية المتقدمة'),
  barcodeScanning('الباركود'),
  backup('النسخ الاحتياطي'),
  users('تعدد المستخدمين'),
  prioritySupport('دعم ذو أولوية');

  const PlanFeature(this.labelAr);

  final String labelAr;
}
