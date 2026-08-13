import 'package:flutter/material.dart';
import 'package:muhasib/core/services/settings_cache.dart';

/// Helper class for responsive font size calculations.
class ResponsiveText {
  /// Calculates a responsive font size based on screen width,
  /// clamped between lowerLimit (80%) and upperLimit (120%).
  static double getResponsiveFontSize(
    BuildContext context, {
    required double fontSize,
    double lowerLimitFactor = 0.8,
    double upperLimitFactor = 1.2,
  }) {
    final double userScale = SettingsCache.fontScale.clamp(0.8, 1.6);
    final double scaleFactor = getScaleFactor(context) * userScale;
    final double responsiveFontSize = fontSize * scaleFactor;

    final double lowerLimit = fontSize * lowerLimitFactor * userScale;
    final double upperLimit = fontSize * upperLimitFactor * userScale;

    return responsiveFontSize.clamp(lowerLimit, upperLimit);
  }

  /// Calculates the scale factor based on screen breakpoints.
  static double getScaleFactor(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return width / 400;
    } else if (width < 900) {
      return width / 700;
    } else {
      return width / 1000;
    }
  }
}

/// Extension on [TextStyle] for easy inline usage.
/// Example: `AppTextStyles.heading1.responsive(context)`
extension ResponsiveTextStyleX on TextStyle {
  TextStyle responsive(BuildContext context) {
    if (fontSize == null) return this;
    return copyWith(
      fontSize: ResponsiveText.getResponsiveFontSize(
        context,
        fontSize: fontSize!,
      ),
    );
  }
}

/// Wraps a subtree so every `Text` scales responsively with screen width.
///
/// Apply it once at the app root (e.g. via `MaterialApp.builder`) to make all
/// app text responsive. The system accessibility text scale is preserved.
class ResponsiveTextScale extends StatelessWidget {
  const ResponsiveTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double widthFactor = ResponsiveText.getScaleFactor(
      context,
    ).clamp(0.8, 1.2);
    final double systemFactor = mediaQuery.textScaler.scale(1.0);
    final double userFactor = SettingsCache.fontScale.clamp(0.8, 1.6);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(
          widthFactor * systemFactor * userFactor,
        ),
      ),
      child: child,
    );
  }
}
