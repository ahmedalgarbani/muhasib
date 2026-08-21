/// فلاتر المدة السريعة — يغطي report_base_page.dart:114

enum QuickDateRange {
  today('today', 'اليوم'),
  week('week', 'الأسبوع'),
  month('month', 'الشهر الحالي'),
  year('year', 'العام الحالي'),
  custom('custom', 'مخصص');

  final String code;
  final String labelAr;
  const QuickDateRange(this.code, this.labelAr);

  String get label => labelAr;

  static QuickDateRange fromCode(String code) {
    return QuickDateRange.values.firstWhere(
      (e) => e.code == code,
      orElse: () => QuickDateRange.month,
    );
  }

  static QuickDateRange? tryFromCode(String? code) {
    if (code == null) return null;
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  String toJson() => code;
}
