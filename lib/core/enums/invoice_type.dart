/// أنواع الفواتير والمستندات

enum InvoiceType {
  salesInvoice(1, 'فاتورة مبيعات', 'Sales Invoice'),
  purchaseInvoice(2, 'فاتورة مشتريات', 'Purchase Invoice'),
  quotation(3, 'عرض سعر', 'Price Quotation'),
  salesReturn(4, 'مرتجع مبيعات', 'Sales Return'),
  purchaseReturn(5, 'مرتجع مشتريات', 'Purchase Return'),
  quickInvoice(6, 'فاتورة سريعة', 'Quick Invoice');

  final int value;
  final String labelAr;
  final String labelEn;

  const InvoiceType(this.value, this.labelAr, this.labelEn);

  String get displayName => labelAr;
  String get nameAr => labelAr;
  String get nameEn => labelEn;
  String get code => name;
  String get label => labelAr;

  static InvoiceType fromValue(int value) {
    return InvoiceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown InvoiceType value: $value'),
    );
  }

  static InvoiceType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static InvoiceType fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid InvoiceType json: $json');
  }

  bool get isReturn => this == salesReturn || this == purchaseReturn;
  bool get isPurchase => this == purchaseInvoice || this == purchaseReturn;
  bool get isSale => this == salesInvoice || this == salesReturn || this == quickInvoice;
  bool get isQuotation => this == quotation;
}
