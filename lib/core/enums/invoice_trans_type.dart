/// أنواع معاملات الفاتورة (نقدي / آجل)

enum InvoiceTransType {
  cash(0, 'نقدي', 'Cash'),
  credit(1, 'آجل', 'Credit');

  final int value;
  final String labelAr;
  final String labelEn;

  const InvoiceTransType(this.value, this.labelAr, this.labelEn);

  String get displayName => labelAr;
  String get label => labelAr;
  String get code => name;

  static InvoiceTransType fromValue(int value) {
    return InvoiceTransType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown InvoiceTransType value: $value'),
    );
  }

  static InvoiceTransType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static InvoiceTransType fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid InvoiceTransType json: $json');
  }

  bool get isCash => this == cash;
  bool get isCredit => this == credit;
}
