import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';

class WarehousesMainPage extends StatelessWidget {
  const WarehousesMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar:  CustomAppBar(title: 'إدارة المخازن', onMenuPressed: () => Navigator.pop(context)),
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
              color: const Color(0xFF1976D2),
              route: '/warehouses/list',
            ),
            _buildMenuCard(
              context,
              title: 'الجرد',
              icon: Icons.inventory,
              color: const Color(0xFF00897B),
              route: '/warehouses/inventory',
            ),
            _buildMenuCard(
              context,
              title: 'التسويات',
              icon: Icons.tune,
              color: const Color(0xFFFF9800),
              route: '/warehouses/adjustment',
            ),
            _buildMenuCard(
              context,
              title: 'التحويلات',
              icon: Icons.swap_horiz,
              color: const Color(0xFF9C27B0),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
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
