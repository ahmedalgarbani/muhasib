import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';

class StockTransferLineModel extends StockTransferLineEntity {
  const StockTransferLineModel({
    super.id,
    required super.quantity,
    required super.statement,
    super.costAmount,
    super.categoryId,
    required super.groupId,
    required super.unitId,
    required super.categorySubUnitId,
    super.stockTransferId,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory StockTransferLineModel.fromEntity(StockTransferLineEntity entity) {
    return StockTransferLineModel(
      id: entity.id,
      quantity: entity.quantity,
      statement: entity.statement,
      costAmount: entity.costAmount,
      categoryId: entity.categoryId,
      groupId: entity.groupId,
      unitId: entity.unitId,
      categorySubUnitId: entity.categorySubUnitId,
      stockTransferId: entity.stockTransferId,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory StockTransferLineModel.fromMap(Map<String, dynamic> map) {
    return StockTransferLineModel(
      id: map['id'] as int?,
      quantity: (map['quantity'] as num).toDouble(),
      statement: map['statement'] as String,
      costAmount: (map['cost_amount'] as num?)?.toDouble(),
      categoryId: map['category_id'] as int?,
      groupId: map['group_id'] as int,
      unitId: map['unit_id'] as int,
      categorySubUnitId: map['category_sub_unit_id'] as int,
      stockTransferId: map['stock_transfer_id'] as int?,
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
      'quantity': quantity,
      'statement': statement,
      if (costAmount != null) 'cost_amount': costAmount,
      if (categoryId != null) 'category_id': categoryId,
      'group_id': groupId,
      'unit_id': unitId,
      'category_sub_unit_id': categorySubUnitId,
      if (stockTransferId != null) 'stock_transfer_id': stockTransferId,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }
}
