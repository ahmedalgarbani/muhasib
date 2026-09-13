import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/widgets/pressable_scale.dart';

/// Friendly inline error state with a retry action.
class ErrorStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const ErrorStateCard({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.errorLight : AppColors.error;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded, size: 28, color: errorColor),
          ),
          const SizedBox(height: 14),
          Text(
            'تعذّر تحميل البيانات',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          PressableScale(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primaryDark : AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl28),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    retryLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
