class TrialBalanceEntity {
  final int accountId;
  final String accountCode;
  final String accountName;
  final double debitBalance;
  final double creditBalance;
  final int accountType; // 1=Assets, 2=Liabilities, 3=Equity, 4=Revenue, 5=Expenses

  const TrialBalanceEntity({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.debitBalance,
    required this.creditBalance,
    required this.accountType,
  });

  double get netBalance => debitBalance - creditBalance;

  bool get isDebit => netBalance > 0;
}

class TrialBalanceSummary {
  final double totalDebit;
  final double totalCredit;
  final double difference;

  const TrialBalanceSummary({
    required this.totalDebit,
    required this.totalCredit,
    required this.difference,
  });

  bool get isBalanced => difference.abs() < 0.01;
}
