import 'package:equatable/equatable.dart';

class OpeningBalanceEntity extends Equatable {
  final int? id;
  final int accountId;
  final String accountName;
  final String accountCode;
  final double debitAmount;
  final double creditAmount;
  final double balance;
  final String? currencyCode;
  final double? exchangeRate;
  final String? statement;
  final DateTime date;

  const OpeningBalanceEntity({
    this.id,
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.debitAmount,
    required this.creditAmount,
    required this.balance,
    this.currencyCode,
    this.exchangeRate,
    this.statement,
    required this.date,
  });

  @override
  List<Object?> get props => [
        id,
        accountId,
        accountName,
        accountCode,
        debitAmount,
        creditAmount,
        balance,
        currencyCode,
        exchangeRate,
        statement,
        date,
      ];
}
