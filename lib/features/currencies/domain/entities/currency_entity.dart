import 'package:equatable/equatable.dart';

class CurrencyEntity extends Equatable {
  final int? id;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;
  final String name;
  final String code;
  final String? symbol;
  final double minExchangeRate;
  final double maxExchangeRate;
  final double exchangeRate;
  final bool isLocalCurrency;
  final bool isActive;
  final int decimalPlaces;

  const CurrencyEntity({
    this.id,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
    required this.name,
    required this.code,
    this.symbol,
    required this.minExchangeRate,
    required this.maxExchangeRate,
    required this.exchangeRate,
    this.isLocalCurrency = false,
    this.isActive = true,
    required this.decimalPlaces,
  });

  @override
  List<Object?> get props => [
        id,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
        name,
        code,
        symbol,
        minExchangeRate,
        maxExchangeRate,
        exchangeRate,
        isLocalCurrency,
        isActive,
        decimalPlaces,
      ];

  CurrencyEntity copyWith({
    int? id,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
    String? name,
    String? code,
    String? symbol,
    double? minExchangeRate,
    double? maxExchangeRate,
    double? exchangeRate,
    bool? isLocalCurrency,
    bool? isActive,
    int? decimalPlaces,
  }) {
    return CurrencyEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      concurrencyStamp: concurrencyStamp ?? this.concurrencyStamp,
      extraProperties: extraProperties ?? this.extraProperties,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      name: name ?? this.name,
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      minExchangeRate: minExchangeRate ?? this.minExchangeRate,
      maxExchangeRate: maxExchangeRate ?? this.maxExchangeRate,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isLocalCurrency: isLocalCurrency ?? this.isLocalCurrency,
      isActive: isActive ?? this.isActive,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    );
  }
}
