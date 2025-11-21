import 'package:equatable/equatable.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';

class InventoryEntity extends Equatable {
  final int? id;
  final String number;
  final int date;
  final String statement;
  final String? parentNumber;
  final int? parentId;
  final TransferStatus status;
  final int? stockId;
  final InventoryType inventoryType;
  final double? totalDifference;
  final double? totalValue;
  final List<InventoryLineEntity> lines;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const InventoryEntity({
    this.id,
    required this.number,
    required this.date,
    required this.statement,
    this.parentNumber,
    this.parentId,
    this.status = TransferStatus.draft,
    this.stockId,
    this.inventoryType = InventoryType.periodic,
    this.totalDifference = 0.0,
    this.totalValue = 0.0,
    this.lines = const [],
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
        number,
        date,
        statement,
        parentNumber,
        parentId,
        status,
        stockId,
        inventoryType,
        totalDifference,
        totalValue,
        lines,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
      ];
}
