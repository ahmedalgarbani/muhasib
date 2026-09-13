import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: isDark ? 0.92 : 0.95),
              borderRadius: BorderRadius.circular(AppRadius.xl28),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark.withValues(alpha: 0.6)
                    : AppColors.borderLight.withValues(alpha: 0.9),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: currentIndex == 0,
                  onTap: () => _handleTap(context, 0, AppRoutes.home),
                ),
                _NavBarItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'المبيعات',
                  isActive: currentIndex == 1,
                  onTap: () => _handleTap(context, 1, AppRoutes.salesList),
                ),
                _NavBarItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  label: 'التقارير',
                  isActive: currentIndex == 2,
                  onTap: () => _handleTap(context, 2, AppRoutes.reports),
                ),
                _NavBarItem(
                  icon: Icons.tune_rounded,
                  label: 'الإعدادات',
                  isActive: currentIndex == 3,
                  onTap: () => _handleTap(context, 3, AppRoutes.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index, String routeName) {
    if (onTabSelected != null) {
      onTabSelected!(index);
    } else {
      if (currentIndex != index) {
        context.goNamed(routeName);
      }
    }
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveColor = isDark ? AppColors.slate400 : AppColors.slate500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.4)
                      : AppColors.saudiMint)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: isActive ? primaryColor : inactiveColor,
                size: 23,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? primaryColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
