import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';

class BankModel extends BankEntity {
  const BankModel({
    super.id,
    required super.name,
    required super.contact,
    required super.contactType,
    super.isActive,
    super.accountId,
    super.bankCode,
    super.branchName,
    super.accountNumber,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory BankModel.fromEntity(BankEntity entity) {
    return BankModel(
      id: entity.id,
      name: entity.name,
      contact: entity.contact,
      contactType: entity.contactType,
      isActive: entity.isActive,
      accountId: entity.accountId,
      bankCode: entity.bankCode,
      branchName: entity.branchName,
      accountNumber: entity.accountNumber,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory BankModel.fromMap(Map<String, dynamic> map) {
    return BankModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      contact: map['contact'] as String? ?? '',
      contactType: map['contact_type'] as int? ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      accountId: map['account_id'] as int?,
      bankCode: map['bank_code'] as String?,
      branchName: map['branch_name'] as String?,
      accountNumber: map['account_number'] as String?,
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
      'contact': contact,
      'contact_type': contactType,
      'is_active': isActive ? 1 : 0,
      'account_id': accountId,
      'bank_code': bankCode,
      'branch_name': branchName,
      'account_number': accountNumber,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }
}

