import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/main/presentation/widgets/stats_card.dart';

class StatsCardsSection extends StatelessWidget {
  final int customersCount;
  final int suppliersCount;

  const StatsCardsSection({
    super.key,
    required this.customersCount,
    required this.suppliersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              icon: Icons.people_alt_outlined,
              title: 'العملاء',
              value: '$customersCount',
              subtitle: '$customersCount عميل مسجل',
              color: AppColors.saudiEmerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              icon: Icons.handshake_outlined,
              title: 'الموردون',
              value: '$suppliersCount',
              subtitle: '$suppliersCount مورد مسجل',
              color: const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }
}
