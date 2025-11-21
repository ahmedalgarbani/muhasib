import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';

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

  StockAdjustmentLineEntity toEntity() => this;
}
