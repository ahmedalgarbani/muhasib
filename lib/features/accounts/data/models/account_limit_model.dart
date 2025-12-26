import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';

class AccountLimitModel extends AccountLimitEntity {
  const AccountLimitModel({
    super.id,
    required super.accountId,
    required super.accountName,
    required super.accountCode,
    required super.currencyId,
    required super.currencyCode,
    required super.debitLimit,
    required super.creditLimit,
    super.currentDebit,
    super.currentCredit,
    super.isActive,
    super.creatorId,
    super.creationTime,
    super.lastModificationTime,
  });

  factory AccountLimitModel.fromMap(Map<String, dynamic> map) {
    return AccountLimitModel(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      accountName: map['account_name'] as String? ?? '',
      accountCode: map['account_code'] as String? ?? '',
      currencyId: map['currency_id'] as int,
      currencyCode: map['currency_code'] as String? ?? 'SAR',
      debitLimit: (map['debit_limit'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentDebit: (map['current_debit'] as num?)?.toDouble() ?? 0.0,
      currentCredit: (map['current_credit'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['is_active'] as int?) == 1,
      creatorId: map['creator_id'] as int?,
      creationTime: map['creation_time'] as int?,
      lastModificationTime: map['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'currency_id': currencyId,
      'debit_limit': debitLimit,
      'credit_limit': creditLimit,
      'current_debit': currentDebit,
      'current_credit': currentCredit,
      'is_active': isActive ? 1 : 0,
      'creator_id': creatorId ?? 1,
      'creation_time': creationTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  factory AccountLimitModel.fromEntity(AccountLimitEntity entity) {
    return AccountLimitModel(
      id: entity.id,
      accountId: entity.accountId,
      accountName: entity.accountName,
      accountCode: entity.accountCode,
      currencyId: entity.currencyId,
      currencyCode: entity.currencyCode,
      debitLimit: entity.debitLimit,
      creditLimit: entity.creditLimit,
      currentDebit: entity.currentDebit,
      currentCredit: entity.currentCredit,
      isActive: entity.isActive,
      creatorId: entity.creatorId,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  AccountLimitEntity toEntity() {
    return AccountLimitEntity(
      id: id,
      accountId: accountId,
      accountName: accountName,
      accountCode: accountCode,
      currencyId: currencyId,
      currencyCode: currencyCode,
      debitLimit: debitLimit,
      creditLimit: creditLimit,
      currentDebit: currentDebit,
      currentCredit: currentCredit,
      isActive: isActive,
      creatorId: creatorId,
      creationTime: creationTime,
      lastModificationTime: lastModificationTime,
    );
  }
}
