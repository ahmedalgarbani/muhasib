import 'package:equatable/equatable.dart';

class ProductUnitEntity extends Equatable {
  final int? id;
  final String name;
  final String short; // Abbreviation
  final double conversionFactor;
  final bool isActive;
  final int? creatorId;
  final int? lastModifierId;
  final int? creationTime;
  final int? lastModificationTime;

  const ProductUnitEntity({
    this.id,
    required this.name,
    required this.short,
    this.conversionFactor = 1.0,
    this.isActive = true,
    this.creatorId,
    this.lastModifierId,
    this.creationTime,
    this.lastModificationTime,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        short,
        conversionFactor,
        isActive,
        creatorId,
        lastModifierId,
        creationTime,
        lastModificationTime,
      ];
}
