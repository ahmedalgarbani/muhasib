import 'package:flutter/material.dart';

/// Reusable Text Field Tile for settings pages.
class SettingsTextFieldTile extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String? hintText;
  final IconData? icon;
  final TextInputType? keyboardType;

  const SettingsTextFieldTile({
    super.key,
    required this.title,
    required this.controller,
    this.hintText,
    this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon, size: 20, color: Colors.grey[600]) : null,
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
