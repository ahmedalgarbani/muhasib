import 'package:equatable/equatable.dart';

class CashboxEntity extends Equatable {
  final int? id;
  final String name;
  final bool isActive;
  final bool isMainFund;
  final int? accountId;
  final double? currentBalance;
  final int? currencyId;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const CashboxEntity({
    this.id,
    required this.name,
    this.isActive = true,
    this.isMainFund = false,
    this.accountId,
    this.currentBalance,
    this.currencyId,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  CashboxEntity copyWith({
    int? id,
    String? name,
    bool? isActive,
    bool? isMainFund,
    int? accountId,
    double? currentBalance,
    int? currencyId,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return CashboxEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      isMainFund: isMainFund ?? this.isMainFund,
      accountId: accountId ?? this.accountId,
      currentBalance: currentBalance ?? this.currentBalance,
      currencyId: currencyId ?? this.currencyId,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      concurrencyStamp: concurrencyStamp ?? this.concurrencyStamp,
      extraProperties: extraProperties ?? this.extraProperties,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isActive,
        isMainFund,
        accountId,
        currentBalance,
        currencyId,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}

