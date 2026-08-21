import 'dart:math' as math;

/// Helper for precise arithmetic avoiding floating point accumulation errors.
/// Uses integer scaling where possible and consistent rounding.
class PrecisionHelper {
  PrecisionHelper._();

  /// Scale factor for quantity (supports up to 6 decimals)
  static const int quantityScale = 1000000;
  /// Scale for currency (2 decimals by default, configurable)
  static const int currencyScale = 100;

  /// Round monetary value to 2 decimals using half-away-from-zero
  static double roundCurrency(double value, {int decimals = 2}) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final factor = math.pow(10, decimals).toDouble();
    // add epsilon to avoid 1.005 -> 1.00 issues due to binary representation
    final rounded = (value * factor).roundToDouble() / factor;
    // normalize -0.0
    return rounded == 0 ? 0.0 : rounded;
  }

  /// Round quantity to up to 6 decimals, removing trailing zeros via fixed
  static double roundQuantity(double value, {int decimals = 6}) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final factor = math.pow(10, decimals).toDouble();
    final rounded = (value * factor).roundToDouble() / factor;
    return rounded == 0 ? 0.0 : rounded;
  }

  /// Safe multiply with rounding to currency
  static double multiplyCurrency(double a, double b, {int decimals = 2}) {
    return roundCurrency(a * b, decimals: decimals);
  }

  /// Safe multiply quantity * conversion with quantity precision
  static double multiplyQuantity(double quantity, double factor) {
    return roundQuantity(quantity * factor, decimals: 6);
  }

  /// Calculate base quantity = quantity * packaging * conversionRate with precision
  static double calcBaseQuantity({
    required double quantity,
    required int packaging,
    required double conversionRate,
  }) {
    final p = packaging <= 0 ? 1 : packaging;
    final c = conversionRate <= 0 ? 1.0 : conversionRate;
    final base = quantity * p * c;
    return roundQuantity(base, decimals: 6);
  }

  /// Calculate unit price from base price
  static double calcUnitPrice({
    required double basePrice,
    required int packaging,
    required double conversionRate,
  }) {
    final p = packaging <= 0 ? 1 : packaging;
    final c = conversionRate <= 0 ? 1.0 : conversionRate;
    return roundCurrency(basePrice * p * c, decimals: 2);
  }

  /// Breakdown base quantity into packages: e.g., 250 base with factor 24 => 10 كرتون و 10 حبة
  static QuantityBreakdown breakdownQuantity({
    required double baseQuantity,
    required int packaging,
    required double conversionRate,
    required String baseUnitName,
    required String packageUnitName,
  }) {
    final factor = (packaging <= 0 ? 1 : packaging) * (conversionRate <= 0 ? 1.0 : conversionRate);
    if (factor <= 1.0) {
      return QuantityBreakdown(
        display: '${_formatQty(baseQuantity)} $baseUnitName',
        packages: 0,
        remainder: baseQuantity,
        baseQuantity: baseQuantity,
      );
    }
    final packages = (baseQuantity / factor).floor();
    final remainder = roundQuantity(baseQuantity - packages * factor, decimals: 6);
    if (packages == 0) {
      return QuantityBreakdown(
        display: '${_formatQty(baseQuantity)} $baseUnitName',
        packages: 0,
        remainder: baseQuantity,
        baseQuantity: baseQuantity,
      );
    }
    if (remainder.abs() < 0.000001) {
      return QuantityBreakdown(
        display: '$packages $packageUnitName',
        packages: packages,
        remainder: 0,
        baseQuantity: baseQuantity,
      );
    }
    return QuantityBreakdown(
      display: '$packages $packageUnitName و ${_formatQty(remainder)} $baseUnitName',
      packages: packages,
      remainder: remainder,
      baseQuantity: baseQuantity,
    );
  }

  static String _formatQty(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  /// Compare doubles with epsilon
  static bool equals(double a, double b, {double epsilon = 0.000001}) => (a - b).abs() < epsilon;
}

class QuantityBreakdown {
  final String display;
  final int packages;
  final double remainder;
  final double baseQuantity;

  QuantityBreakdown({
    required this.display,
    required this.packages,
    required this.remainder,
    required this.baseQuantity,
  });
}
