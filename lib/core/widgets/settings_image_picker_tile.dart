import 'package:flutter/material.dart';

/// Reusable Image Picker Tile for settings pages.
class SettingsImagePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String buttonText;
  final bool enabled;

  const SettingsImagePickerTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.buttonText = 'اختر',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: enabled ? onTap : null,
      leading: Icon(
        icon,
        size: 20,
        color: enabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.outlineVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? colorScheme.onSurface : colorScheme.outlineVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            buttonText,
            style: TextStyle(
              fontSize: 13,
              color: enabled
                  ? Theme.of(context).primaryColor
                  : colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
