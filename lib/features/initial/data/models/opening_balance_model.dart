import '../../domain/entities/opening_balance_entity.dart';

class OpeningBalanceModel extends OpeningBalanceEntity {
  const OpeningBalanceModel({
    super.id,
    required super.accountId,
    required super.accountName,
    required super.accountCode,
    required super.debitAmount,
    required super.creditAmount,
    required super.balance,
    super.currencyCode,
    super.exchangeRate,
    super.statement,
    required super.date,
  });

  factory OpeningBalanceModel.fromJson(Map<String, dynamic> json) {
    return OpeningBalanceModel(
      id: json['id'] as int?,
      accountId: json['account_id'] as int,
      accountName: json['account_name'] as String? ?? '',
      accountCode: json['account_code'] as String? ?? '',
      debitAmount: (json['debit_amount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currency_code'] as String?,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble(),
      statement: json['statement'] as String?,
      date: json['date'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['date'] * 1000)
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'account_name': accountName,
      'account_code': accountCode,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'balance': balance,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'statement': statement,
      'date': date.millisecondsSinceEpoch ~/ 1000,
    };
  }

  OpeningBalanceEntity toEntity() => this;
}
