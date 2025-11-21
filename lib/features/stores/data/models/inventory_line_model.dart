import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';

class InventoryLineModel extends InventoryLineEntity {
  const InventoryLineModel({
    super.id,
    required super.statement,
    required super.quantity,
    required super.actualQuantity,
    super.difference = 0.0,
    super.costAmount,
    super.categoryId,
    required super.groupId,
    required super.unitId,
    required super.categorySubUnitId,
    super.inventoryId,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory InventoryLineModel.fromEntity(InventoryLineEntity entity) {
    return InventoryLineModel(
      id: entity.id,
      statement: entity.statement,
      quantity: entity.quantity,
      actualQuantity: entity.actualQuantity,
      difference: entity.difference,
      costAmount: entity.costAmount,
      categoryId: entity.categoryId,
      groupId: entity.groupId,
      unitId: entity.unitId,
      categorySubUnitId: entity.categorySubUnitId,
      inventoryId: entity.inventoryId,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory InventoryLineModel.fromMap(Map<String, dynamic> map) {
    return InventoryLineModel(
      id: map['id'] as int?,
      statement: map['statement'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      actualQuantity: (map['actual_quantity'] as num).toDouble(),
      difference: (map['difference'] as num?)?.toDouble() ?? 0.0,
      costAmount: (map['cost_amount'] as num?)?.toDouble(),
      categoryId: map['category_id'] as int?,
      groupId: map['group_id'] as int,
      unitId: map['unit_id'] as int,
      categorySubUnitId: map['category_sub_unit_id'] as int,
      inventoryId: map['inventory_id'] as int?,
      creatorId: map['creator_id'] as int?,
      lastModifierId: map['last_modifier_id'] as int?,
      concurrencyStamp: map['concurrency_stamp'] as String?,
      extraProperties: map['extra_properties'] as String?,
      creationTime: map['creation_time'] as int?,
      lastModificationTime: map['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'statement': statement,
      'quantity': quantity,
      'actual_quantity': actualQuantity,
      'difference': difference,
      if (costAmount != null) 'cost_amount': costAmount,
      if (categoryId != null) 'category_id': categoryId,
      'group_id': groupId,
      'unit_id': unitId,
      'category_sub_unit_id': categorySubUnitId,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }
}
