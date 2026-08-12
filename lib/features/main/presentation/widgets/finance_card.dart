import 'package:flutter/material.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';
import 'package:muhasib/features/main/presentation/widgets/card_actions.dart';
import 'package:muhasib/features/main/presentation/widgets/card_balance.dart';
import 'package:muhasib/features/main/presentation/widgets/card_header.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class FinanceCard extends StatelessWidget {
  final CardData data;
  final bool showBalance;
  final bool isActive;
  final VoidCallback onToggleBalance;

  const FinanceCard({
    super.key,
    required this.data,
    required this.showBalance,
    required this.isActive,
    required this.onToggleBalance,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.85; // smaller card width
    final cardHeight = size.height * 0.28; // smaller height for balance

    return Center(
      child: AnimatedScale(
        scale: isActive ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.7,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: data.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: CardHeader(title: data.title)),
                  CardBalance(balance: data.balance, showBalance: showBalance),
                  CardActions(
                    showBalance: showBalance,
                    onToggleBalance: onToggleBalance,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
