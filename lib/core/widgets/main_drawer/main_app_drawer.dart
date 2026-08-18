import 'package:flutter/material.dart';
import 'package:muhasib/core/models/nav_item.dart';
import 'package:muhasib/core/route/app_navigator.dart';
import 'package:muhasib/core/route/app_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/app_drawer_controller.dart';
import 'package:muhasib/core/widgets/main_drawer/drawer_menu_item.dart';

class MainAppDrawer extends StatelessWidget {
  const MainAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final mainItems = AppNavigator.bySection(DrawerSection.main)
        .where(
          (item) =>
              SettingsCache.showStockModule ||
              item.route != AppRoutes.warehouses,
        )
        .where((item) {
          if (!SettingsCache.useMiniHasib) return true;
          return item.route == AppRoutes.sales ||
              item.route == AppRoutes.purchases ||
              item.route == AppRoutes.profiles ||
              item.route == AppRoutes.settings;
        })
        .toList();
    final bottomItems = AppNavigator.bySection(DrawerSection.bottom);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MainDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              children: [
                ...mainItems.map((item) => DrawerMenuItem(item: item)),
                if (bottomItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _SectionLabel('عن التطبيق'),
                  const SizedBox(height: 4),
                  ...bottomItems.map((item) => DrawerMenuItem(item: item)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainDrawerHeader extends StatelessWidget {
  const _MainDrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.saudiEmerald, AppColors.saudiEmeraldDark],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.sm14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: closeAppDrawer,
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  closeAppDrawer();
                  router.go(AppRoutes.home);
                },
                child: const Text(
                  'محاسب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'نظام إدارة الحسابات ونقاط البيع الذكي',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
