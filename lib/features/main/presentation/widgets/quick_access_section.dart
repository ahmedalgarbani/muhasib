import 'package:flutter/material.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_item.dart';

class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.gray200),
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 4 : 6,
            childAspectRatio: MediaQuery.of(context).size.width < 400
                ? 0.7
                : 1.0,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
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
            ],
          ),
        ],
      ),
    );
  }
}
