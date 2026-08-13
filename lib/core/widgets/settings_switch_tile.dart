import 'package:flutter/material.dart';

/// Reusable Switch Tile for settings pages.
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final bool enabled;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: icon != null
          ? Icon(
              icon,
              size: 20,
              color: enabled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.outlineVariant,
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? colorScheme.onSurface : colorScheme.outlineVariant,
        ),
      ),
      subtitle: Text(
        subtitle ?? (value ? 'مفعل' : 'غير مفعل'),
        style: TextStyle(
          fontSize: 11,
          color: enabled
              ? colorScheme.onSurfaceVariant
              : colorScheme.outlineVariant,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: Theme.of(context).primaryColor,
      dense: true,
    );
  }
}
