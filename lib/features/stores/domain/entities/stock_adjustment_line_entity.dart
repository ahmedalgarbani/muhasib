import 'package:equatable/equatable.dart';

class StockAdjustmentLineEntity extends Equatable {
  
  final int? id;
  final int stockSettlementId;
  final int categoryId;
  final String? categoryName;
  final int? categoryGroupId;
  final String? categoryGroupName;
  final int? unitId;
  final String? unitName;
  final int? subUnitId;
  final String? subUnitName;
  final double quantity;
  final double amount;
  final String? reason;
  final String? expiryDate;
  final String? statement;

  const StockAdjustmentLineEntity({
    this.id,
    required this.stockSettlementId,
    required this.categoryId,
    this.categoryName,
    this.categoryGroupId,
    this.categoryGroupName,
    this.unitId,
    this.unitName,
    this.subUnitId,
    this.subUnitName,
    required this.quantity,
    required this.amount,
    this.reason,
    this.expiryDate,
    this.statement,
  });

  @override
  List<Object?> get props => [
        id,
        stockSettlementId,
        categoryId,
        categoryName,
        categoryGroupId,
        categoryGroupName,
        unitId,
        unitName,
        subUnitId,
        subUnitName,
        quantity,
        amount,
        reason,
        expiryDate,
        statement,
      ];

  StockAdjustmentLineEntity copyWith({
    int? id,
    int? stockSettlementId,
    int? categoryId,
    String? categoryName,
    int? categoryGroupId,
    String? categoryGroupName,
    int? unitId,
    String? unitName,
    int? subUnitId,
    String? subUnitName,
    double? quantity,
    double? amount,
    String? reason,
    String? expiryDate,
    String? statement,
  }) {
    return StockAdjustmentLineEntity(
      id: id ?? this.id,
      stockSettlementId: stockSettlementId ?? this.stockSettlementId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryGroupId: categoryGroupId ?? this.categoryGroupId,
      categoryGroupName: categoryGroupName ?? this.categoryGroupName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      subUnitId: subUnitId ?? this.subUnitId,
      subUnitName: subUnitName ?? this.subUnitName,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      expiryDate: expiryDate ?? this.expiryDate,
      statement: statement ?? this.statement,
    );
  }
}
