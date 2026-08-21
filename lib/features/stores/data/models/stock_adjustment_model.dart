import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

class StockAdjustmentLineModel extends StockAdjustmentLineEntity {
  const StockAdjustmentLineModel({
    super.id,
    required super.categoryId,
    required super.groupId,
    required super.unitId,
    required super.categorySubUnitId,
    required super.quantity,
    required super.statement,
    required super.amount,
    required super.totalAmount,
    super.currencyCode,
    super.exchangeRate,
    required super.currencyId,
    required super.stockId,
    super.stockSettlementId,
    super.expireDate,
    super.reason,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory StockAdjustmentLineModel.fromEntity(StockAdjustmentLineEntity entity) {
    return StockAdjustmentLineModel(
      id: entity.id,
      categoryId: entity.categoryId,
      groupId: entity.groupId,
      unitId: entity.unitId,
      categorySubUnitId: entity.categorySubUnitId,
      quantity: entity.quantity,
      statement: entity.statement,
      amount: entity.amount,
      totalAmount: entity.totalAmount,
      currencyCode: entity.currencyCode,
      exchangeRate: entity.exchangeRate,
      currencyId: entity.currencyId,
      stockId: entity.stockId,
      stockSettlementId: entity.stockSettlementId,
      expireDate: entity.expireDate,
      reason: entity.reason,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory StockAdjustmentLineModel.fromMap(Map<String, dynamic> map) {
    return StockAdjustmentLineModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      groupId: map['group_id'] as int,
      unitId: map['unit_id'] as int,
      categorySubUnitId: map['category_sub_unit_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      statement: map['statement'] as String,
      amount: (map['amount'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String?,
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble(),
      currencyId: map['currency_id'] as int,
      stockId: map['stock_id'] as int,
      stockSettlementId: map['stock_settlement_id'] as int?,
      expireDate: map['expire_date'] as int?,
      reason: map['reason'] as String?,
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
      'category_id': categoryId,
      'group_id': groupId,
      'unit_id': unitId,
      'category_sub_unit_id': categorySubUnitId,
      'quantity': quantity,
      'statement': statement,
      'amount': amount,
      'total_amount': totalAmount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      'currency_id': currencyId,
      'stock_id': stockId,
      if (stockSettlementId != null) 'stock_settlement_id': stockSettlementId,
      if (expireDate != null) 'expire_date': expireDate,
      if (reason != null) 'reason': reason,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }
}

class StockAdjustmentModel extends StockAdjustmentEntity {
  const StockAdjustmentModel({
    super.id,
    required super.number,
    required super.date,
    required super.type,
    super.totalAmount,
    super.currencyCode,
    super.exchangeRate,
    required super.currencyId,
    required super.statement,
    super.parentNumber,
    super.parentId,
    super.status,
    super.stockId,
    super.uNo,
    super.settlementReason,
    super.lines,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory StockAdjustmentModel.fromEntity(StockAdjustmentEntity entity) {
    return StockAdjustmentModel(
      id: entity.id,
      number: entity.number,
      date: entity.date,
      type: entity.type,
      totalAmount: entity.totalAmount,
      currencyCode: entity.currencyCode,
      exchangeRate: entity.exchangeRate,
      currencyId: entity.currencyId,
      statement: entity.statement,
      parentNumber: entity.parentNumber,
      parentId: entity.parentId,
      status: entity.status,
      stockId: entity.stockId,
      uNo: entity.uNo,
      settlementReason: entity.settlementReason,
      lines: entity.lines.map((e) => StockAdjustmentLineModel.fromEntity(e)).toList(),
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory StockAdjustmentModel.fromMap(Map<String, dynamic> map, {List<StockAdjustmentLineEntity> lines = const []}) {
    return StockAdjustmentModel(
      id: map['id'] as int?,
      number: map['number'] as String,
      date: map['date'] as int,
      type: AdjustmentType.fromValue(map['type'] as int),
      totalAmount: map['total_amount'] as double?,
      currencyCode: map['currency_code'] as String?,
      exchangeRate: map['exchange_rate'] as double?,
      currencyId: map['currency_id'] as int,
      statement: map['statement'] as String,
      parentNumber: map['parent_number'] as String?,
      parentId: map['parent_id'] as int?,
      status: TransferStatus.fromValue(map['status'] as int? ?? 0),
      stockId: map['stock_id'] as int?,
      uNo: map['u_no'] as String?,
      settlementReason: map['settlement_reason'] as String?,
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
      'type': type.value,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      'currency_id': currencyId,
      'statement': statement,
      if (parentNumber != null) 'parent_number': parentNumber,
      if (parentId != null) 'parent_id': parentId,
      'status': status.value,
      if (stockId != null) 'stock_id': stockId,
      if (uNo != null) 'u_no': uNo,
      if (settlementReason != null) 'settlement_reason': settlementReason,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }

  StockAdjustmentEntity toEntity() => this;
}
