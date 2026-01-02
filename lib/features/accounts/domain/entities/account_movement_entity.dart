import 'package:equatable/equatable.dart';

class AccountMovementEntity extends Equatable {
  final int id;
  final int journalEntryId;
  final DateTime entryDate;
  final String description;
  final String reference;
  final double debitAmount;
  final double creditAmount;
  final double balance;

  const AccountMovementEntity({
    required this.id,
    required this.journalEntryId,
    required this.entryDate,
    required this.description,
    required this.reference,
    required this.debitAmount,
    required this.creditAmount,
    required this.balance,
  });

  @override
  List<Object?> get props => [
    id,
    journalEntryId,
    entryDate,
    description,
    reference,
    debitAmount,
    creditAmount,
    balance,
  ];
}

class AccountMovementsSummary extends Equatable {
  final double totalDebit;
  final double totalCredit;
  final double netBalance;
  final int transactionCount;

  const AccountMovementsSummary({
    required this.totalDebit,
    required this.totalCredit,
    required this.netBalance,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [totalDebit, totalCredit, netBalance, transactionCount];
}
