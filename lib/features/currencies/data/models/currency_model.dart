import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';

class CurrencyModel extends CurrencyEntity {
  const CurrencyModel({
    super.id,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
    required super.name,
    required super.code,
    super.symbol,
    required super.minExchangeRate,
    required super.maxExchangeRate,
    required super.exchangeRate,
    super.isLocalCurrency = false,
    super.isActive = true,
    required super.decimalPlaces,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id'] as int?,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      concurrencyStamp: json['concurrency_stamp'] as String?,
      extraProperties: json['extra_properties'] as String?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
      name: json['name'] as String,
      code: json['code'] as String,
      symbol: json['symbol'] as String?,
      minExchangeRate: (json['min_exchange_rate'] as num).toDouble(),
      maxExchangeRate: (json['max_exchange_rate'] as num).toDouble(),
      exchangeRate: (json['exchange_rate'] as num).toDouble(),
      isLocalCurrency: (json['is_local_currency'] as int) == 1,
      isActive: (json['is_active'] as int) == 1,
      decimalPlaces: json['decimal_places'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId ?? 1,
      'last_modifier_id': lastModifierId ?? 1,
      'concurrency_stamp': concurrencyStamp,
      'extra_properties': extraProperties,
      'creation_time': creationTime,
      'last_modification_time': lastModificationTime,
      'name': name,
      'code': code,
      'symbol': symbol,
      'min_exchange_rate': minExchangeRate,
      'max_exchange_rate': maxExchangeRate,
      'exchange_rate': exchangeRate,
      'is_local_currency': isLocalCurrency ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'decimal_places': decimalPlaces,
    };
  }

  CurrencyEntity toEntity() => CurrencyEntity(
    id: id,
    creatorId: creatorId,
    lastModifierId: lastModifierId,
    concurrencyStamp: concurrencyStamp,
    extraProperties: extraProperties,
    creationTime: creationTime,
    lastModificationTime: lastModificationTime,
    name: name,
    code: code,
    symbol: symbol,
    minExchangeRate: minExchangeRate,
    maxExchangeRate: maxExchangeRate,
    exchangeRate: exchangeRate,
    isLocalCurrency: isLocalCurrency,
    isActive: isActive,
    decimalPlaces: decimalPlaces,
  );

  factory CurrencyModel.fromEntity(CurrencyEntity entity) => CurrencyModel(
    id: entity.id,
    creatorId: entity.creatorId,
    lastModifierId: entity.lastModifierId,
    concurrencyStamp: entity.concurrencyStamp,
    extraProperties: entity.extraProperties,
    creationTime: entity.creationTime,
    lastModificationTime: entity.lastModificationTime,
    name: entity.name,
    code: entity.code,
    symbol: entity.symbol,
    minExchangeRate: entity.minExchangeRate,
    maxExchangeRate: entity.maxExchangeRate,
    exchangeRate: entity.exchangeRate,
    isLocalCurrency: entity.isLocalCurrency,
    isActive: entity.isActive,
    decimalPlaces: entity.decimalPlaces,
  );
}
