import 'package:equatable/equatable.dart';

class OtherFeeEntity extends Equatable {
  final int? id;
  final String name;
  final bool isActive;
  final int? accountId;
  final int toolType;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const OtherFeeEntity({
    this.id,
    required this.name,
    this.isActive = true,
    this.accountId,
    this.toolType = 0,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  OtherFeeEntity copyWith({
    int? id,
    String? name,
    bool? isActive,
    int? accountId,
    int? toolType,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return OtherFeeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      accountId: accountId ?? this.accountId,
      toolType: toolType ?? this.toolType,
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
        accountId,
        toolType,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}

