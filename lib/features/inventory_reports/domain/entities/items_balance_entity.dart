import 'package:equatable/equatable.dart';

/// كيان رصيد صنف - يلخص الوارد/المنصرف/الرصيد الحالي
class ItemsBalanceEntity extends Equatable {
  final int productId;
  final String productName;
  final String productCode;
  final String unitName;
  final double currentQuantity; // الرصيد الحالي = الوارد - المنصرف
  final double totalInbound; // إجمالي الوارد
  final double totalOutbound; // إجمالي المنصرف
  final double unitCost; // تكلفة الوحدة (avg_cost أو cost_amount)
  final double totalValue; // current * unitCost
  final int? warehouseId; // null = الكل
  final String? warehouseName;

  const ItemsBalanceEntity({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitName,
    required this.currentQuantity,
    required this.totalInbound,
    required this.totalOutbound,
    required this.unitCost,
    required this.totalValue,
    this.warehouseId,
    this.warehouseName,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productCode,
        unitName,
        currentQuantity,
        totalInbound,
        totalOutbound,
        unitCost,
        totalValue,
        warehouseId,
        warehouseName,
      ];
}
