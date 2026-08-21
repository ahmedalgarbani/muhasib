/// أنواع الحسابات حسب التصنيف المحاسبي المعياري
/// Re-export central definition — source of truth for AccountType

enum AccountType {
  assets(0, 'أصول', 'Assets'),
  liabilities(1, 'خصوم', 'Liabilities'),
  equity(2, 'حقوق ملكية', 'Equity'),
  revenue(3, 'إيرادات', 'Revenue'),
  expenses(4, 'مصروفات', 'Expenses');

  final int value;
  final String labelAr;
  final String labelEn;

  const AccountType(this.value, this.labelAr, this.labelEn);

  String get arabicName => labelAr;
  String get label => labelAr;
  String get code => name;

  static AccountType fromValue(int value) {
    return AccountType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown AccountType value: $value'),
    );
  }

  static AccountType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;

  // Helpers based on NormalBalance — preserved for compatibility
  bool get isDebitNature => this == assets || this == expenses;
  bool get isCreditNature => !isDebitNature;

  static List<AccountType> get debitTypes =>
      values.where((t) => t.isDebitNature).toList();

  static List<AccountType> get creditTypes =>
      values.where((t) => t.isCreditNature).toList();
}

/// الطبيعة الطبيعية للحساب (مدين أو دائن)
enum NormalBalance {
  debit(0, 'مدين', 'Debit'),
  credit(1, 'دائن', 'Credit');

  final int value;
  final String labelAr;
  final String labelEn;

  const NormalBalance(this.value, this.labelAr, this.labelEn);

  String get arabicName => labelAr;
  String get label => labelAr;

  static NormalBalance fromValue(int value) {
    return value == 1 ? NormalBalance.credit : NormalBalance.debit;
  }

  static NormalBalance? tryFromValue(int value) {
    if (value == 0) return debit;
    if (value == 1) return credit;
    return null;
  }

  int toJson() => value;
}
