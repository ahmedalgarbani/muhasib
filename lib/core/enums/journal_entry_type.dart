/// أنواع القيود المحاسبية والوثائق المرجعية

enum JournalEntryType {
  normal('normal', 'عادي', 'Normal'),
  opening('opening', 'افتتاحي', 'Opening'),
  adjusting('adjusting', 'تسوية', 'Adjusting'),
  closing('closing', 'إقفال', 'Closing'),
  reversing('reversing', 'عكسي', 'Reversing'),
  transfer('transfer', 'تحويل', 'Transfer');

  final String code;
  final String labelAr;
  final String labelEn;

  const JournalEntryType(this.code, this.labelAr, this.labelEn);

  String get label => labelAr;
  String get value => code;

  static JournalEntryType fromCode(String code) {
    return JournalEntryType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => throw ArgumentError('Unknown JournalEntryType code: $code'),
    );
  }

  static JournalEntryType? tryFromCode(String? code) {
    if (code == null) return null;
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  String toJson() => code;
  static JournalEntryType fromJson(dynamic json) {
    if (json is String) return fromCode(json);
    throw ArgumentError('Invalid JournalEntryType json: $json');
  }
}

/// أنواع المستندات المرجعية للدفعات
enum PaymentDocumentType {
  salesInvoice('sales_invoice', 'فاتورة مبيعات', 'Sales Invoice'),
  purchaseInvoice('purchase_invoice', 'فاتورة مشتريات', 'Purchase Invoice'),
  salesReturn('sales_return', 'مرتجع مبيعات', 'Sales Return'),
  purchaseReturn('purchase_return', 'مرتجع مشتريات', 'Purchase Return'),
  receiptVoucher('receipt_voucher', 'سند قبض', 'Receipt Voucher'),
  paymentVoucher('payment_voucher', 'سند صرف', 'Payment Voucher'),
  expense('expense', 'مصروف', 'Expense'),
  refund('refund', 'استرداد', 'Refund'),
  advancePayment('advance_payment', 'دفعة مقدمة', 'Advance Payment'),
  openingBalance('opening_balance', 'رصيد افتتاحي', 'Opening Balance');

  final String code;
  final String labelAr;
  final String labelEn;

  const PaymentDocumentType(this.code, this.labelAr, this.labelEn);

  String get label => labelAr;

  static PaymentDocumentType fromCode(String code) {
    return PaymentDocumentType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => throw ArgumentError('Unknown PaymentDocumentType code: $code'),
    );
  }

  static PaymentDocumentType? tryFromCode(String? code) {
    if (code == null) return null;
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  String toJson() => code;
}
