import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';

class ProductSubUnitModel extends ProductSubUnitEntity {
  const ProductSubUnitModel({
    super.id,
    super.categoryId,
    super.unitId,
    required super.packaging,
    super.conversionRate = 1.0,
    super.isMainUnit = false,
    super.isActive = true,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
    super.barcode,
    super.costPrice,
    super.sellPrice,
    super.wholesalePrice,
    super.isDefaultSale = false,
    super.isDefaultPurchase = false,
  });

  factory ProductSubUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductSubUnitModel(
      id: json['id'] as int?,
      categoryId: json['category_id'] as int?,
      unitId: json['unit_id'] as int?,
      packaging: json['packaging'] as int,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 1.0,
      isMainUnit: (json['is_main_unit'] as int? ?? 0) == 1,
      isActive: (json['is_active'] as int? ?? 1) == 1,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      concurrencyStamp: json['concurrency_stamp'] as String?,
      extraProperties: json['extra_properties'] as String?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
      barcode: json['barcode'] as String?,
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      sellPrice: (json['sell_price'] as num?)?.toDouble(),
      wholesalePrice: (json['wholesale_price'] as num?)?.toDouble(),
      isDefaultSale: (json['is_default_sale'] as int? ?? 0) == 1,
      isDefaultPurchase: (json['is_default_purchase'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'category_id': categoryId,
      'unit_id': unitId,
      'packaging': packaging,
      'conversion_rate': conversionRate,
      'is_main_unit': isMainUnit ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'creator_id': creatorId ?? 1,
      'last_modifier_id': lastModifierId ?? 1,
      'concurrency_stamp': concurrencyStamp,
      'extra_properties': extraProperties,
      'barcode': barcode,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'wholesale_price': wholesalePrice,
      'is_default_sale': isDefaultSale ? 1 : 0,
      'is_default_purchase': isDefaultPurchase ? 1 : 0,
    };
    
    // Omit timestamps if null to use database defaults
    if (creationTime != null) {
      map['creation_time'] = creationTime;
    }
    if (lastModificationTime != null) {
      map['last_modification_time'] = lastModificationTime;
    }
    
    return map;
  }

  factory ProductSubUnitModel.fromEntity(ProductSubUnitEntity entity) {
    return ProductSubUnitModel(
      id: entity.id,
      categoryId: entity.categoryId,
      unitId: entity.unitId,
      packaging: entity.packaging,
      conversionRate: entity.conversionRate,
      isMainUnit: entity.isMainUnit,
      isActive: entity.isActive,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
      barcode: entity.barcode,
      costPrice: entity.costPrice,
      sellPrice: entity.sellPrice,
      wholesalePrice: entity.wholesalePrice,
      isDefaultSale: entity.isDefaultSale,
      isDefaultPurchase: entity.isDefaultPurchase,
    );
  }
}
