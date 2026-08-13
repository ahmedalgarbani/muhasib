import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

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
            _buildMenuCard(
              context,
              title: 'المخازن',
              icon: Icons.warehouse,
              color: AppColors.materialBlue700,
              route: '/warehouses/list',
            ),
            _buildMenuCard(
              context,
              title: 'الجرد',
              icon: Icons.inventory,
              color: AppColors.materialTeal600,
              route: '/warehouses/inventory',
            ),
            _buildMenuCard(
              context,
              title: 'التسويات',
              icon: Icons.tune,
              color: AppColors.materialOrange500,
              route: '/warehouses/adjustment',
            ),
            _buildMenuCard(
              context,
              title: 'التحويلات',
              icon: Icons.swap_horiz,
              color: AppColors.materialPurple500,
              route: '/warehouses/transfer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return CustomCardContainer(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(route),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: color,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
