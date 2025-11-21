import 'package:muhasib/features/products/domain/entities/product_unit_entity.dart';

class ProductUnitModel extends ProductUnitEntity {
  const ProductUnitModel({
    super.id,
    required super.name,
    required super.short,
    super.conversionFactor = 1.0,
    super.isActive = true,
    super.creatorId,
    super.lastModifierId,
    super.creationTime,
    super.lastModificationTime,
  });

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductUnitModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      short: json['short'] as String,
      conversionFactor: (json['conversion_factor'] as num?)?.toDouble() ?? 1.0,
      isActive: (json['is_active'] as int? ?? 1) == 1,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'short': short,
      'conversion_factor': conversionFactor,
      'is_active': isActive ? 1 : 0,
      'creator_id': creatorId ?? 1,
      'last_modifier_id': lastModifierId ?? 1,
    };
    
    // Omit timestamps if null to use database defaults
    if (creationTime != null) {
      map['creation_time'] = creationTime;
    }
    if (lastModificationTime != null) {
      map['last_modification_time'] = lastModificationTime;
    }
    
    return map;
  }

  factory ProductUnitModel.fromEntity(ProductUnitEntity entity) {
    return ProductUnitModel(
      id: entity.id,
      name: entity.name,
      short: entity.short,
      conversionFactor: entity.conversionFactor,
      isActive: entity.isActive,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }
}
