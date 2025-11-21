import 'package:equatable/equatable.dart';

class AccountEntity extends Equatable {
  final int? id;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;
  final int cId;
  final String code;
  final String name;
  final bool isMaster;
  final int? masterId;
  final int? masterCId;
  final int type;
  final int national;
  final String? statement;
  final bool isActive;
  final bool allowUpdateDelete;
  final double balance;
  final double localBalance;

  const AccountEntity({
    this.id,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
    required this.cId,
    required this.code,
    required this.name,
    this.isMaster = false,
    this.masterId,
    this.masterCId,
    required this.type,
    required this.national,
    this.statement,
    this.isActive = true,
    this.allowUpdateDelete = true,
    this.balance = 0.0,
    this.localBalance = 0.0,
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
        cId,
        code,
        name,
        isMaster,
        masterId,
        masterCId,
        type,
        national,
        statement,
        isActive,
        allowUpdateDelete,
        balance,
        localBalance,
      ];

  AccountEntity copyWith({
    int? id,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
    int? cId,
    String? code,
    String? name,
    bool? isMaster,
    int? masterId,
    int? masterCId,
    int? type,
    int? national,
    String? statement,
    bool? isActive,
    bool? allowUpdateDelete,
    double? balance,
    double? localBalance,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      concurrencyStamp: concurrencyStamp ?? this.concurrencyStamp,
      extraProperties: extraProperties ?? this.extraProperties,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      cId: cId ?? this.cId,
      code: code ?? this.code,
      name: name ?? this.name,
      isMaster: isMaster ?? this.isMaster,
      masterId: masterId ?? this.masterId,
      masterCId: masterCId ?? this.masterCId,
      type: type ?? this.type,
      national: national ?? this.national,
      statement: statement ?? this.statement,
      isActive: isActive ?? this.isActive,
      allowUpdateDelete: allowUpdateDelete ?? this.allowUpdateDelete,
      balance: balance ?? this.balance,
      localBalance: localBalance ?? this.localBalance,
    );
  }
}
