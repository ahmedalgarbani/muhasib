import 'package:equatable/equatable.dart';

class ProductSubUnitEntity extends Equatable {
  final int? id;
  final int? categoryId; // Product ID
  final int? unitId;
  final int packaging;
  final double conversionRate;
  final bool isMainUnit;
  final bool isActive;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const ProductSubUnitEntity({
    this.id,
    this.categoryId,
    this.unitId,
    required this.packaging,
    this.conversionRate = 1.0,
    this.isMainUnit = false,
    this.isActive = true,
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
        categoryId,
        unitId,
        packaging,
        conversionRate,
        isMainUnit,
        isActive,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}
