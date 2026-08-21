/// حالة سداد الفاتورة — جديد كليًا
/// يغطي: purchase_detail_header.dart:92 و purchases_list_widgets.dart:250 و sale_page_body.dart:198
/// ملاحظة: لا تخلط مع PaymentStatus (للدفعات الموحدة) — هذا خاص بحالة سداد الفاتورة

enum InvoicePaymentStatus {
  unpaid(0, 'غير مدفوعة', 'Unpaid'),
  paid(1, 'مدفوعة', 'Paid'),
  partial(2, 'مدفوعة جزئياً', 'Partially Paid');

  final int value;
  final String labelAr;
  final String labelEn;

  const InvoicePaymentStatus(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;
  String get code => name;

  static InvoicePaymentStatus fromValue(int value) {
    return InvoicePaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown InvoicePaymentStatus value: $value'),
    );
  }

  static InvoicePaymentStatus? tryFromValue(int? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  /// الحساب الصحيح من المبالغ — لا تعتمد على الرقم المخزن وحده
  static InvoicePaymentStatus fromAmounts({
    required double total,
    required double paid,
  }) {
    if (paid <= 0.01) return InvoicePaymentStatus.unpaid;
    if (paid + 0.01 >= total) return InvoicePaymentStatus.paid;
    return InvoicePaymentStatus.partial;
  }

  int toJson() => value;
  static InvoicePaymentStatus fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid InvoicePaymentStatus json: $json');
  }

  bool get isPaid => this == paid;
  bool get isPartial => this == partial;
  bool get isUnpaid => this == unpaid;
}
