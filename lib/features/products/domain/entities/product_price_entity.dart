import 'package:equatable/equatable.dart';

class ProductPriceEntity extends Equatable {
  final int? id;
  final int? categorySubUnitId;
  final int priceLevel;
  final double? bidAmount;
  final double? bidLocalAmount;
  final String? bidCurrencyCode;
  final double? bidExchangeRate;
  final int? bidCurrencyId;
  final double? minQuantity;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const ProductPriceEntity({
    this.id,
    this.categorySubUnitId,
    this.priceLevel = 1,
    this.bidAmount,
    this.bidLocalAmount,
    this.bidCurrencyCode,
    this.bidExchangeRate,
    this.bidCurrencyId,
    this.minQuantity = 1.0,
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
        categorySubUnitId,
        priceLevel,
        bidAmount,
        bidLocalAmount,
        bidCurrencyCode,
        bidExchangeRate,
        bidCurrencyId,
        minQuantity,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}
