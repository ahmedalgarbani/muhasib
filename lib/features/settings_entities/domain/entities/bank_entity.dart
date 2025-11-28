import 'package:equatable/equatable.dart';

class BankEntity extends Equatable {
  final int? id;
  final String name;
  final String contact;
  final int contactType;
  final bool isActive;
  final int? accountId;
  final String? bankCode;
  final String? branchName;
  final String? accountNumber;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const BankEntity({
    this.id,
    required this.name,
    required this.contact,
    required this.contactType,
    this.isActive = true,
    this.accountId,
    this.bankCode,
    this.branchName,
    this.accountNumber,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  BankEntity copyWith({
    int? id,
    String? name,
    String? contact,
    int? contactType,
    bool? isActive,
    int? accountId,
    String? bankCode,
    String? branchName,
    String? accountNumber,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return BankEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      contactType: contactType ?? this.contactType,
      isActive: isActive ?? this.isActive,
      accountId: accountId ?? this.accountId,
      bankCode: bankCode ?? this.bankCode,
      branchName: branchName ?? this.branchName,
      accountNumber: accountNumber ?? this.accountNumber,
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
        contact,
        contactType,
        isActive,
        accountId,
        bankCode,
        branchName,
        accountNumber,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}

