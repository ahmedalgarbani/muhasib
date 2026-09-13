import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final String subtitle;
  final Color? color;

  const StatsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? AppColors.saudiEmerald;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            cardColor.withValues(alpha: isDark ? 0.18 : 0.10),
            cardColor.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(
          color: cardColor.withValues(alpha: isDark ? 0.30 : 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: cardColor, size: 21),
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) => Text(
                  NumberFormatter.formatNumber(animatedValue),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
