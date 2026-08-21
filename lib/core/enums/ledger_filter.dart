/// فلتر دفتر الأستاذ والحركات — يغطي account_transactions_page.dart:112 و general_ledger_report_page.dart:268

enum LedgerFilter {
  all('الكل'),
  debit('مدين'),
  credit('دائن');

  final String labelAr;
  const LedgerFilter(this.labelAr);

  String get label => labelAr;

  static LedgerFilter fromLabel(String label) {
    switch (label) {
      case 'مدين':
        return LedgerFilter.debit;
      case 'دائن':
        return LedgerFilter.credit;
      default:
        return LedgerFilter.all;
    }
  }

  static LedgerFilter? tryFromLabel(String? label) {
    if (label == null) return null;
    for (final e in values) {
      if (e.labelAr == label) return e;
    }
    return null;
  }

  String toJson() => labelAr;
}
