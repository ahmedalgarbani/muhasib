/// طرق الدفع الموحدة — بديل لـ class PaymentMethod القديم

enum PaymentMethod {
  cash(0, 'نقدي', 'Cash', false, false),
  credit(1, 'آجل', 'Credit', false, false),
  bankTransfer(2, 'حوالة بنكية', 'Bank Transfer', true, true),
  check(3, 'شيك', 'Check', true, true),
  card(4, 'بطاقة', 'Card', true, true);

  final int value;
  final String labelAr;
  final String labelEn;
  final bool requiresBank;
  final bool requiresReference;

  const PaymentMethod(
    this.value,
    this.labelAr,
    this.labelEn,
    this.requiresBank,
    this.requiresReference,
  );

  String get label => labelAr;
  String get code => name;
  String get displayName => labelAr;

  static PaymentMethod fromValue(int value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown PaymentMethod value: $value'),
    );
  }

  static PaymentMethod? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static PaymentMethod fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid PaymentMethod json: $json');
  }

  bool get isImmediate => this == cash || this == card;
  bool get isDeferred => this == credit || this == check;

  static String getName(int method) => tryFromValue(method)?.labelAr ?? 'غير محدد';
}
