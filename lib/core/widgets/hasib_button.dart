import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

enum HasibButtonVariant { primary, secondary, text, danger, success }

class HasibButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final IconData? icon;
  final bool loading;
  final HasibButtonVariant variant;
  final bool fullWidth;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const HasibButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.icon,
    this.loading = false,
    this.variant = HasibButtonVariant.primary,
    this.fullWidth = true,
    this.height,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !loading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case HasibButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.primary : Colors.grey[300]!;
        foregroundColor = isEnabled ? Colors.white : Colors.grey[500]!;
        break;
      case HasibButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.primary : Colors.grey[500]!;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.primary : Colors.grey[300]!,
          width: 1.5,
        );
        break;
      case HasibButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.primary : Colors.grey[500]!;
        break;
      case HasibButtonVariant.danger:
        backgroundColor = isEnabled ? Colors.red : Colors.red.shade200;
        foregroundColor = Colors.white;
        break;
      case HasibButtonVariant.success:
        backgroundColor = isEnabled ? Colors.green : Colors.green.shade200;
        foregroundColor = Colors.white;
        break;
    }

    final Widget? effectiveLeading = leading ??
        (icon != null ? Icon(icon, size: fontSize != null ? fontSize! + 3 : 18) : null);

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (effectiveLeading != null) ...[
          IconTheme(
            data: IconThemeData(
              color: foregroundColor,
              size: fontSize != null ? fontSize! + 3 : 18,
            ),
            child: effectiveLeading,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize ?? 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (variant == HasibButtonVariant.text) {
      return TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: content,
      );
    }

    return Container(
      width: fullWidth ? double.infinity : null,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: (variant == HasibButtonVariant.primary ||
                variant == HasibButtonVariant.danger ||
                variant == HasibButtonVariant.success) &&
                isEnabled
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: borderSide,
          ),
        ),
        child: content,
      ),
    );
  }
}
