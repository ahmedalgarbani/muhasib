// Invoice Types Enumeration
// Defines all invoice types supported by the system
enum InvoiceType {
  salesInvoice(1, 'Sales Invoice', 'فاتورة مبيعات'),
  purchaseInvoice(2, 'Purchase Invoice', 'فاتورة مشتريات'),
  quotation(3, 'Price Quotation', 'عرض سعر'),
  salesReturn(4, 'Sales Return', 'مرتجع مبيعات'),
  purchaseReturn(5, 'Purchase Return', 'مرتجع مشتريات'),
  quickInvoice(6, 'Quick Invoice', 'فاتورة سريعة');

  final int value;
  final String nameEn;
  final String nameAr;

  const InvoiceType(this.value, this.nameEn, this.nameAr);

  static InvoiceType fromValue(int value) {
    return InvoiceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InvoiceType.salesInvoice,
    );
  }

  String get displayName => nameAr;

  bool get isReturn => this == salesReturn || this == purchaseReturn;
  bool get isPurchase => this == purchaseInvoice || this == purchaseReturn;
  bool get isSale => this == salesInvoice || this == salesReturn || this == quickInvoice;
  bool get isQuotation => this == quotation;
}

// Invoice Status Enumeration
enum InvoiceStatus {
  draft(0, 'Draft', 'مسودة'),
  open(1, 'Open', 'مفتوحة'),
  approved(2, 'Approved', 'معتمدة'),
  cancelled(3, 'Cancelled', 'ملغية'),
  converted(4, 'Converted', 'محولة'); // For quotations converted to invoices

  final int value;
  final String nameEn;
  final String nameAr;

  const InvoiceStatus(this.value, this.nameEn, this.nameAr);

  static InvoiceStatus fromValue(int value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvoiceStatus.draft,
    );
  }

  String get displayName => nameAr;

  bool get canEdit => this == draft || this == open;
  bool get canDelete => this == draft;
  bool get canConvert => this == draft || this == open; // For quotations
  bool get isPosted => this == approved;
}

// Invoice Transaction Type
enum InvoiceTransType {
  cash(0, 'Cash', 'نقدي'),
  credit(1, 'Credit', 'آجل');

  final int value;
  final String nameEn;
  final String nameAr;

  const InvoiceTransType(this.value, this.nameEn, this.nameAr);

  static InvoiceTransType fromValue(int value) {
    return InvoiceTransType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InvoiceTransType.cash,
    );
  }

  String get displayName => nameAr;
}
