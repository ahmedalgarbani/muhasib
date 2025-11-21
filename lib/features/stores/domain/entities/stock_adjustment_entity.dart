import 'package:equatable/equatable.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

class StockAdjustmentLineEntity extends Equatable {
  final int? id;
  final int categoryId;
  final int groupId;
  final int unitId;
  final int categorySubUnitId;
  final double quantity;
  final String statement;
  final double amount;
  final double totalAmount;
  final String? currencyCode;
  final double? exchangeRate;
  final int currencyId;
  final int stockId;
  final int? stockSettlementId;
  final int? expireDate;
  final String? reason;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const StockAdjustmentLineEntity({
    this.id,
    required this.categoryId,
    required this.groupId,
    required this.unitId,
    required this.categorySubUnitId,
    required this.quantity,
    required this.statement,
    required this.amount,
    required this.totalAmount,
    this.currencyCode,
    this.exchangeRate,
    required this.currencyId,
    required this.stockId,
    this.stockSettlementId,
    this.expireDate,
    this.reason,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        groupId,
        unitId,
        categorySubUnitId,
        quantity,
        statement,
        amount,
        totalAmount,
        currencyCode,
        exchangeRate,
        currencyId,
        stockId,
        stockSettlementId,
        expireDate,
        reason,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}

class StockAdjustmentEntity extends Equatable {
  final int? id;
  final String number;
  final int date;
  final AdjustmentType type;
  final double? totalAmount;
  final String? currencyCode;
  final double? exchangeRate;
  final int currencyId;
  final String statement;
  final String? parentNumber;
  final int? parentId;
  final TransferStatus status;
  final int? stockId;
  final String? uNo;
  final String? settlementReason;
  final List<StockAdjustmentLineEntity> lines;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const StockAdjustmentEntity({
    this.id,
    required this.number,
    required this.date,
    required this.type,
    this.totalAmount,
    this.currencyCode,
    this.exchangeRate,
    required this.currencyId,
    required this.statement,
    this.parentNumber,
    this.parentId,
    this.status = TransferStatus.draft,
    this.stockId,
    this.uNo,
    this.settlementReason,
    this.lines = const [],
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  @override
  List<Object?> get props => [
        id,
        number,
        date,
        type,
        totalAmount,
        currencyCode,
        exchangeRate,
        currencyId,
        statement,
        parentNumber,
        parentId,
        status,
        stockId,
        uNo,
        settlementReason,
        lines,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}
