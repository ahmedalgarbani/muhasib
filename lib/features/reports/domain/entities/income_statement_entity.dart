class IncomeStatementEntity {
  final String categoryCode;
  final String categoryName;
  final List<IncomeStatementLineItem> items;
  final double totalAmount;

  const IncomeStatementEntity({
    required this.categoryCode,
    required this.categoryName,
    required this.items,
    required this.totalAmount,
  });
}

class IncomeStatementLineItem {
  final int accountId;
  final String accountCode;
  final String accountName;
  final double amount;

  const IncomeStatementLineItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.amount,
  });
}

class IncomeStatementSummary {
  final double totalRevenue;
  final double totalCostOfSales;
  final double grossProfit;
  final double totalOperatingExpenses;
  final double operatingIncome;
  final double totalOtherIncome;
  final double totalOtherExpenses;
  final double netIncomeBeforeTax;
  final double taxExpense;
  final double netIncome;

  const IncomeStatementSummary({
    required this.totalRevenue,
    required this.totalCostOfSales,
    required this.grossProfit,
    required this.totalOperatingExpenses,
    required this.operatingIncome,
    required this.totalOtherIncome,
    required this.totalOtherExpenses,
    required this.netIncomeBeforeTax,
    required this.taxExpense,
    required this.netIncome,
  });

  double get grossProfitMargin => totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0;
  double get netProfitMargin => totalRevenue > 0 ? (netIncome / totalRevenue) * 100 : 0;
}
