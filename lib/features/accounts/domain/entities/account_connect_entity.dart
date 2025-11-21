import 'package:equatable/equatable.dart';

class AccountConnectEntity extends Equatable {
  final int? id;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;
  final int? accountConnectType;
  final int? cId;

  const AccountConnectEntity({
    this.id,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
    this.accountConnectType,
    this.cId,
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
        accountConnectType,
        cId,
      ];

  AccountConnectEntity copyWith({
    int? id,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
    int? accountConnectType,
    int? cId,
  }) {
    return AccountConnectEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      concurrencyStamp: concurrencyStamp ?? this.concurrencyStamp,
      extraProperties: extraProperties ?? this.extraProperties,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      accountConnectType: accountConnectType ?? this.accountConnectType,
      cId: cId ?? this.cId,
    );
  }
}
