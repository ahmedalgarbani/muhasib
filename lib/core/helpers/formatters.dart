import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/enums/app_date_format.dart';
import 'package:muhasib/core/services/settings_cache.dart';

class NumberFormatter {
  static NumberFormat get _formatter {
    final decimals = SettingsCache.decimalNoOutput;
    final locale = SettingsCache.language == 'en' ? 'en_US' : 'ar';
    if (decimals <= 0) {
      return NumberFormat('#,##0', locale);
    }
    return NumberFormat(
      '#,##0.${'0' * decimals}',
      locale,
    );
  }

  /// Replaces the locale's default group/decimal marks with the separators
  /// configured in settings.
  static String _applySeparators(String value) {
    final group = SettingsCache.thousandsSeparator;
    final decimal = SettingsCache.decimalSeparator;
    final result = value
        .replaceAll(',', '\u0000')
        .replaceAll('٬', '\u0000')
        .replaceAll('.', '\u0001')
        .replaceAll('٫', '\u0001')
        .replaceAll('،', '\u0001');
    return result
        .replaceAll('\u0000', group)
        .replaceAll('\u0001', decimal);
  }

  static String formatCurrency(double amount, {String? symbol}) {
    final resolvedSymbol = symbol ?? SettingsCache.defaultCurrencySymbol;
    return '${formatNumber(amount)} $resolvedSymbol';
  }

  static String formatNumber(double number) {
    return _applySeparators(_formatter.format(number));
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

/// Limits numeric input to digits, one decimal point, and at most
/// `decimalNoInput` fraction digits (a live setting).
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({int? maxDecimals})
      : maxDecimals = maxDecimals ?? SettingsCache.decimalNoInput;

  final int maxDecimals;

  static final RegExp _allowed = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!_allowed.hasMatch(text)) return oldValue;
    final dotIndex = text.indexOf('.');
    if (dotIndex != -1 && text.length - dotIndex - 1 > maxDecimals) {
      return oldValue;
    }
    return newValue;
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
