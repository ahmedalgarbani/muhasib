import 'package:flutter/material.dart';

/// Reusable Dropdown Tile for settings pages.
class SettingsDropdownTile<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const SettingsDropdownTile({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon, size: 20, color: Colors.grey[600]) : null,
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    );
  }
}
