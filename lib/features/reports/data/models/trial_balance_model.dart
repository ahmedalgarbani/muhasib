import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';

class TrialBalanceModel extends TrialBalanceEntity {
  const TrialBalanceModel({
    required super.accountId,
    required super.accountCode,
    required super.accountName,
    required super.accountType,
    super.openingDebit,
    super.openingCredit,
    super.periodDebit,
    super.periodCredit,
    super.closingDebit,
    super.closingCredit,
  });

  factory TrialBalanceModel.fromMap(Map<String, dynamic> map) {
    return TrialBalanceModel(
      accountId: map['account_id'] ?? 0,
      accountCode: map['account_code'] ?? '',
      accountName: map['account_name'] ?? '',
      accountType: map['account_type'] ?? 0,
      openingDebit: (map['opening_debit'] as num?)?.toDouble() ?? 0.0,
      openingCredit: (map['opening_credit'] as num?)?.toDouble() ?? 0.0,
      periodDebit: (map['period_debit'] as num?)?.toDouble() ?? 0.0,
      periodCredit: (map['period_credit'] as num?)?.toDouble() ?? 0.0,
      closingDebit: (map['closing_debit'] as num?)?.toDouble() ?? 0.0,
      closingCredit: (map['closing_credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Legacy factory for backward compatibility (simple debit/credit totals)
  factory TrialBalanceModel.fromLegacyMap(Map<String, dynamic> map) {
    final debit = (map['debit_balance'] as num?)?.toDouble() ?? 0.0;
    final credit = (map['credit_balance'] as num?)?.toDouble() ?? 0.0;
    return TrialBalanceModel(
      accountId: map['account_id'] ?? 0,
      accountCode: map['account_code'] ?? '',
      accountName: map['account_name'] ?? '',
      accountType: map['account_type'] ?? 0,
      openingDebit: 0.0,
      openingCredit: 0.0,
      periodDebit: debit,
      periodCredit: credit,
      closingDebit: debit,
      closingCredit: credit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'account_code': accountCode,
      'account_name': accountName,
      'account_type': accountType,
      'opening_debit': openingDebit,
      'opening_credit': openingCredit,
      'period_debit': periodDebit,
      'period_credit': periodCredit,
      'closing_debit': closingDebit,
      'closing_credit': closingCredit,
    };
  }
}
