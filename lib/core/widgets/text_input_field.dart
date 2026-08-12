import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class TextInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? textEditingController;
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

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusBorderColor;

  const TextInputField({
    super.key,
    this.label = '',
    this.hint,
    this.textEditingController,
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
    this.backgroundColor,
    this.borderColor,
    this.focusBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: label),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: textEditingController,
          textAlign: textAlign,
          textDirection: isArabic ? TextDirection.rtl : null,
          keyboardType: inputType,
          textInputAction: inputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: maxLines,
          validator: validator,
          obscureText: obscureText,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: showCharacterCount ? null : "",
            filled: true,
            fillColor: backgroundColor ?? (readOnly ? Colors.grey[100] : AppColors.background),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: borderColor ?? AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: borderColor ?? AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: focusBorderColor ?? AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
