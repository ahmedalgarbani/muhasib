/// أنواع بطاقات الدفع
enum PaymentCardType {
  mada('mada', 'مدى', 'Mada'),
  visa('visa', 'فيزا', 'Visa'),
  mastercard('mastercard', 'ماستركارد', 'Mastercard'),
  amex('amex', 'أمكس', 'Amex'),
  other('other', 'أخرى', 'Other');

  final String code;
  final String labelAr;
  final String labelEn;

  const PaymentCardType(this.code, this.labelAr, this.labelEn);

  String get label => labelAr;

  static PaymentCardType fromCode(String code) {
    return PaymentCardType.values.firstWhere(
      (e) => e.code == code.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown PaymentCardType code: $code'),
    );
  }

  static PaymentCardType? tryFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final e in values) {
      if (e.code == code.toLowerCase()) return e;
    }
    return null;
  }

  String toJson() => code;
}
