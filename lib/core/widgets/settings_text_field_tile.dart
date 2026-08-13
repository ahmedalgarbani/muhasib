import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

/// Reusable Text Field Tile for settings pages.
class SettingsTextFieldTile extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String? hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const SettingsTextFieldTile({
    super.key,
    required this.title,
    required this.controller,
    this.hintText,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, size: 20, color: Colors.grey[600])
          : null,
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: TextInputField(
        controller: controller,
        hint: hintText ?? '',
        keyboardType: keyboardType ?? TextInputType.text,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
