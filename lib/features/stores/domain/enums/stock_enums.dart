// Domain layer enums for the stores feature

enum TransferStatus {
  draft(0),
  pendingApproval(1),
  approved(2),
  inTransit(3),
  completed(4),
  rejected(5),
  cancelled(6);

  final int value;
  const TransferStatus(this.value);

  static TransferStatus fromValue(int value) {
    return TransferStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransferStatus.draft,
    );
  }
}

enum TransferType {
  regular(0),
  returnTransfer(1),
  adjustment(2);

  final int value;
  const TransferType(this.value);

  static TransferType fromValue(int value) {
    return TransferType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransferType.regular,
    );
  }
}

enum InventoryType {
  periodic(0),
  cycle(1),
  spot(2),
  annual(3);

  final int value;
  const InventoryType(this.value);

  static InventoryType fromValue(int value) {
    return InventoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InventoryType.periodic,
    );
  }
}

enum AdjustmentType {
  increase(0),
  decrease(1);

  final int value;
  const AdjustmentType(this.value);

  static AdjustmentType fromValue(int value) {
    return AdjustmentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AdjustmentType.increase,
    );
  }
}

enum AdjustmentReason {
  damage(0),
  expiry(1),
  theft(2),
  error(3),
  found(4),
  other(5);

  final int value;
  const AdjustmentReason(this.value);

  static AdjustmentReason fromValue(int value) {
    return AdjustmentReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AdjustmentReason.other,
    );
  }

  String get displayName {
    switch (this) {
      case AdjustmentReason.damage:
        return 'تالف';
      case AdjustmentReason.expiry:
        return 'منتهي الصلاحية';
      case AdjustmentReason.theft:
        return 'سرقة/فقدان';
      case AdjustmentReason.error:
        return 'خطأ في الجرد';
      case AdjustmentReason.found:
        return 'عثور عليه';
      case AdjustmentReason.other:
        return 'أخرى';
    }
  }
}
