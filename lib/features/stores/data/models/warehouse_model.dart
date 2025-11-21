import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';

class WarehouseModel extends WarehouseEntity {
  const WarehouseModel({
    super.id,
    required super.name,
    required super.address,
    super.contact,
    super.contactType,
    super.isMainStock,
    super.isActive,
    super.accountId,
    super.managerName,
    super.capacity,
    super.creatorId,
    super.lastModifierId,
    super.concurrencyStamp,
    super.extraProperties,
    super.creationTime,
    super.lastModificationTime,
  });

  factory WarehouseModel.fromEntity(WarehouseEntity entity) {
    return WarehouseModel(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      contact: entity.contact,
      contactType: entity.contactType,
      isMainStock: entity.isMainStock,
      isActive: entity.isActive,
      accountId: entity.accountId,
      managerName: entity.managerName,
      capacity: entity.capacity,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      concurrencyStamp: entity.concurrencyStamp,
      extraProperties: entity.extraProperties,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  factory WarehouseModel.fromMap(Map<String, dynamic> map) {
    return WarehouseModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
      contact: map['contact'] as String?,
      contactType: map['contact_type'] as int?,
      isMainStock: (map['is_main_stock'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      accountId: map['account_id'] as int?,
      managerName: map['manager_name'] as String?,
      capacity: map['capacity'] as double?,
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
      'address': address,
      if (contact != null) 'contact': contact,
      if (contactType != null) 'contact_type': contactType,
      'is_main_stock': isMainStock ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      if (accountId != null) 'account_id': accountId,
      if (managerName != null) 'manager_name': managerName,
      if (capacity != null) 'capacity': capacity,
      if (creatorId != null) 'creator_id': creatorId,
      if (lastModifierId != null) 'last_modifier_id': lastModifierId,
      if (concurrencyStamp != null) 'concurrency_stamp': concurrencyStamp,
      if (extraProperties != null) 'extra_properties': extraProperties,
      if (creationTime != null) 'creation_time': creationTime,
      if (lastModificationTime != null) 'last_modification_time': lastModificationTime,
    };
  }
}
