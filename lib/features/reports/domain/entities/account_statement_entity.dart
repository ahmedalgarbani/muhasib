class AccountStatementEntity {
  final int transactionId;
  final DateTime transactionDate;
  final String description;
  final String reference;
  final double debitAmount;
  final double creditAmount;
  final double balance;
  final String transactionType; // journal, invoice, payment, receipt

  const AccountStatementEntity({
    required this.transactionId,
    required this.transactionDate,
    required this.description,
    required this.reference,
    required this.debitAmount,
    required this.creditAmount,
    required this.balance,
    required this.transactionType,
  });
}

class AccountStatementSummary {
  final int accountId;
  final String accountCode;
  final String accountName;
  final double openingBalance;
  final double totalDebits;
  final double totalCredits;
  final double closingBalance;
  final int transactionCount;
  final DateTime? startDate;
  final DateTime? endDate;

  const AccountStatementSummary({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.openingBalance,
    required this.totalDebits,
    required this.totalCredits,
    required this.closingBalance,
    required this.transactionCount,
    this.startDate,
    this.endDate,
  });
}
