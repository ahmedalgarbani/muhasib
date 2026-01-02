class IncomeStatementEntity {
  final String categoryCode;
  final String categoryName;
  final List<IncomeStatementLineItem> items;
  final double totalAmount;
  
  // Period comparison (optional)
  final double? previousPeriodTotal;

  const IncomeStatementEntity({
    required this.categoryCode,
    required this.categoryName,
    required this.items,
    required this.totalAmount,
    this.previousPeriodTotal,
  });

  /// Calculate percentage change from previous period
  double? get percentageChange {
    if (previousPeriodTotal == null || previousPeriodTotal == 0) return null;
    return ((totalAmount - previousPeriodTotal!) / previousPeriodTotal!.abs()) * 100;
  }

  /// Check if improved compared to previous period
  /// For revenue: increase is improvement
  /// For expenses: decrease is improvement
  bool? get isImproved {
    if (percentageChange == null) return null;
    // Revenue categories (code starts with 4)
    if (categoryCode.startsWith('4')) {
      return percentageChange! > 0;
    }
    // Expense categories
    return percentageChange! < 0;
  }
}

class IncomeStatementLineItem {
  final int accountId;
  final String accountCode;
  final String accountName;
  final double amount;
  final double? previousPeriodAmount;

  const IncomeStatementLineItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.amount,
    this.previousPeriodAmount,
  });

  double? get percentageChange {
    if (previousPeriodAmount == null || previousPeriodAmount == 0) return null;
    return ((amount - previousPeriodAmount!) / previousPeriodAmount!.abs()) * 100;
  }
}

class IncomeStatementSummary {
  // Current Period
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

  // Previous Period (for comparison)
  final double? previousTotalRevenue;
  final double? previousNetIncome;

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
    this.previousTotalRevenue,
    this.previousNetIncome,
  });

  // Profit margins
  double get grossProfitMargin => totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0;
  double get operatingProfitMargin => totalRevenue > 0 ? (operatingIncome / totalRevenue) * 100 : 0;
  double get netProfitMargin => totalRevenue > 0 ? (netIncome / totalRevenue) * 100 : 0;

  // Expense ratios
  double get costOfSalesRatio => totalRevenue > 0 ? (totalCostOfSales / totalRevenue) * 100 : 0;
  double get operatingExpenseRatio => totalRevenue > 0 ? (totalOperatingExpenses / totalRevenue) * 100 : 0;

  // Period comparison
  double? get revenueGrowth {
    if (previousTotalRevenue == null || previousTotalRevenue == 0) return null;
    return ((totalRevenue - previousTotalRevenue!) / previousTotalRevenue!) * 100;
  }

  double? get netIncomeGrowth {
    if (previousNetIncome == null || previousNetIncome == 0) return null;
    return ((netIncome - previousNetIncome!) / previousNetIncome!.abs()) * 100;
  }

  // Check if profitable
  bool get isProfitable => netIncome > 0;
  
  // Check if improved vs previous period
  bool? get isImproved {
    if (previousNetIncome == null) return null;
    return netIncome > previousNetIncome!;
  }
}
