/// حالات الفاتورة

enum InvoiceStatus {
  draft(0, 'مسودة', 'Draft'),
  open(1, 'مفتوحة', 'Open'),
  approved(2, 'معتمدة', 'Approved'),
  cancelled(3, 'ملغية', 'Cancelled'),
  converted(4, 'محولة', 'Converted');

  final int value;
  final String labelAr;
  final String labelEn;

  const InvoiceStatus(this.value, this.labelAr, this.labelEn);

  String get displayName => labelAr;
  String get label => labelAr;
  String get code => name;

  static InvoiceStatus fromValue(int value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown InvoiceStatus value: $value'),
    );
  }

  static InvoiceStatus? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static InvoiceStatus fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid InvoiceStatus json: $json');
  }

  bool get canEdit => this == draft || this == open;
  bool get canDelete => this == draft;
  bool get canConvert => this == draft || this == open;
  bool get isPosted => this == approved;
}
