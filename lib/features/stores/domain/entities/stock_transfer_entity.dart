import 'package:equatable/equatable.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

class StockTransferLineEntity extends Equatable {
  final int? id;
  final double quantity;
  final String statement;
  final double? costAmount;
  final int? categoryId;
  final int groupId;
  final int unitId;
  final int categorySubUnitId;
  final int? stockTransferId;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;
  // Multi-unit enhancement
  final double? baseQuantity;
  final double? conversionRate;
  final int? packaging;

  const StockTransferLineEntity({
    this.id,
    required this.quantity,
    required this.statement,
    this.costAmount,
    this.categoryId,
    required this.groupId,
    required this.unitId,
    required this.categorySubUnitId,
    this.stockTransferId,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
    this.baseQuantity,
    this.conversionRate,
    this.packaging,
  });

  double get effectiveBaseQuantity {
    if (baseQuantity != null && baseQuantity! > 0) return baseQuantity!;
    final int pVal = packaging ?? 1;
    final int p = pVal <= 0 ? 1 : pVal;
    final double cVal = conversionRate ?? 1.0;
    final double c = cVal <= 0 ? 1.0 : cVal;
    return quantity * p * c;
  }

  @override
  List<Object?> get props => [
        id,
        quantity,
        statement,
        costAmount,
        categoryId,
        groupId,
        unitId,
        categorySubUnitId,
        stockTransferId,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
        baseQuantity,
        conversionRate,
        packaging,
      ];
}

class StockTransferEntity extends Equatable {
  final int? id;
  final String number;
  final int date;
  final String statement;
  final String? parentNumber;
  final int? parentId;
  final TransferStatus status;
  final int? fromStockId;
  final int? toStockId;
  final String? uNo;
  final TransferType transferType;
  final double? totalValue;
  final List<StockTransferLineEntity> lines;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const StockTransferEntity({
    this.id,
    required this.number,
    required this.date,
    required this.statement,
    this.parentNumber,
    this.parentId,
    this.status = TransferStatus.draft,
    this.fromStockId,
    this.toStockId,
    this.uNo,
    this.transferType = TransferType.regular,
    this.totalValue = 0.0,
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
        statement,
        parentNumber,
        parentId,
        status,
        fromStockId,
        toStockId,
        uNo,
        transferType,
        totalValue,
        lines,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}
