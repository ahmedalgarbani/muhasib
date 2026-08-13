import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

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
    final defaultFillColor = enabled
        ? (backgroundColor ?? AppColors.surface)
        : AppColors.slate100.withValues(alpha: 0.6);

    final defaultBorderColor = borderColor ?? AppColors.slate200;
    final defaultFocusColor = focusBorderColor ?? AppColors.primary;

    final defaultPrefixIcon = prefixIcon != null
        ? IconTheme(
            data: const IconThemeData(color: AppColors.slate500, size: 20),
            child: prefixIcon!,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
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
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: true,
          icon: AnimatedRotation(
            turns: 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? AppColors.slate500 : AppColors.slate300,
              size: 22,
            ),
          ),
          dropdownColor: Colors.white,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(AppRadius.md),
          elevation: 3,
          style: TextStyle(
            color: enabled ? AppColors.slate900 : AppColors.slate400,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: suffixIcon != null
              ? (context) => items.map((item) {
                  return Row(
                    children: [
                      Expanded(child: item.child),
                      IconTheme(
                        data: const IconThemeData(
                          color: AppColors.slate500,
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
            hintStyle: const TextStyle(
              color: AppColors.slate400,
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
              horizontal: 16,
              vertical: 15,
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
                color: AppColors.slate200.withValues(alpha: 0.5),
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
