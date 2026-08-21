/// حالات الفترات المالية
enum FiscalPeriodStatus {
  open(0, 'مفتوحة', 'Open'),
  closed(1, 'مقفلة', 'Closed'),
  locked(2, 'مقفلة نهائياً', 'Locked');

  final int value;
  final String labelAr;
  final String labelEn;

  const FiscalPeriodStatus(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;

  static FiscalPeriodStatus fromValue(int value) {
    return FiscalPeriodStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown FiscalPeriodStatus value: $value'),
    );
  }

  static FiscalPeriodStatus? tryFromValue(int? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;

  bool get isClosed => this == closed || this == locked;
  bool get isLocked => this == locked;
}

/// Helper to derive status from legacy two fields (status + is_closed)
extension FiscalPeriodStatusX on FiscalPeriodStatus {
  static FiscalPeriodStatus fromLegacy({int? status, int? isClosed}) {
    if (isClosed == 1) return FiscalPeriodStatus.closed;
    if (status == 2) return FiscalPeriodStatus.locked;
    if (status == 1) return FiscalPeriodStatus.closed;
    return FiscalPeriodStatus.open;
  }
}
