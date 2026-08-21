/// أنواع حركات المخزون — مرجع مركزي لجدول stock_movements.movement_type

enum StockMovementType {
  purchase('purchase', 'شراء', 'Purchase'),
  purchaseReversal('purchase_reversal', 'عكس شراء', 'Purchase Reversal'),
  returnPurchase('return_purchase', 'مرتجع مشتريات', 'Purchase Return'),
  purchaseReturnReversal('purchase_return_reversal', 'عكس مرتجع مشتريات', 'Purchase Return Reversal'),
  sale('sale', 'بيع', 'Sale'),
  saleReverse('sale_reverse', 'عكس بيع', 'Sale Reversal'),
  returnSale('return_sale', 'مرتجع مبيعات', 'Sales Return'),
  deleteReturn('delete_return', 'حذف مرتجع', 'Delete Return'),
  initialStock('initial_stock', 'رصيد افتتاحي', 'Initial Stock'),
  inventoryAdjustment('inventory_adjustment', 'تسوية جرد', 'Inventory Adjustment'),
  adjustment('adjustment', 'تسوية', 'Adjustment'),
  transferOut('transfer_out', 'تحويل صادر', 'Transfer Out'),
  transferIn('transfer_in', 'تحويل وارد', 'Transfer In');

  final String code;
  final String labelAr;
  final String labelEn;

  const StockMovementType(this.code, this.labelAr, this.labelEn);

  String get label => labelAr;
  String get value => code;

  static StockMovementType fromCode(String code) {
    return StockMovementType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => throw ArgumentError('Unknown StockMovementType code: $code'),
    );
  }

  static StockMovementType? tryFromCode(String? code) {
    if (code == null) return null;
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  String toJson() => code;
  static StockMovementType fromJson(dynamic json) {
    if (json is String) return fromCode(json);
    throw ArgumentError('Invalid StockMovementType json: $json');
  }

  bool get isInbound =>
      this == purchase ||
      this == returnPurchase ||
      this == transferIn ||
      this == initialStock;

  bool get isOutbound =>
      this == sale ||
      this == transferOut ||
      this == returnSale;
}
