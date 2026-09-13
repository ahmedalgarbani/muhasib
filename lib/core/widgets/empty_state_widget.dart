import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

/// Reusable Empty State Widget for lists, pages, and components with no data.
///
/// Responsive: adapts icon, font sizes, and padding automatically to the
/// available constraints to prevent overflows in tight or small containers.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Widget? customAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconSize,
    this.iconColor,
    this.actionText,
    this.onActionPressed,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor =
        iconColor ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final maxHeight = hasBoundedHeight
            ? constraints.maxHeight
            : double.infinity;

        // Adaptive scaling based on available height
        final bool isVeryCompact = maxHeight < 135;
        final bool isCompact = maxHeight < 200;

        final double effectiveCircleSize = iconSize != null
            ? iconSize! * 1.5
            : isVeryCompact
            ? 44.0
            : isCompact
            ? 60.0
            : 76.0;

        final double effectiveIconSize =
            iconSize ??
            (isVeryCompact
                ? 22.0
                : isCompact
                ? 30.0
                : 36.0);

        final double titleFontSize = isVeryCompact
            ? 13.5
            : isCompact
            ? 15.0
            : 16.5;

        final double subtitleFontSize = isVeryCompact
            ? 11.5
            : isCompact
            ? 12.5
            : 13.5;

        final double spacingBeforeTitle = isVeryCompact
            ? 4.0
            : isCompact
            ? 8.0
            : 10.0;

        final double spacingBeforeSubtitle = isVeryCompact
            ? 3.0
            : isCompact
            ? 6.0
            : 8.0;

        final EdgeInsets effectivePadding = isVeryCompact
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              )
            : isCompact
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              )
            : const EdgeInsets.all(AppSpacing.lg);

        Widget content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: effectiveCircleSize,
              height: effectiveCircleSize,
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
              child: Center(
                child: Icon(
                  icon,
                  size: effectiveIconSize,
                  color: defaultIconColor,
                ),
              ),
            ),
            SizedBox(height: spacingBeforeTitle),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              maxLines: isVeryCompact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: spacingBeforeSubtitle),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: isVeryCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (customAction != null) ...[
              const SizedBox(height: 8),
              customAction!,
            ] else if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 8),
              HasibButton(
                label: actionText!,
                onPressed: onActionPressed,
                leading: const Icon(Icons.add_rounded),
                variant: HasibButtonVariant.primary,
              ),
            ],
          ],
        );

        return Center(
          child: Padding(
            padding: effectivePadding,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        );
      },
    );
  }
}
