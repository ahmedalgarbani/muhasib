/// حالات اعتماد المستندات (عروض الأسعار، الفواتير)

enum ApprovalStatus {
  draft(0, 'مسودة', 'Draft', '#6B7280'),
  pendingApproval(1, 'قيد الاعتماد', 'Pending Approval', '#F59E0B'),
  approved(2, 'معتمد', 'Approved', '#10B981'),
  rejected(3, 'مرفوض', 'Rejected', '#EF4444'),
  expired(4, 'منتهي الصلاحية', 'Expired', '#9CA3AF'),
  converted(5, 'محول لفاتورة', 'Converted', '#8B5CF6');

  final int value;
  final String labelAr;
  final String labelEn;
  final String colorHex;

  const ApprovalStatus(this.value, this.labelAr, this.labelEn, this.colorHex);

  String get label => labelAr;
  String get code => name;

  static ApprovalStatus fromValue(int value) {
    return ApprovalStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown ApprovalStatus value: $value'),
    );
  }

  static ApprovalStatus? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static ApprovalStatus fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid ApprovalStatus json: $json');
  }

  static String getName(int status) => tryFromValue(status)?.labelAr ?? 'غير محدد';
  static String getColor(int status) => tryFromValue(status)?.colorHex ?? '#6B7280';
}
