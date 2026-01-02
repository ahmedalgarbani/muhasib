/// Account types following standard accounting classification
/// أنواع الحسابات حسب التصنيف المحاسبي المعياري
enum AccountType {
  /// Assets - الأصول (طبيعة مدينة)
  assets(0, 'أصول', NormalBalance.debit),
  
  /// Liabilities - الخصوم (طبيعة دائنة)
  liabilities(1, 'خصوم', NormalBalance.credit),
  
  /// Equity - حقوق الملكية (طبيعة دائنة)
  equity(2, 'حقوق ملكية', NormalBalance.credit),
  
  /// Revenue - الإيرادات (طبيعة دائنة)
  revenue(3, 'إيرادات', NormalBalance.credit),
  
  /// Expenses - المصروفات (طبيعة مدينة)
  expenses(4, 'مصروفات', NormalBalance.debit);

  final int value;
  final String arabicName;
  final NormalBalance normalBalance;
  
  const AccountType(this.value, this.arabicName, this.normalBalance);
  
  /// Get AccountType from integer value
  static AccountType fromValue(int value) {
    return AccountType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AccountType.assets,
    );
  }
  
  /// Check if this account type is a debit-nature account
  bool get isDebitNature => normalBalance == NormalBalance.debit;
  
  /// Check if this account type is a credit-nature account
  bool get isCreditNature => normalBalance == NormalBalance.credit;
  
  /// Get all debit-nature account types
  static List<AccountType> get debitTypes => 
      AccountType.values.where((t) => t.isDebitNature).toList();
  
  /// Get all credit-nature account types
  static List<AccountType> get creditTypes => 
      AccountType.values.where((t) => t.isCreditNature).toList();
}

/// Normal balance for accounts
/// الطبيعة الطبيعية للحساب (مدين أو دائن)
enum NormalBalance {
  /// Debit - مدين
  debit(0, 'مدين'),
  
  /// Credit - دائن
  credit(1, 'دائن');

  final int value;
  final String arabicName;
  
  const NormalBalance(this.value, this.arabicName);
  
  static NormalBalance fromValue(int value) {
    return value == 1 ? NormalBalance.credit : NormalBalance.debit;
  }
}
