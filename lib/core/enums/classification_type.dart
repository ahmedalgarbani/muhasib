/// تصنيف الحساب (محلي / دولي)
enum ClassificationType {
  local(0, 'محلي', 'Local'),
  international(1, 'دولي', 'International');

  final int value;
  final String labelAr;
  final String labelEn;

  const ClassificationType(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;

  static ClassificationType fromValue(int value) {
    return ClassificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown ClassificationType value: $value'),
    );
  }

  static ClassificationType? tryFromValue(int? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
}
