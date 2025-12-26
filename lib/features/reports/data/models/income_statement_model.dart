import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';

class IncomeStatementModel extends IncomeStatementEntity {
  const IncomeStatementModel({
    required super.categoryCode,
    required super.categoryName,
    required super.items,
    required super.totalAmount,
  });

  factory IncomeStatementModel.fromMap(Map<String, dynamic> map) {
    return IncomeStatementModel(
      categoryCode: map['category_code'] ?? '',
      categoryName: map['category_name'] ?? '',
      items: [],
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
    );
  }
}

class IncomeStatementLineItemModel extends IncomeStatementLineItem {
  const IncomeStatementLineItemModel({
    required super.accountId,
    required super.accountCode,
    required super.accountName,
    required super.amount,
  });

  factory IncomeStatementLineItemModel.fromMap(Map<String, dynamic> map) {
    return IncomeStatementLineItemModel(
      accountId: map['account_id'] ?? 0,
      accountCode: map['account_code'] ?? '',
      accountName: map['account_name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}
