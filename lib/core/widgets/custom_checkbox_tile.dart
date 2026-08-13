import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// Reusable Checkbox Tile with standardized padding, border, and labels.
class CustomCheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;

  const CustomCheckboxTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: enabled ? colorScheme.surface : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primary,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        secondary: icon != null
            ? Icon(
                icon,
                color: enabled ? AppColors.primary : Colors.grey,
                size: 22,
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: enabled ? colorScheme.onSurface : Colors.grey,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? colorScheme.onSurfaceVariant : Colors.grey,
                ),
              )
            : null,
      ),
    );
  }
}
