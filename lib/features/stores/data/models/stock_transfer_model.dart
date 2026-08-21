import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

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
    super.baseQuantity,
    super.conversionRate,
    super.packaging,
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
      baseQuantity: entity.baseQuantity,
      conversionRate: entity.conversionRate,
      packaging: entity.packaging,
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
      baseQuantity: (map['base_quantity'] as num?)?.toDouble(),
      conversionRate: (map['conversion_rate'] as num?)?.toDouble(),
      packaging: map['packaging'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
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
    // Multi-unit fields
    m['base_quantity'] = baseQuantity ?? effectiveBaseQuantity;
    m['conversion_rate'] = conversionRate ?? 1.0;
    m['packaging'] = packaging ?? 1;
    return m;
  }
}

class StockTransferModel extends StockTransferEntity {
  const StockTransferModel({
    super.id,
    required super.number,
    required super.date,
    required super.statement,
    super.parentNumber,
    super.parentId,
    super.status,
    super.fromStockId,
    super.toStockId,
    super.uNo,
    super.transferType,
    super.totalValue,
    super.lines,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory StockTransferModel.fromEntity(StockTransferEntity entity) {
    return StockTransferModel(
      id: entity.id,
      number: entity.number,
      date: entity.date,
      statement: entity.statement,
      parentNumber: entity.parentNumber,
      parentId: entity.parentId,
      status: entity.status,
      fromStockId: entity.fromStockId,
      toStockId: entity.toStockId,
      uNo: entity.uNo,
      transferType: entity.transferType,
      totalValue: entity.totalValue,
      lines: entity.lines.map((e) => StockTransferLineModel.fromEntity(e)).toList(),
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory StockTransferModel.fromMap(Map<String, dynamic> map, {List<StockTransferLineEntity> lines = const []}) {
    return StockTransferModel(
      id: map['id'] as int?,
      number: map['number'] as String,
      date: map['date'] as int,
      statement: map['statement'] as String,
      parentNumber: map['parent_number'] as String?,
      parentId: map['parent_id'] as int?,
      status: TransferStatus.fromValue(map['status'] as int? ?? 0),
      fromStockId: map['from_stock_id'] as int?,
      toStockId: map['to_stock_id'] as int?,
      uNo: map['u_no'] as String?,
      transferType: TransferType.fromValue(map['transfer_type'] as int? ?? 0),
      totalValue: map['total_value'] as double?,
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
      if (fromStockId != null) 'from_stock_id': fromStockId,
      if (toStockId != null) 'to_stock_id': toStockId,
      if (uNo != null) 'u_no': uNo,
      'transfer_type': transferType.value,
      if (totalValue != null) 'total_value': totalValue,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }

  StockTransferEntity toEntity() => this;
}
