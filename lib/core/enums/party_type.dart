/// أنواع أطراف التعامل

enum PartyType {
  customer('customer', 'عميل', 'Customer'),
  supplier('supplier', 'مورد', 'Supplier'),
  employee('employee', 'موظف', 'Employee'),
  other('other', 'أخرى', 'Other');

  final String code;
  final String labelAr;
  final String labelEn;

  const PartyType(this.code, this.labelAr, this.labelEn);

  String get label => labelAr;
  String get value => code;

  static PartyType fromCode(String code) {
    return PartyType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => throw ArgumentError('Unknown PartyType code: $code'),
    );
  }

  static PartyType? tryFromCode(String? code) {
    if (code == null) return null;
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  /// Compatibility with int-based legacy (1=customer, 2=supplier)
  static PartyType fromValue(int value) {
    return switch (value) {
      1 => PartyType.customer,
      2 => PartyType.supplier,
      3 => PartyType.employee,
      _ => PartyType.other,
    };
  }

  int toIntValue() => switch (this) {
        PartyType.customer => 1,
        PartyType.supplier => 2,
        PartyType.employee => 3,
        PartyType.other => 0,
      };

  String toJson() => code;
  static PartyType fromJson(dynamic json) {
    if (json is String) return fromCode(json);
    if (json is int) return fromValue(json);
    throw ArgumentError('Invalid PartyType json: $json');
  }
}
