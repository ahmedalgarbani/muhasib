import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

/// Reusable Empty State Widget for lists, pages, and components with no data.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Widget? customAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 80.0,
    this.iconColor,
    this.actionText,
    this.onActionPressed,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = iconColor ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.3)
                    : AppColors.saudiMint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryLight.withValues(alpha: 0.2)
                      : AppColors.emerald200,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 38,
                color: defaultIconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (customAction != null) ...[
              const SizedBox(height: 20),
              customAction!,
            ] else if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 20),
              HasibButton(
                label: actionText!,
                onPressed: onActionPressed,
                leading: const Icon(Icons.add_rounded),
                variant: HasibButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
