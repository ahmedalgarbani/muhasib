/// Numeric limits that a plan can cap. A missing or `null` value means the
/// limit is unlimited for that plan.
enum PlanLimit {
  maxProducts('الأصناف'),
  maxWarehouses('المخازن'),
  maxUsers('المستخدمون'),
  maxCurrencies('العملات'),
  maxMonthlyInvoices('فواتير البيع شهرياً');

  const PlanLimit(this.labelAr);

  final String labelAr;
}
