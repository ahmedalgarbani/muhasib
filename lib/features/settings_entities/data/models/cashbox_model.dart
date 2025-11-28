import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';

class CashboxModel extends CashboxEntity {
  const CashboxModel({
    super.id,
    required super.name,
    super.isActive,
    super.isMainFund,
    super.accountId,
    super.currentBalance,
    super.currencyId,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory CashboxModel.fromEntity(CashboxEntity entity) {
    return CashboxModel(
      id: entity.id,
      name: entity.name,
      isActive: entity.isActive,
      isMainFund: entity.isMainFund,
      accountId: entity.accountId,
      currentBalance: entity.currentBalance,
      currencyId: entity.currencyId,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory CashboxModel.fromMap(Map<String, dynamic> map) {
    return CashboxModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      isActive: (map['is_active'] as int?) == 1,
      isMainFund: (map['is_main_fund'] as int?) == 1,
      accountId: map['account_id'] as int?,
      currentBalance: (map['current_balance'] as num?)?.toDouble(),
      currencyId: map['currency_id'] as int?,
      creatorId: map['creator_id'] as int?,
      lastModifierId: map['last_modifier_id'] as int?,
      concurrencyStamp: map['concurrency_stamp'] as String?,
      extraProperties: map['extra_properties'] as String?,
      creationTime: map['creation_time'] as int?,
      lastModificationTime: map['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'is_active': isActive ? 1 : 0,
      'is_main_fund': isMainFund ? 1 : 0,
      if (accountId != null) 'account_id': accountId,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (currencyId != null) 'currency_id': currencyId,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }
}

