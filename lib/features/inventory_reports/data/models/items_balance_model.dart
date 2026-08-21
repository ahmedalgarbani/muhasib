import 'package:muhasib/features/inventory_reports/domain/entities/items_balance_entity.dart';

class ItemsBalanceModel extends ItemsBalanceEntity {
  const ItemsBalanceModel({
    required super.productId,
    required super.productName,
    required super.productCode,
    required super.unitName,
    required super.currentQuantity,
    required super.totalInbound,
    required super.totalOutbound,
    required super.unitCost,
    required super.totalValue,
    super.warehouseId,
    super.warehouseName,
  });

  factory ItemsBalanceModel.fromMap(Map<String, dynamic> map) {
    return ItemsBalanceModel(
      productId: map['product_id'] as int,
      productName: map['product_name'] as String? ?? 'غير معروف',
      productCode: map['product_code'] as String? ?? '',
      unitName: map['unit_name'] as String? ?? 'حبة',
      currentQuantity: (map['current_quantity'] as num?)?.toDouble() ?? 0,
      totalInbound: (map['total_inbound'] as num?)?.toDouble() ?? 0,
      totalOutbound: (map['total_outbound'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0,
      totalValue: (map['total_value'] as num?)?.toDouble() ?? 0,
      warehouseId: map['warehouse_id'] as int?,
      warehouseName: map['warehouse_name'] as String?,
    );
  }

  ItemsBalanceEntity toEntity() => this;
}
