import 'package:equatable/equatable.dart';

class ProductSubUnitEntity extends Equatable {
  final int? id;
  final int? categoryId; // Product ID
  final int? unitId;
  final int packaging;
  final double conversionRate;
  final bool isMainUnit;
  final bool isActive;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;
  // Multi-unit enhancement (008)
  final String? barcode;
  final double? costPrice;
  final double? sellPrice;
  final double? wholesalePrice;
  final bool isDefaultSale;
  final bool isDefaultPurchase;

  const ProductSubUnitEntity({
    this.id,
    this.categoryId,
    this.unitId,
    required this.packaging,
    this.conversionRate = 1.0,
    this.isMainUnit = false,
    this.isActive = true,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
    this.barcode,
    this.costPrice,
    this.sellPrice,
    this.wholesalePrice,
    this.isDefaultSale = false,
    this.isDefaultPurchase = false,
  });

  /// معامل التحويل الإجمالي للوحدة الأساسية: packaging * conversionRate
  double get totalConversionFactor {
    final p = packaging <= 0 ? 1 : packaging;
    final c = conversionRate <= 0 ? 1.0 : conversionRate;
    return p * c;
  }

  /// يحتوي على باركود خاص
  bool get hasBarcode => barcode != null && barcode!.trim().isNotEmpty;

  /// نسخ مع تعديل
  ProductSubUnitEntity copyWith({
    int? id,
    int? categoryId,
    int? unitId,
    int? packaging,
    double? conversionRate,
    bool? isMainUnit,
    bool? isActive,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
    String? barcode,
    double? costPrice,
    double? sellPrice,
    double? wholesalePrice,
    bool? isDefaultSale,
    bool? isDefaultPurchase,
  }) {
    return ProductSubUnitEntity(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      packaging: packaging ?? this.packaging,
      conversionRate: conversionRate ?? this.conversionRate,
      isMainUnit: isMainUnit ?? this.isMainUnit,
      isActive: isActive ?? this.isActive,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      concurrencyStamp: concurrencyStamp ?? this.concurrencyStamp,
      extraProperties: extraProperties ?? this.extraProperties,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      isDefaultSale: isDefaultSale ?? this.isDefaultSale,
      isDefaultPurchase: isDefaultPurchase ?? this.isDefaultPurchase,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        unitId,
        packaging,
        conversionRate,
        isMainUnit,
        isActive,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
        barcode,
        costPrice,
        sellPrice,
        wholesalePrice,
        isDefaultSale,
        isDefaultPurchase,
      ];
}
