/// مستويات الأسعار
enum PriceLevel {
  retail(1, 'سعر التجزئة', 'Retail'),
  wholesale(2, 'سعر الجملة', 'Wholesale'),
  special(3, 'سعر خاص', 'Special'),
  distributor(4, 'سعر الموزع', 'Distributor');

  final int value;
  final String labelAr;
  final String labelEn;

  const PriceLevel(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;

  static PriceLevel fromValue(int value) {
    return PriceLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown PriceLevel value: $value'),
    );
  }

  static PriceLevel? tryFromValue(int? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static PriceLevel fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid PriceLevel json: $json');
  }
}
