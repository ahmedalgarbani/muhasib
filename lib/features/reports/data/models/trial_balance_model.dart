import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';

class TrialBalanceModel extends TrialBalanceEntity {
  const TrialBalanceModel({
    required super.accountId,
    required super.accountCode,
    required super.accountName,
    required super.debitBalance,
    required super.creditBalance,
    required super.accountType,
  });

  factory TrialBalanceModel.fromMap(Map<String, dynamic> map) {
    return TrialBalanceModel(
      accountId: map['account_id'] ?? 0,
      accountCode: map['account_code'] ?? '',
      accountName: map['account_name'] ?? '',
      debitBalance: (map['debit_balance'] ?? 0.0).toDouble(),
      creditBalance: (map['credit_balance'] ?? 0.0).toDouble(),
      accountType: map['account_type'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'account_code': accountCode,
      'account_name': accountName,
      'debit_balance': debitBalance,
      'credit_balance': creditBalance,
      'account_type': accountType,
    };
  }
}
