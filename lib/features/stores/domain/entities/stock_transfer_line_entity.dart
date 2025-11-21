import 'package:equatable/equatable.dart';

class StockTransferLineEntity extends Equatable {
  final int? id;
  final int stockTransferId;
  final int categoryId;
  final String? categoryName;
  final int? categoryGroupId;
  final String? categoryGroupName;
  final int? unitId;
  final String? unitName;
  final int? subUnitId;
  final String? subUnitName;
  final double quantity;
  final double cost;
  final double totalAmount;
  final String? statement;

  const StockTransferLineEntity({
    this.id,
    required this.stockTransferId,
    required this.categoryId,
    this.categoryName,
    this.categoryGroupId,
    this.categoryGroupName,
    this.unitId,
    this.unitName,
    this.subUnitId,
    this.subUnitName,
    required this.quantity,
    required this.cost,
    required this.totalAmount,
    this.statement,
  });

  @override
  List<Object?> get props => [
        id,
        stockTransferId,
        categoryId,
        categoryName,
        categoryGroupId,
        categoryGroupName,
        unitId,
        unitName,
        subUnitId,
        subUnitName,
        quantity,
        cost,
        totalAmount,
        statement,
      ];

  StockTransferLineEntity copyWith({
    int? id,
    int? stockTransferId,
    int? categoryId,
    String? categoryName,
    int? categoryGroupId,
    String? categoryGroupName,
    int? unitId,
    String? unitName,
    int? subUnitId,
    String? subUnitName,
    double? quantity,
    double? cost,
    double? totalAmount,
    String? statement,
  }) {
    return StockTransferLineEntity(
      id: id ?? this.id,
      stockTransferId: stockTransferId ?? this.stockTransferId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryGroupId: categoryGroupId ?? this.categoryGroupId,
      categoryGroupName: categoryGroupName ?? this.categoryGroupName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      subUnitId: subUnitId ?? this.subUnitId,
      subUnitName: subUnitName ?? this.subUnitName,
      quantity: quantity ?? this.quantity,
      cost: cost ?? this.cost,
      totalAmount: totalAmount ?? this.totalAmount,
      statement: statement ?? this.statement,
    );
  }
}
