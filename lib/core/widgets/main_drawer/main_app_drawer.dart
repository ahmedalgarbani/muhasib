import 'package:flutter/material.dart';
import 'package:muhasib/core/models/nav_item.dart';
import 'package:muhasib/core/route/app_navigator.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/app_drawer_controller.dart';
import 'package:muhasib/core/widgets/main_drawer/drawer_menu_item.dart';

class MainAppDrawer extends StatelessWidget {
  const MainAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final mainItems = AppNavigator.bySection(DrawerSection.main);
    final bottomItems = AppNavigator.bySection(DrawerSection.bottom);

    return ColoredBox(
      color: AppColors.gray50,
      child: Column(
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: closeAppDrawer,
                tooltip: 'إغلاق',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'محاسب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'نظام إدارة الحسابات والمخزون',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
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
        style: const TextStyle(
          color: AppColors.gray400,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
