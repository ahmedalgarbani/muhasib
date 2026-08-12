import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// A modern, premium text input field widget following system design standards.
class TextInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? textEditingController;
  final TextEditingController? controller;
  final String? initialValue;
  final bool isRequired;
  final bool isArabic;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? inputType;
  final int? maxLength;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool showCharacterCount;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final TextStyle? style;

  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusBorderColor;

  const TextInputField({
    super.key,
    this.label = '',
    this.hint,
    this.textEditingController,
    this.controller,
    this.initialValue,
    this.isRequired = false,
    this.isArabic = false,
    this.prefixIcon,
    this.suffixIcon,
    this.inputAction,
    this.onSubmitted,
    this.inputType,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.showCharacterCount = false,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.decoration,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onTap,
    this.inputFormatters,
    this.enabled = true,
    this.backgroundColor,
    this.borderColor,
    this.focusBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? textEditingController;
    final effectiveInitialValue = effectiveController == null
        ? initialValue
        : null;
    final effectiveKeyboardType = keyboardType ?? inputType;

    final defaultFillColor = enabled
        ? (readOnly ? AppColors.slate100 : AppColors.surface)
        : AppColors.slate100.withValues(alpha: 0.6);

    final defaultBorderColor = borderColor ?? AppColors.slate200;
    final defaultFocusColor = focusBorderColor ?? AppColors.primary;

    final defaultStyle = TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: enabled ? AppColors.slate900 : AppColors.slate400,
      height: 1.4,
    );

    final defaultHintStyle = TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: AppColors.slate400,
    );

    final defaultPrefixIcon = prefixIcon != null
        ? IconTheme(
            data: const IconThemeData(color: AppColors.slate500, size: 20),
            child: prefixIcon!,
          )
        : null;

    final defaultSuffixIcon = suffixIcon != null
        ? IconTheme(
            data: const IconThemeData(color: AppColors.slate500, size: 20),
            child: suffixIcon!,
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
        TextFormField(
          controller: effectiveController,
          initialValue: effectiveInitialValue,
          focusNode: focusNode,
          autofocus: autofocus,
          onTap: onTap,
          inputFormatters: inputFormatters,
          enabled: enabled,
          textAlign: textAlign,
          textDirection: isArabic ? TextDirection.rtl : null,
          keyboardType: effectiveKeyboardType,
          textInputAction: inputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: maxLines,
          validator: validator,
          obscureText: obscureText,
          readOnly: readOnly,
          style: style ?? defaultStyle,
          decoration:
              decoration ??
              InputDecoration(
                hintText: hint,
                hintStyle: defaultHintStyle,
                prefixIcon: defaultPrefixIcon,
                suffixIcon: defaultSuffixIcon,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                counterText: showCharacterCount ? null : '',
                filled: true,
                fillColor: backgroundColor ?? defaultFillColor,
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
                  borderSide: const BorderSide(
                    color: AppColors.red500,
                    width: 1.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.red500,
                    width: 1.8,
                  ),
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
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
        ),
      ],
    );
  }
}
