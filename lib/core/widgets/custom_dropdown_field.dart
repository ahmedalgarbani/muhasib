import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';

/// A premium dropdown form field matching TextInputField styling.
///
/// Provides a consistent design system with label, validation, prefix/suffix
/// icons, and polished dropdown popup styling.
class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool enabled;
  final String? Function(T?)? validator;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusBorderColor;

  const CustomDropdownField({
    super.key,
    this.label = '',
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.enabled = true,
    this.validator,
    this.backgroundColor,
    this.borderColor,
    this.focusBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final defaultFillColor = enabled
        ? (backgroundColor ?? colorScheme.surface)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final defaultBorderColor = borderColor ?? dividerColor;
    final defaultFocusColor = focusBorderColor ?? AppColors.primary;

    final defaultPrefixIcon = prefixIcon != null
        ? IconTheme(
            data: IconThemeData(color: colorScheme.onSurfaceVariant, size: 20),
            child: prefixIcon!,
          )
        : null;

    final hasMatch = items != null && items!.any((item) => item.value == value);
    final safeValue = hasMatch ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.1,
                ),
                children: [
                  TextSpan(text: label),
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.red500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        DropdownButtonFormField<T>(
          value: safeValue,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: true,
          icon: AnimatedRotation(
            turns: 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.outlineVariant,
              size: 22,
            ),
          ),
          dropdownColor: colorScheme.surface,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(AppRadius.md),
          elevation: 3,
          style: TextStyle(
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: suffixIcon != null
              ? (context) => items.map((item) {
                  return Row(
                    children: [
                      Expanded(child: item.child),
                      IconTheme(
                        data: IconThemeData(
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        child: suffixIcon!,
                      ),
                    ],
                  );
                }).toList()
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: defaultPrefixIcon,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            errorText: errorText,
            filled: true,
            fillColor: defaultFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: defaultBorderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: defaultBorderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: defaultFocusColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.red500, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.red500, width: 1.8),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: dividerColor.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppColors.red500,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
