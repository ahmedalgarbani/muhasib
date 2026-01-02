import 'package:equatable/equatable.dart';

class RegionEntity extends Equatable {
  final int? id;
  final String name;
  final bool isActive;
  final String? country;
  final String? code;
  final int? parentRegionId;
  final String? description;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const RegionEntity({
    this.id,
    required this.name,
    this.isActive = true,
    this.country,
    this.code,
    this.parentRegionId,
    this.description,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  RegionEntity copyWith({
    int? id,
    String? name,
    bool? isActive,
    String? country,
    String? code,
    int? parentRegionId,
    String? description,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return RegionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      country: country ?? this.country,
      code: code ?? this.code,
      parentRegionId: parentRegionId ?? this.parentRegionId,
      description: description ?? this.description,
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
        country,
        code,
        parentRegionId,
        description,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}

