import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

/// Reusable List Tile Card for master-detail items, customers, suppliers, currencies, warehouses, and settings.
class CustomListTileCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? statusChip;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const CustomListTileCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.statusChip,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomCardContainer(
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (statusChip != null) statusChip!,
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ] else if (onEdit != null || onDelete != null) ...[
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) onEdit!();
                if (value == 'delete' && onDelete != null) onDelete!();
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
