import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';

class IncomeStatementModel extends IncomeStatementEntity {
  const IncomeStatementModel({
    required super.categoryCode,
    required super.categoryName,
    required super.items,
    required super.totalAmount,
    super.previousPeriodTotal,
  });

  factory IncomeStatementModel.fromMap(Map<String, dynamic> map) {
    return IncomeStatementModel(
      categoryCode: map['category_code'] ?? '',
      categoryName: map['category_name'] ?? '',
      items: [],
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      previousPeriodTotal: (map['previous_period_total'] as num?)?.toDouble(),
    );
  }

  IncomeStatementModel copyWith({
    String? categoryCode,
    String? categoryName,
    List<IncomeStatementLineItem>? items,
    double? totalAmount,
    double? previousPeriodTotal,
  }) {
    return IncomeStatementModel(
      categoryCode: categoryCode ?? this.categoryCode,
      categoryName: categoryName ?? this.categoryName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      previousPeriodTotal: previousPeriodTotal ?? this.previousPeriodTotal,
    );
  }
}

class IncomeStatementLineItemModel extends IncomeStatementLineItem {
  const IncomeStatementLineItemModel({
    required super.accountId,
    required super.accountCode,
    required super.accountName,
    required super.amount,
    super.previousPeriodAmount,
  });

  factory IncomeStatementLineItemModel.fromMap(Map<String, dynamic> map) {
    return IncomeStatementLineItemModel(
      accountId: map['account_id'] ?? 0,
      accountCode: map['account_code'] ?? '',
      accountName: map['account_name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      previousPeriodAmount: (map['previous_amount'] as num?)?.toDouble(),
    );
  }

  IncomeStatementLineItemModel copyWith({
    int? accountId,
    String? accountCode,
    String? accountName,
    double? amount,
    double? previousPeriodAmount,
  }) {
    return IncomeStatementLineItemModel(
      accountId: accountId ?? this.accountId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      previousPeriodAmount: previousPeriodAmount ?? this.previousPeriodAmount,
    );
  }
}
