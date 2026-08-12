import 'package:flutter/material.dart';
import 'package:muhasib/features/main/presentation/widgets/stats_card.dart';

class StatsCardsSection extends StatelessWidget {
  const StatsCardsSection({super.key});

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
              value: '156',
              subtitle: '45 زبون نشط',
            ),
          ),
          Expanded(
            child: StatsCard(
              icon: Icons.handshake,
              title: 'الموردين',
              value: '89',
              subtitle: '23 مورد نشط',
            ),
          ),
        ],
      ),
    );
  }
}
