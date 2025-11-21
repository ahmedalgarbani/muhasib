import 'package:muhasib/features/products/domain/entities/product_price_entity.dart';

class ProductPriceModel extends ProductPriceEntity {
  const ProductPriceModel({
    super.id,
    super.categorySubUnitId,
    super.priceLevel = 1,
    super.bidAmount,
    super.bidLocalAmount,
    super.bidCurrencyCode,
    super.bidExchangeRate,
    super.bidCurrencyId,
    super.minQuantity = 1.0,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    return ProductPriceModel(
      id: json['id'] as int?,
      categorySubUnitId: json['category_sub_unit_id'] as int?,
      priceLevel: json['price_level'] as int? ?? 1,
      bidAmount: (json['bid_amount'] as num?)?.toDouble(),
      bidLocalAmount: (json['bid_local_amount'] as num?)?.toDouble(),
      bidCurrencyCode: json['bid_currency_code'] as String?,
      bidExchangeRate: (json['bid_exchange_rate'] as num?)?.toDouble(),
      bidCurrencyId: json['bid_currency_id'] as int?,
      minQuantity: (json['min_quantity'] as num?)?.toDouble() ?? 1.0,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      concurrencyStamp: json['concurrency_stamp'] as String?,
      extraProperties: json['extra_properties'] as String?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'category_sub_unit_id': categorySubUnitId,
      'price_level': priceLevel,
      'bid_amount': bidAmount,
      'bid_local_amount': bidLocalAmount,
      'bid_currency_code': bidCurrencyCode,
      'bid_exchange_rate': bidExchangeRate,
      'bid_currency_id': bidCurrencyId,
      'min_quantity': minQuantity,
      'creator_id': creatorId ?? 1,
      'last_modifier_id': lastModifierId ?? 1,
      'concurrency_stamp': concurrencyStamp,
      'extra_properties': extraProperties,
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

  factory ProductPriceModel.fromEntity(ProductPriceEntity entity) {
    return ProductPriceModel(
      id: entity.id,
      categorySubUnitId: entity.categorySubUnitId,
      priceLevel: entity.priceLevel,
      bidAmount: entity.bidAmount,
      bidLocalAmount: entity.bidLocalAmount,
      bidCurrencyCode: entity.bidCurrencyCode,
      bidExchangeRate: entity.bidExchangeRate,
      bidCurrencyId: entity.bidCurrencyId,
      minQuantity: entity.minQuantity,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }
}
