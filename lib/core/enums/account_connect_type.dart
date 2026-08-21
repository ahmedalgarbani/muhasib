/// أنواع ربط الحسابات — مرجع مركزي لجدول account_connects
/// Central enum for account_connects.account_connect_type

enum AccountConnectType {
  banks(0, 'البنوك', 'Banks'),
  cashboxes(1, 'الصناديق', 'Cashboxes'),
  customers(2, 'العملاء', 'Customers'),
  suppliers(3, 'الموردين', 'Suppliers'),
  taxes(4, 'الضرائب', 'Taxes'),
  inventory(5, 'المخزون', 'Inventory'),
  merchandise(6, 'البضاعة', 'Merchandise'),
  sales(7, 'المبيعات', 'Sales'),
  discountAllowed(8, 'الخصم المسموح به', 'Discount Allowed'),
  discountEarned(9, 'الخصم المكتسب', 'Discount Earned'),
  purchases(10, 'المشتريات', 'Purchases'),
  salesReturns(11, 'مردودات المبيعات', 'Sales Returns'),
  purchaseReturns(12, 'مردودات المشتريات', 'Purchase Returns'),
  costOfGoodsSold(13, 'تكلفة البضاعة المباعة', 'COGS'),
  salesCommissionExpense(14, 'عمولة المبيعات - مصروف', 'Sales Commission Expense'),
  commissionPayable(15, 'عمولة مستحقة', 'Commission Payable'),
  exchangeGainLoss(16, 'أرباح/خسائر فروق العملة', 'Exchange Gain/Loss'),
  inputVAT(17, 'ضريبة المدخلات', 'Input VAT'),
  outputVAT(18, 'ضريبة المخرجات', 'Output VAT');

  final int value;
  final String labelAr;
  final String labelEn;

  const AccountConnectType(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;
  String get code => name;

  static AccountConnectType fromValue(int value) {
    return AccountConnectType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown AccountConnectType value: $value'),
    );
  }

  static AccountConnectType? tryFromValue(int value) {
    for (final e in AccountConnectType.values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;

  static AccountConnectType fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid AccountConnectType json: $json');
  }
}
