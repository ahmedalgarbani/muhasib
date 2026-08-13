import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/stores/presentation/widgets/warehouse_page_sections.dart';

class WarehousesMainPage extends StatelessWidget {
  const WarehousesMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: const CustomAppBar(title: 'إدارة المخازن'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            WarehouseMenuCard(
              title: 'المخازن',
              icon: Icons.warehouse,
              color: AppColors.materialBlue700,
              onTap: () => context.pushNamed('/warehouses/list'),
            ),
            WarehouseMenuCard(
              title: 'الجرد',
              icon: Icons.inventory,
              color: AppColors.materialTeal600,
              onTap: () => context.pushNamed('/warehouses/inventory'),
            ),
            WarehouseMenuCard(
              title: 'التسويات',
              icon: Icons.tune,
              color: AppColors.materialOrange500,
              onTap: () => context.pushNamed('/warehouses/adjustment'),
            ),
            WarehouseMenuCard(
              title: 'التحويلات',
              icon: Icons.swap_horiz,
              color: AppColors.materialPurple500,
              onTap: () => context.pushNamed('/warehouses/transfer'),
            ),
          ],
        ),
      ),
    );
  }
}
