/// نوع عمولة المندوب
enum CommissionType {
  percentage(0, 'نسبة من المبيعات', 'Percentage of Sales'),
  fixed(1, 'مبلغ ثابت لكل فاتورة', 'Fixed per Invoice');

  final int value;
  final String labelAr;
  final String labelEn;

  const CommissionType(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;

  static CommissionType fromValue(int value) {
    return CommissionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown CommissionType value: $value'),
    );
  }

  static CommissionType? tryFromValue(int? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
}

/// حالة عمولة المندوب
enum CommissionStatus {
  pending(0, 'قيد الانتظار', 'Pending'),
  approved(1, 'معتمدة', 'Approved'),
  paid(2, 'مدفوعة', 'Paid'),
  cancelled(3, 'ملغية', 'Cancelled');

  final int value;
  final String labelAr;
  final String labelEn;

  const CommissionStatus(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;

  static CommissionStatus fromValue(int value) {
    return CommissionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown CommissionStatus value: $value'),
    );
  }

  static CommissionStatus? tryFromValue(int? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
}
