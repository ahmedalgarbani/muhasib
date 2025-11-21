import 'package:equatable/equatable.dart';

class WarehouseEntity extends Equatable {
  final int? id;
  final String name;
  final String address;
  final String? contact;
  final int? contactType;
  final bool isMainStock;
  final bool isActive;
  final int? accountId;
  final String? managerName;
  final double? capacity;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const WarehouseEntity({
    this.id,
    required this.name,
    required this.address,
    this.contact,
    this.contactType,
    this.isMainStock = false,
    this.isActive = true,
    this.accountId,
    this.managerName,
    this.capacity,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        contact,
        contactType,
        isMainStock,
        isActive,
        accountId,
        managerName,
        capacity,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}
