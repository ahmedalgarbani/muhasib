/// Enhanced Trial Balance Entity with Opening, Period Movements, and Closing Balance
class TrialBalanceEntity {
  final int accountId;
  final String accountCode;
  final String accountName;
  final int accountType; // 1=Assets, 2=Liabilities, 3=Equity, 4=Revenue, 5=Expenses
  
  // Opening Balance (before the selected period)
  final double openingDebit;
  final double openingCredit;
  
  // Period Movements (during the selected period)
  final double periodDebit;
  final double periodCredit;
  
  // Closing Balance (calculated: opening + period movements)
  final double closingDebit;
  final double closingCredit;

  const TrialBalanceEntity({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    this.openingDebit = 0.0,
    this.openingCredit = 0.0,
    this.periodDebit = 0.0,
    this.periodCredit = 0.0,
    this.closingDebit = 0.0,
    this.closingCredit = 0.0,
  });

  // Legacy getters for backward compatibility
  double get debitBalance => closingDebit;
  double get creditBalance => closingCredit;

  // Net balances
  double get openingBalance => openingDebit - openingCredit;
  double get periodBalance => periodDebit - periodCredit;
  double get closingBalance => closingDebit - closingCredit;
  
  // Alternative: Net closing = Opening net + Period net
  double get netBalance => closingDebit - closingCredit;

  bool get isDebit => netBalance > 0;
  
  // Check if account has any activity
  bool get hasActivity => periodDebit > 0 || periodCredit > 0;
}

class TrialBalanceSummary {
  // Opening totals
  final double openingDebit;
  final double openingCredit;
  
  // Period totals
  final double periodDebit;
  final double periodCredit;
  
  // Closing totals
  final double closingDebit;
  final double closingCredit;

  const TrialBalanceSummary({
    this.openingDebit = 0.0,
    this.openingCredit = 0.0,
    this.periodDebit = 0.0,
    this.periodCredit = 0.0,
    this.closingDebit = 0.0,
    this.closingCredit = 0.0,
  });

  // Legacy getters for backward compatibility
  double get totalDebit => closingDebit;
  double get totalCredit => closingCredit;
  double get difference => closingDebit - closingCredit;

  // Detailed differences
  double get openingDifference => openingDebit - openingCredit;
  double get periodDifference => periodDebit - periodCredit;
  double get closingDifference => closingDebit - closingCredit;

  // Balance checks (allowing small rounding tolerance)
  bool get isOpeningBalanced => openingDifference.abs() < 0.01;
  bool get isPeriodBalanced => periodDifference.abs() < 0.01;
  bool get isClosingBalanced => closingDifference.abs() < 0.01;
  bool get isBalanced => isClosingBalanced;
}
