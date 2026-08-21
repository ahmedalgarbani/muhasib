import 'package:muhasib/core/enums/invoice_type.dart';

/// نوع مستند حركة الصنف — يغطي item_movement_entity.dart:75

enum ItemMovementDocType {
  salesInvoice(1, 'فاتورة مبيعات'),
  purchaseInvoice(2, 'فاتورة مشتريات'),
  quotation(3, 'عرض سعر'),
  salesReturn(4, 'مرتجع مبيعات'),
  purchaseReturn(5, 'مرتجع مشتريات'),
  stockTransfer(6, 'تحويل مخزني'),
  stockCount(7, 'جرد مخزني');

  final int value;
  final String labelAr;

  const ItemMovementDocType(this.value, this.labelAr);

  String get label => labelAr;
  String get code => name;

  static ItemMovementDocType fromValue(int value) {
    return ItemMovementDocType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown ItemMovementDocType value: $value'),
    );
  }

  static ItemMovementDocType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static ItemMovementDocType fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid ItemMovementDocType json: $json');
  }

  /// يطابق InvoiceType عند الإمكان
  InvoiceType? toInvoiceType() {
    switch (this) {
      case ItemMovementDocType.salesInvoice:
        return InvoiceType.salesInvoice;
      case ItemMovementDocType.purchaseInvoice:
        return InvoiceType.purchaseInvoice;
      case ItemMovementDocType.quotation:
        return InvoiceType.quotation;
      case ItemMovementDocType.salesReturn:
        return InvoiceType.salesReturn;
      case ItemMovementDocType.purchaseReturn:
        return InvoiceType.purchaseReturn;
      case ItemMovementDocType.stockTransfer:
      case ItemMovementDocType.stockCount:
        return null;
    }
  }
}
