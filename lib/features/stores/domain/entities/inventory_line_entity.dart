import 'package:equatable/equatable.dart';

class InventoryLineEntity extends Equatable {
  final int? id;
  final int? inventoryId;
  final int? categoryId;
  final int groupId;
  final int unitId;
  final int categorySubUnitId;
  final String statement;
  final double quantity;
  final double actualQuantity;
  final double difference;
  final double? costAmount;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const InventoryLineEntity({
    this.id,
    this.inventoryId,
    this.categoryId,
    required this.groupId,
    required this.unitId,
    required this.categorySubUnitId,
    required this.statement,
    required this.quantity,
    required this.actualQuantity,
    this.difference = 0.0,
    this.costAmount,
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
        inventoryId,
        categoryId,
        groupId,
        unitId,
        categorySubUnitId,
        statement,
        quantity,
        actualQuantity,
        difference,
        costAmount,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];

  InventoryLineEntity copyWith({
    int? id,
    int? inventoryId,
    int? categoryId,
    int? groupId,
    int? unitId,
    int? categorySubUnitId,
    String? statement,
    double? quantity,
    double? actualQuantity,
    double? difference,
    double? costAmount,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return InventoryLineEntity(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      categoryId: categoryId ?? this.categoryId,
      groupId: groupId ?? this.groupId,
      unitId: unitId ?? this.unitId,
      categorySubUnitId: categorySubUnitId ?? this.categorySubUnitId,
      statement: statement ?? this.statement,
      quantity: quantity ?? this.quantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      difference: difference ?? this.difference,
      costAmount: costAmount ?? this.costAmount,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      concurrencyStamp: concurrencyStamp ?? this.concurrencyStamp,
      extraProperties: extraProperties ?? this.extraProperties,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
    );
  }
  // generate toMap mathod 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'category_id': categoryId,
      'group_id': groupId,
      'unit_id': unitId,
      'category_sub_unit_id': categorySubUnitId,
      'statement': statement,
      'quantity': quantity,
      'actual_quantity': actualQuantity,
      'difference': difference,
      'cost_amount': costAmount,
      'creator_id': creatorId,
      'last_modifier_id': lastModifierId,
      'concurrency_stamp': concurrencyStamp,
      'extra_properties': extraProperties,
      'creation_time': creationTime,
      'last_modification_time': lastModificationTime,
    };
  }
}
