import 'package:flutter/material.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/services/settings_cache.dart';
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
      QuickAccessItem(
        icon: Icons.shopping_bag,
        label: 'المشتريات',
        color: Colors.blue,
        route: AppRoutes.purchasesList,
      ),
      QuickAccessItem(
        icon: Icons.shopping_cart,
        label: 'المبيعات',
        color: Colors.green,
        route: AppRoutes.salesList,
      ),
      QuickAccessItem(
        icon: Icons.description,
        label: 'السندات',
        color: Colors.purple,
        route: AppRoutes.accountsVouchers,
      ),
      QuickAccessItem(
        icon: Icons.account_balance,
        label: 'الحسابات',
        color: Colors.orange,
        route: AppRoutes.accountsGuide,
      ),
      const QuickAccessItem(
        icon: Icons.people,
        label: 'الزبائن',
        color: Colors.pink,
      ),
      const QuickAccessItem(
        icon: Icons.handshake,
        label: 'الموردين',
        color: Colors.indigo,
      ),
      QuickAccessItem(
        icon: Icons.bar_chart,
        label: 'التقارير',
        color: Colors.teal,
        route: AppRoutes.reports,
      ),
      QuickAccessItem(
        icon: Icons.settings,
        label: 'الإعدادات',
        color: Colors.grey,
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
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الوصول السريع',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (useWrap)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: 88,
                      height: 96,
                      child: item,
                    ),
                  )
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
