/// أنواع الخصم

enum DiscountType {
  percentage(0, 'نسبة مئوية', 'Percentage'),
  fixed(1, 'مبلغ ثابت', 'Fixed Amount');

  // Aliases for backward compatibility
  static const DiscountType amount = percentage;
  static const DiscountType percent = percentage;

  final int value;
  final String labelAr;
  final String labelEn;

  const DiscountType(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;
  String get code => name;

  static DiscountType fromValue(int value) {
    return switch (value) {
      0 => DiscountType.percentage,
      1 => DiscountType.fixed,
      _ => throw ArgumentError('Unknown DiscountType value: $value'),
    };
  }

  static DiscountType? tryFromValue(int value) {
    if (value == 0) return DiscountType.percentage;
    if (value == 1) return DiscountType.fixed;
    return null;
  }

  int toJson() => value;
  static DiscountType fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid DiscountType json: $json');
  }

  bool get isPercentage => value == 0;
  bool get isFixed => value == 1;

  double calculate(double baseAmount, double discountValue) {
    return isPercentage ? baseAmount * (discountValue / 100) : discountValue;
  }
}
