import 'package:flutter/material.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_item.dart';

class QuickAccessSection extends StatelessWidget {
  final int? crossAxisCount;
  final double? childAspectRatio;
  final bool useWrap;

  const QuickAccessSection({
    super.key,
    this.crossAxisCount,
    this.childAspectRatio,
    this.useWrap = false,
  });

  List<QuickAccessItem> _buildItems() {
    final items = [
      const QuickAccessItem(
        icon: Icons.point_of_sale_rounded,
        label: 'المبيعات',
        color: AppColors.saudiEmerald,
        route: AppRoutes.salesList,
      ),
      const QuickAccessItem(
        icon: Icons.shopping_bag_outlined,
        label: 'المشتريات',
        color: Color(0xFF0284C7),
        route: AppRoutes.purchasesList,
      ),
      const QuickAccessItem(
        icon: Icons.receipt_long_rounded,
        label: 'السندات',
        color: Color(0xFF7C3AED),
        route: AppRoutes.accountsVouchers,
      ),
      const QuickAccessItem(
        icon: Icons.account_balance_outlined,
        label: 'دليل الحسابات',
        color: AppColors.saudiGold,
        route: AppRoutes.accountsGuide,
      ),
      const QuickAccessItem(
        icon: Icons.people_alt_outlined,
        label: 'العملاء',
        color: Color(0xFF0D9488),
      ),
      const QuickAccessItem(
        icon: Icons.inventory_2_outlined,
        label: 'المخزون',
        color: Color(0xFFEA580C),
      ),
      const QuickAccessItem(
        icon: Icons.insert_chart_outlined_rounded,
        label: 'التقارير',
        color: Color(0xFF4F46E5),
        route: AppRoutes.reports,
      ),
      const QuickAccessItem(
        icon: Icons.settings_suggest_outlined,
        label: 'الإعدادات',
        color: AppColors.slate600,
        route: AppRoutes.settings,
      ),
    ];
    if (SettingsCache.useMiniHasib) {
      items.removeWhere(
        (item) =>
            item.route == AppRoutes.accountsVouchers ||
            item.route == AppRoutes.accountsGuide ||
            item.route == AppRoutes.reports,
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final width = MediaQuery.of(context).size.width;
    final columns = crossAxisCount ?? (width < 600 ? 4 : 6);
    final aspect = childAspectRatio ?? (width < 400 ? 0.7 : 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الوصول السريع',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.saudiMint,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Text(
                    'الخدمات',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.saudiEmerald,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (useWrap)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => SizedBox(width: 88, height: 96, child: item))
                  .toList(),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              childAspectRatio: aspect,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: items,
            ),
        ],
      ),
    );
  }
}
