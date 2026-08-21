import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

import 'package:muhasib/core/constant/app_constant.dart';

/// Reusable Card Container with unified border radius, background, border, and elevation.
class CustomCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? color;
  final Color? borderColor;
  final double elevation;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final bool borderOnForeground;
  final bool semanticContainer;

  const CustomCardContainer({
    super.key,
    required this.child,
    this.padding = AppConstant.defaultPadding,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.onTap,
    this.backgroundColor,
    this.color,
    this.borderColor,
    this.elevation = 0,
    this.shape,
    this.clipBehavior = Clip.none,
    this.shadowColor,
    this.surfaceTintColor,
    this.borderOnForeground = true,
    this.semanticContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    final roundedShape = shape is RoundedRectangleBorder
        ? shape! as RoundedRectangleBorder
        : null;
    final borderRadius =
        roundedShape?.borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final BorderRadius inkBorderRadius = borderRadius is BorderRadius
        ? borderRadius
        : BorderRadius.circular(AppRadius.lg);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ?? color ?? Theme.of(context).colorScheme.surface,
        borderRadius: inkBorderRadius,
        border: roundedShape?.side != BorderSide.none
            ? Border.fromBorderSide(
                roundedShape?.side ??
                    BorderSide(
                      color: borderColor ?? Theme.of(context).dividerColor,
                      width: 1,
                    ),
              )
            : Border.all(
                color: borderColor ?? Theme.of(context).dividerColor,
                width: 1,
              ),
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.2 : 0.04 * elevation,
              ),
              blurRadius: 8 * elevation,
              offset: Offset(0, 2 * elevation),
            )
          else if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );

    final clippedContent = clipBehavior == Clip.none
        ? cardContent
        : ClipPath(
            clipper: ShapeBorderClipper(
              shape:
                  shape ?? RoundedRectangleBorder(borderRadius: borderRadius),
            ),
            child: cardContent,
          );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: inkBorderRadius,
            child: clippedContent,
          ),
        ),
      );
    }

    return Padding(padding: margin, child: clippedContent);
  }
}
