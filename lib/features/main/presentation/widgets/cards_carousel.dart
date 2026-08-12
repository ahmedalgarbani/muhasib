import 'package:flutter/material.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';
import 'package:muhasib/features/main/presentation/widgets/carousel_indicators.dart';
import 'package:muhasib/features/main/presentation/widgets/finance_card.dart';

class CardsCarousel extends StatelessWidget {
  final List<CardData> cards;
  final bool showBalance;
  final int activeIndex;
  final Function(int) onPageChanged;
  final VoidCallback onToggleBalance;

  const CardsCarousel({
    Key? key,
    required this.cards,
    required this.showBalance,
    required this.activeIndex,
    required this.onPageChanged,
    required this.onToggleBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Column(
      children: [
        SizedBox(
          height: height * 0.33, // adaptive carousel height
          child: PageView.builder(
            itemCount: cards.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return FinanceCard(
                data: cards[index],
                showBalance: showBalance,
                isActive: activeIndex == index,
                onToggleBalance: onToggleBalance,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        CarouselIndicators(count: cards.length, activeIndex: activeIndex),
      ],
    );
  }
}
