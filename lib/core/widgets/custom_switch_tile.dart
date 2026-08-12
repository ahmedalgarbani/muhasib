import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// Reusable Switch Tile with standardized theme padding, borders, and subtitle.
class CustomSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const CustomSwitchTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: enabled ? AppColors.gray50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: AppColors.primary,
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
            color: enabled ? AppColors.textPrimary : Colors.grey,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? AppColors.textSecondary : Colors.grey,
                ),
              )
            : null,
      ),
    );
  }
}
