import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';

class AccountConnectModel extends AccountConnectEntity {
  const AccountConnectModel({
    super.id,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    required super.creationTime,
    required super.lastModificationTime,
    required super.accountConnectType,
    super.cId,
  });

  factory AccountConnectModel.fromJson(Map<String, dynamic> json) {
    return AccountConnectModel(
      id: json['id'] as int?,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      concurrencyStamp: json['concurrency_stamp'] as String?,
      extraProperties: json['extra_properties'] as String?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
      accountConnectType: json['account_connect_type'] as int?,
      cId: json['c_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'last_modifier_id': lastModifierId,
      'concurrency_stamp': concurrencyStamp,
      'extra_properties': extraProperties,
      'creation_time': creationTime,
      'last_modification_time': lastModificationTime,
      'account_connect_type': accountConnectType,
      'c_id': cId,
    };
  }

  factory AccountConnectModel.fromEntity(AccountConnectEntity entity) {
    return AccountConnectModel(
      id: entity.id,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
      accountConnectType: entity.accountConnectType,
      cId: entity.cId,
    );
  }
  toEntity(AccountConnectModel entity) {
    return AccountConnectEntity(
      id: entity.id,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
      accountConnectType: entity.accountConnectType,
      cId: entity.cId,
    );
  }
}
