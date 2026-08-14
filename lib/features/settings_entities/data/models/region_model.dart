import 'package:muhasib/features/settings_entities/domain/entities/region_entity.dart';

class RegionModel extends RegionEntity {
  const RegionModel({
    super.id,
    required super.name,
    super.isActive,
    super.country,
    super.code,
    super.parentRegionId,
    super.description,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory RegionModel.fromEntity(RegionEntity entity) {
    return RegionModel(
      id: entity.id,
      name: entity.name,
      isActive: entity.isActive,
      country: entity.country,
      code: entity.code,
      parentRegionId: entity.parentRegionId,
      description: entity.description,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory RegionModel.fromMap(Map<String, dynamic> map) {
    return RegionModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      isActive: (map['is_active'] as int?) == 1,
      country: map['country'] as String?,
      code: map['code'] as String?,
      parentRegionId: map['parent_region_id'] as int?,
      description: map['description'] as String?,
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
      'country': country,
      'code': code,
      'parent_region_id': parentRegionId,
      'description': description,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }
}

