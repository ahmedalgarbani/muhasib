import 'package:equatable/equatable.dart';

/// Product types
enum ProductType {
  goods,     // 0 - سلعة (تُخزن في المخزون)
  service,   // 1 - خدمة (لا تُخزن)
  consumable // 2 - مستهلكات (تُخزن لكن لا تُتبع بدقة)
}

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
  
  // New fields
  final ProductType productType;
  final bool trackInventory;
  
  // Accounting links
  final int? inventoryAccountId;
  final int? cogsAccountId;
  final int? revenueAccountId;
  final int? purchaseAccountId;
  
  // Soft delete
  final bool isDeleted;
  final int? deletedAt;
  final int? deletedBy;

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
    // New fields
    this.productType = ProductType.goods,
    this.trackInventory = true,
    this.inventoryAccountId,
    this.cogsAccountId,
    this.revenueAccountId,
    this.purchaseAccountId,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  /// Check if this product is a service (no inventory tracking)
  bool get isService => productType == ProductType.service;
  
  /// Check if this product should affect inventory
  bool get affectsInventory => trackInventory && productType != ProductType.service;

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
        productType,
        trackInventory,
        inventoryAccountId,
        cogsAccountId,
        revenueAccountId,
        purchaseAccountId,
        isDeleted,
        deletedAt,
        deletedBy,
      ];
}

