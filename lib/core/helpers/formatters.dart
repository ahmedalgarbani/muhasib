import 'package:intl/intl.dart';

class NumberFormatter {
  static String formatCurrency(double amount, {String symbol = 'ريال'}) {
    final formatter = NumberFormat('#,##0', 'ar');
    return '${formatter.format(amount)} $symbol';
  }

  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.##', 'ar');
    return formatter.format(number);
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm', 'ar').format(date);
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
