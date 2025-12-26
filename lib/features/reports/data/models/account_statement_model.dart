import 'package:muhasib/features/reports/domain/entities/account_statement_entity.dart';

class AccountStatementModel extends AccountStatementEntity {
  const AccountStatementModel({
    required super.transactionId,
    required super.transactionDate,
    required super.description,
    required super.reference,
    required super.debitAmount,
    required super.creditAmount,
    required super.balance,
    required super.transactionType,
  });

  factory AccountStatementModel.fromMap(Map<String, dynamic> map) {
    return AccountStatementModel(
      transactionId: map['transaction_id'] ?? 0,
      transactionDate: DateTime.parse(map['transaction_date'] ?? DateTime.now().toIso8601String()),
      description: map['description'] ?? '',
      reference: map['reference'] ?? '',
      debitAmount: (map['debit_amount'] ?? 0.0).toDouble(),
      creditAmount: (map['credit_amount'] ?? 0.0).toDouble(),
      balance: (map['balance'] ?? 0.0).toDouble(),
      transactionType: map['transaction_type'] ?? 'journal',
    );
  }
}
