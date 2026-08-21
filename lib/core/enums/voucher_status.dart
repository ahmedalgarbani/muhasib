/// حالات السندات المالية
enum VoucherStatus {
  draft(0, 'مسودة', 'Draft'),
  posted(1, 'مرحلة', 'Posted'),
  cancelled(2, 'ملغية', 'Cancelled');

  final int value;
  final String labelAr;
  final String labelEn;

  const VoucherStatus(this.value, this.labelAr, this.labelEn);

  String get label => labelAr;

  static VoucherStatus fromValue(int value) {
    return VoucherStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown VoucherStatus value: $value'),
    );
  }

  static VoucherStatus? tryFromValue(int? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static VoucherStatus fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid VoucherStatus json: $json');
  }

  bool get isPosted => this == posted;
  bool get canEdit => this == draft;
}
