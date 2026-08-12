part of 'journal_entry_page.dart';

class JournalEntry {
  final String id;
  final int? accountId;
  final String account;
  final int? currencyId;

  final String currency;
  final double debit;
  final double credit;

  final String notes;

  const JournalEntry({
    required this.id,
    this.accountId,
    required this.account,
    this.currencyId,
    required this.currency,
    required this.debit,
    required this.credit,
    required this.notes,
  });

  JournalEntry copyWith({
    String? id,
    int? accountId,
    String? account,
    int? currencyId,
    String? currency,
    double? debit,
    double? credit,
    String? notes,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      account: account ?? this.account,
      currencyId: currencyId ?? this.currencyId,
      currency: currency ?? this.currency,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      notes: notes ?? this.notes,
    );
  }
}

class JournalHeader {
  final String entryNumber;
  final DateTime entryDate;
  final String description;

  const JournalHeader({
    required this.entryNumber,
    required this.entryDate,
    required this.description,
  });

  JournalHeader copyWith({
    String? entryNumber,
    DateTime? entryDate,
    String? description,
  }) {
    return JournalHeader(
      entryNumber: entryNumber ?? this.entryNumber,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
    );
  }
}

class JournalTotals {
  final double debit;
  final double credit;

  const JournalTotals({required this.debit, required this.credit});

  double get difference => (debit - credit).abs();
  bool get isBalanced => difference < 0.01 && debit > 0;
}

class AppTheme {
  static const primaryColor = AppColors.primary;
  static const secondaryColor = AppColors.indigo600;
  static const greenColor = AppColors.emerald600;
  static const redColor = AppColors.red600;
  static const yellowColor = AppColors.amber600;
}
