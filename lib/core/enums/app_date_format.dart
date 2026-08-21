/// صيغ عرض التاريخ والوقت + نوع الشاشة الرئيسية
/// يغطي: formatters.dart:34 و other_settings_page.dart:73,86,107,120

enum AppDateFormat {
  dayMonthYear(0, 'dd - MM - yyyy', 'يوم - شهر - سنة'),
  yearMonthDay(1, 'yyyy - MM - dd', 'سنة - شهر - يوم'),
  monthDayYear(2, 'MM - dd - yyyy', 'شهر - يوم - سنة');

  final int value;
  final String pattern;
  final String labelAr;
  const AppDateFormat(this.value, this.pattern, this.labelAr);

  String get label => labelAr;
  String get code => name;

  static AppDateFormat fromValue(int value) {
    return AppDateFormat.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppDateFormat.dayMonthYear,
    );
  }

  static AppDateFormat? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
  static AppDateFormat fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) return fromValue(int.parse(json));
    throw ArgumentError('Invalid AppDateFormat json: $json');
  }

  static String getPattern(int value) =>
      tryFromValue(value)?.pattern ?? dayMonthYear.pattern;
}

enum AppTimeFormat {
  h12(0, '12 ساعة', 'hh:mm a'),
  h24(1, '24 ساعة', 'HH:mm');

  final int value;
  final String labelAr;
  final String pattern;
  const AppTimeFormat(this.value, this.labelAr, this.pattern);

  String get label => labelAr;

  static AppTimeFormat fromValue(int value) => value == 1 ? h24 : h12;

  static AppTimeFormat? tryFromValue(int value) {
    if (value == 0) return h12;
    if (value == 1) return h24;
    return null;
  }

  int toJson() => value;
}

enum HomeScreenType {
  first(1, 'الأولى'),
  second(2, 'الثانية'),
  third(3, 'الثالثة');

  final int value;
  final String labelAr;
  const HomeScreenType(this.value, this.labelAr);

  String get label => labelAr;

  static HomeScreenType fromValue(int value) {
    return HomeScreenType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HomeScreenType.first,
    );
  }

  static HomeScreenType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  int toJson() => value;
}
