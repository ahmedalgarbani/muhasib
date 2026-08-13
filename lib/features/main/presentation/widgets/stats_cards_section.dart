import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 5,
        children: [
          Expanded(
            child: StatsCard(
              icon: Icons.people,
              title: 'الزبائن',
              value: '$customersCount',
              subtitle: '$customersCount زبون مسجل',
            ),
          ),
          Expanded(
            child: StatsCard(
              icon: Icons.handshake,
              title: 'الموردين',
              value: '$suppliersCount',
              subtitle: '$suppliersCount مورد مسجل',
            ),
          ),
        ],
      ),
    );
  }
}
