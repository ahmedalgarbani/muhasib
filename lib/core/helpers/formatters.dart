import 'package:intl/intl.dart';
import 'package:muhasib/core/services/settings_cache.dart';

class NumberFormatter {
  static NumberFormat get _formatter {
    final decimals = SettingsCache.decimalNoOutput;
    final arabicSeparators = SettingsCache.decimalSeparator == '،';
    final locale = arabicSeparators ? 'ar' : 'en_US';
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
    switch (SettingsCache.dateFormat) {
      case 1:
        return 'yyyy - MM - dd';
      case 2:
        return 'MM - dd - yyyy';
      default:
        return 'dd - MM - yyyy';
    }
  }

  static String get _timePattern {
    return SettingsCache.timeFormat == 1 ? 'HH:mm' : 'hh:mm a';
  }

  static String formatDate(DateTime date) {
    return DateFormat(_datePattern, 'ar').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('$_datePattern $_timePattern', 'ar').format(date);
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
