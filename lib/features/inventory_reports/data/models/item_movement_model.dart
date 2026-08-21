import 'package:muhasib/features/inventory_reports/domain/entities/item_movement_entity.dart';

class ItemMovementModel extends ItemMovementEntity {
  const ItemMovementModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.productCode,
    required super.unitName,
    required super.warehouseId,
    required super.warehouseName,
    required super.movementType,
    required super.quantity,
    super.originalQuantity,
    super.unitId,
    super.conversionRate,
    super.packaging,
    required super.unitCost,
    required super.totalCost,
    required super.balanceAfter,
    super.referenceType,
    super.referenceNumber,
    required super.creationTime,
    super.notes,
  });

  factory ItemMovementModel.fromMap(Map<String, dynamic> map) {
    return ItemMovementModel(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String? ?? 'غير معروف',
      productCode: map['product_code'] as String? ?? '',
      unitName: map['unit_name'] as String? ?? 'حبة',
      warehouseId: map['warehouse_id'] as int,
      warehouseName: map['warehouse_name'] as String? ?? 'غير محدد',
      movementType: map['movement_type'] as String? ?? 'unknown',
      quantity: (map['quantity'] as num).toDouble(),
      originalQuantity: (map['original_quantity'] as num?)?.toDouble(),
      unitId: map['unit_id'] as int?,
      conversionRate: (map['conversion_rate'] as num?)?.toDouble(),
      packaging: map['packaging'] as int?,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
      balanceAfter: (map['balance_after'] as num?)?.toDouble() ?? 0,
      referenceType: map['reference_type'] as String?,
      referenceNumber: map['reference_number'] as String?,
      creationTime: map['creation_time'] as int? ?? map['trans_date'] as int? ?? 0,
      notes: map['notes'] as String? ?? map['statement'] as String?,
    );
  }

  ItemMovementEntity toEntity() => this;
}
