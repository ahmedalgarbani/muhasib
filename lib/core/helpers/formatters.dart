import 'package:intl/intl.dart';
import 'package:muhasib/core/enums/app_date_format.dart';
import 'package:muhasib/core/services/settings_cache.dart';

class NumberFormatter {
  static NumberFormat get _formatter {
    final decimals = SettingsCache.decimalNoOutput;
    final arabicSeparators = SettingsCache.decimalSeparator == '،';
    final locale =
        (arabicSeparators || SettingsCache.language == 'ar') ? 'ar' : 'en_US';
    if (decimals <= 0) {
      return NumberFormat('#,##0', locale);
    }
    return NumberFormat(
      '#,##0.${'0' * decimals}',
      locale,
    );
  }

  static String formatCurrency(double amount, {String symbol = 'ريال'}) {
    return '${_formatter.format(amount)} $symbol';
  }

  static String formatNumber(double number) {
    return _formatter.format(number);
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

class DateFormatter {
  static String get _datePattern {
    return switch (AppDateFormat.tryFromValue(SettingsCache.dateFormat)) {
      AppDateFormat.yearMonthDay => 'yyyy - MM - dd',
      AppDateFormat.monthDayYear => 'MM - dd - yyyy',
      _ => 'dd - MM - yyyy',
    };
  }

  static String get _timePattern {
    return switch (AppTimeFormat.tryFromValue(SettingsCache.timeFormat)) {
      AppTimeFormat.h24 => 'HH:mm',
      _ => 'hh:mm a',
    };
  }

  static String get _locale =>
      SettingsCache.language == 'en' ? 'en_US' : 'ar';

  static String formatDate(DateTime date) {
    return DateFormat(_datePattern, _locale).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('$_datePattern $_timePattern', _locale).format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return formatDate(date);
    }
  }
}
