import 'package:equatable/equatable.dart';

/// كيان حركة صنف واحد - يمثل سجل في stock_movements مع معلومات المنتج والمخزن
class ItemMovementEntity extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final String productCode;
  final String unitName;
  final int warehouseId;
  final String warehouseName;
  final String movementType;
  final double quantity; // موجب = وارد، سالب = منصرف
  final double unitCost;
  final double totalCost;
  final double balanceAfter;
  final String? referenceType;
  final String? referenceNumber;
  final int creationTime; // seconds since epoch
  final String? notes;

  const ItemMovementEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitName,
    required this.warehouseId,
    required this.warehouseName,
    required this.movementType,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.balanceAfter,
    this.referenceType,
    this.referenceNumber,
    required this.creationTime,
    this.notes,
  });

  bool get isInbound => quantity > 0;
  bool get isOutbound => quantity < 0;

  String get directionLabel => isInbound ? 'وارد' : 'منصرف';

  /// تحويل نوع الحركة إلى تسمية عربية مع رقم المستند
  String get documentLabel {
    final num = referenceNumber?.isNotEmpty == true ? referenceNumber! : id.toString();
    switch (movementType) {
      case 'transfer_in':
      case 'transfer_out':
        return 'تحويل مخزني بالرقم: $num';
      case 'initial_stock':
        return 'بضاعة اول المدة بالرقم: $num';
      case 'sale':
      case 'sales_invoice':
        return 'فاتورة مبيعات بالرقم: $num';
      case 'purchase':
      case 'purchase_invoice':
        return 'فاتورة مشتريات بالرقم: $num';
      case 'adjustment':
      case 'inventory_adjustment':
        return 'تسوية مخزنية بالرقم: $num';
      case 'return_sale':
        return 'مرتجع مبيعات بالرقم: $num';
      case 'return_purchase':
        return 'مرتجع مشتريات بالرقم: $num';
      default:
        if (referenceType != null && referenceType!.isNotEmpty) {
          return '$referenceType بالرقم: $num';
        }
        return 'حركة مخزنية بالرقم: $num';
    }
  }

  String get formattedDate {
    final dt = DateTime.fromMillisecondsSinceEpoch(creationTime * 1000);
    final period = dt.hour < 12 ? 'ص' : 'م';
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    return '${dt.year} - ${dt.month} - ${dt.day} - $hour12:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productCode,
        unitName,
        warehouseId,
        warehouseName,
        movementType,
        quantity,
        unitCost,
        totalCost,
        balanceAfter,
        referenceType,
        referenceNumber,
        creationTime,
        notes,
      ];
}
