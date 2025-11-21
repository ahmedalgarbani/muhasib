import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    super.id,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    required super.creationTime,
    required super.lastModificationTime,
    required super.cId,
    required super.code,
    required super.name,
    super.isMaster,
    super.masterId,
    super.masterCId,
    required super.type,
    required super.national,
    super.statement,
    super.isActive,
    super.allowUpdateDelete,
    super.balance,
    super.localBalance,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int?,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      concurrencyStamp: json['concurrency_stamp'] as String?,
      extraProperties: json['extra_properties'] as String?,
      creationTime: json['creation_time'] as int,
      lastModificationTime: json['last_modification_time'] as int,
      cId: json['c_id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      isMaster: (json['is_master'] as int) == 1,
      masterId: json['master_id'] as int?,
      masterCId: json['master_c_id'] as int?,
      type: json['type'] as int,
      national: json['national'] as int,
      statement: json['statement'] as String?,
      isActive: (json['is_active'] as int) == 1,
      allowUpdateDelete: (json['allow_update_delete'] as int) == 1,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      localBalance: (json['local_balance'] as num?)?.toDouble() ?? 0.0,
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
      'c_id': cId,
      'code': code,
      'name': name,
      'is_master': isMaster ? 1 : 0,
      'master_id': masterId,
      'master_c_id': masterCId,
      'type': type,
      'national': national,
      'statement': statement,
      'is_active': isActive ? 1 : 0,
      'allow_update_delete': allowUpdateDelete ? 1 : 0,
      'balance': balance,
      'local_balance': localBalance,
    };
  }

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
      cId: entity.cId,
      code: entity.code,
      name: entity.name,
      isMaster: entity.isMaster,
      masterId: entity.masterId,
      masterCId: entity.masterCId,
      type: entity.type,
      national: entity.national,
      statement: entity.statement,
      isActive: entity.isActive,
      allowUpdateDelete: entity.allowUpdateDelete,
      balance: entity.balance,
      localBalance: entity.localBalance,
    );
  }

  AccountEntity toEntity() {
    return AccountEntity(
      id: id,
      creatorId: creatorId,
      lastModifierId: lastModifierId,
      concurrencyStamp: concurrencyStamp,
      extraProperties: extraProperties,
      creationTime: creationTime,
      lastModificationTime: lastModificationTime,
      cId: cId,
      code: code,
      name: name,
      isMaster: isMaster,
      masterId: masterId,
      masterCId: masterCId,
      type: type,
      national: national,
      statement: statement,
      isActive: isActive,
      allowUpdateDelete: allowUpdateDelete,
      balance: balance,
      localBalance: localBalance,
    );
  }
}

enum AccountType { assets, liabilities, equity, revenue, expenses }

enum AccountNature { debit, credit }
