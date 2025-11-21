import 'package:flutter/material.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_item.dart';

class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
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
                // TODO: Add customers route when available
              ),
              const QuickAccessItem(
                icon: Icons.handshake,
                label: 'الموردين',
                color: Colors.indigo,
                // TODO: Add suppliers route when available
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
