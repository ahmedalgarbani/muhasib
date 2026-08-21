/// أنواع تسلسل الترقيم التلقائي — يغطي number_sequence_service.dart:179
/// و invoice_repository_impl.dart:243

enum DocumentSequenceType {
  salesInvoice('sales_invoice', 'INV', 'فاتورة مبيعات'),
  purchaseInvoice('purchase_invoice', 'PINV', 'فاتورة مشتريات'),
  quotation('quotation', 'QT', 'عرض سعر'),
  journalEntry('journal_entry', 'JE', 'قيد يومية'),
  receiptVoucher('receipt_voucher', 'RV', 'سند قبض'),
  paymentVoucher('payment_voucher', 'PV', 'سند صرف'),
  salesReturn('sales_return', 'SRT', 'مرتجع مبيعات'),
  purchaseReturn('purchase_return', 'PRT', 'مرتجع مشتريات'),
  openingBalance('opening_balance', 'OB', 'رصيد افتتاحي'),
  stockTransfer('stock_transfer', 'TR', 'تحويل مخزني'),
  stockAdjustment('stock_adjustment', 'ADJ', 'تسوية مخزنية');

  final String code;
  final String defaultPrefix;
  final String labelAr;

  const DocumentSequenceType(this.code, this.defaultPrefix, this.labelAr);

  String get label => labelAr;

  static DocumentSequenceType fromCode(String code) {
    return DocumentSequenceType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => DocumentSequenceType.salesInvoice,
    );
  }

  static DocumentSequenceType? tryFromCode(String code) {
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  /// للتوافق مع النمط القديم int 1,2,4,5,6 (InvoiceType values)
  static DocumentSequenceType? tryFromInvoiceTypeValue(int value) {
    switch (value) {
      case 1:
        return DocumentSequenceType.salesInvoice;
      case 2:
        return DocumentSequenceType.purchaseInvoice;
      case 3:
        return DocumentSequenceType.quotation;
      case 4:
        return DocumentSequenceType.salesReturn;
      case 5:
        return DocumentSequenceType.purchaseReturn;
      case 6:
        return DocumentSequenceType.salesInvoice; // quickInvoice يشارك تسلسل المبيعات
      default:
        return null;
    }
  }

  String toJson() => code;
  static DocumentSequenceType fromJson(dynamic json) {
    if (json is String) return fromCode(json);
    throw ArgumentError('Invalid DocumentSequenceType json: $json');
  }
}
