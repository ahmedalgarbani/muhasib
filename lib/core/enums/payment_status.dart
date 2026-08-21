/// حالات الدفع والمستندات المالية

enum PaymentStatus {
  draft(0, 'مسودة', 'Draft'),
  completed(1, 'مكتمل', 'Completed'),
  pending(2, 'قيد الانتظار', 'Pending'),
  bounced(3, 'مرتجع', 'Bounced'),
  cancelled(4, 'ملغي', 'Cancelled'),
  refunded(5, 'مسترد', 'Refunded');

  final int value;
  final String labelAr;
  final String labelEn;

  const PaymentStatus(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;
  String get code => name;

  static PaymentStatus fromValue(int value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown PaymentStatus value: $value'),
    );
  }

  static PaymentStatus? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static PaymentStatus fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid PaymentStatus json: $json');
  }

  static String getName(int status) => tryFromValue(status)?.labelAr ?? 'غير محدد';

  bool get isFinal => this == completed || this == cancelled || this == refunded;
}
