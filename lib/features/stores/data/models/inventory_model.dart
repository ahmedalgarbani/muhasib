import 'package:muhasib/features/stores/data/models/inventory_line_model.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_entity.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

class InventoryModel extends InventoryEntity {
  const InventoryModel({
    super.id,
    required super.number,
    required super.date,
    required super.statement,
    super.parentNumber,
    super.parentId,
    super.status,
    super.stockId,
    super.inventoryType,
    super.totalDifference,
    super.totalValue,
    super.lines,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory InventoryModel.fromEntity(InventoryEntity entity) {
    return InventoryModel(
      id: entity.id,
      number: entity.number,
      date: entity.date,
      statement: entity.statement,
      parentNumber: entity.parentNumber,
      parentId: entity.parentId,
      status: entity.status,
      stockId: entity.stockId,
      inventoryType: entity.inventoryType,
      totalDifference: entity.totalDifference,
      totalValue: entity.totalValue,
      lines: entity.lines.map((e) => InventoryLineModel.fromEntity(e)).toList(),
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map, {List<InventoryLineEntity> lines = const []}) {
    return InventoryModel(
      id: map['id'] as int?,
      number: map['number'] as String,
      date: map['date'] as int,
      statement: map['statement'] as String,
      parentNumber: map['parent_number'] as String?,
      parentId: map['parent_id'] as int?,
      status: TransferStatus.fromValue(map['status'] as int? ?? 0),
      stockId: map['stock_id'] as int?,
      inventoryType: InventoryType.fromValue(map['inventory_type'] as int? ?? 0),
      totalDifference: (map['total_difference'] as num?)?.toDouble() ?? 0.0,
      totalValue: (map['total_value'] as num?)?.toDouble() ?? 0.0,
      lines: lines,
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
      'number': number,
      'date': date,
      'statement': statement,
      if (parentNumber != null) 'parent_number': parentNumber,
      if (parentId != null) 'parent_id': parentId,
      'status': status.value,
      if (stockId != null) 'stock_id': stockId,
      'inventory_type': inventoryType.value,
      if (totalDifference != null) 'total_difference': totalDifference,
      if (totalValue != null) 'total_value': totalValue,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }

  InventoryEntity toEntity() => this;
}
