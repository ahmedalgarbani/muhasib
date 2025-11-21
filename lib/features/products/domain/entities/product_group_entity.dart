import 'package:equatable/equatable.dart';

class ProductGroupEntity extends Equatable {
  final int? id;
  final String name;
  final String? statement;
  final int? parentGroupId;
  final bool isActive;
  final int? creatorId;
  final int? lastModifierId;
  final int? creationTime;
  final int? lastModificationTime;

  const ProductGroupEntity({
    this.id,
    required this.name,
    this.statement,
    this.parentGroupId,
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
        statement,
        parentGroupId,
        isActive,
        creatorId,
        lastModifierId,
        creationTime,
        lastModificationTime,
      ];
}
