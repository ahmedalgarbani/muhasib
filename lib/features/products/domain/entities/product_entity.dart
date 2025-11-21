import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int? id;
  final String name;
  final String statement;
  final String barcodeNo;
  final double? costAmount;
  final double? costLocalAmount;
  final String? costCurrencyCode;
  final double? costExchangeRate;
  final int? costCurrencyId;
  final double? sellAmount;
  final double? sellLocalAmount;
  final double? sellExchangeRate;
  final double quantity;
  final int? groupId;
  final int? unitId;
  final int stockId;
  final String? imagePath;
  final double? minStockLevel;
  final double? maxStockLevel;
  final double? reorderPoint;
  final bool isActive;
  final bool isTaxable;
  final int? taxId;
  final int? expireDate;
  final String? uNo;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const ProductEntity({
    this.id,
    required this.name,
    required this.statement,
    required this.barcodeNo,
    this.costAmount,
    this.costLocalAmount,
    this.costCurrencyCode,
    this.costExchangeRate,
    this.costCurrencyId,
    this.sellAmount,
    this.sellLocalAmount,
    this.sellExchangeRate,
    this.quantity = 0,
    this.groupId,
    this.unitId,
    required this.stockId,
    this.imagePath,
    this.minStockLevel = 0,
    this.maxStockLevel,
    this.reorderPoint,
    this.isActive = true,
    this.isTaxable = true,
    this.taxId,
    this.expireDate,
    this.uNo,
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
        name,
        statement,
        barcodeNo,
        costAmount,
        costLocalAmount,
        costCurrencyCode,
        costExchangeRate,
        costCurrencyId,
        sellAmount,
        sellLocalAmount,
        sellExchangeRate,
        quantity,
        groupId,
        unitId,
        stockId,
        imagePath,
        minStockLevel,
        maxStockLevel,
        reorderPoint,
        isActive,
        isTaxable,
        taxId,
        expireDate,
        uNo,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}
