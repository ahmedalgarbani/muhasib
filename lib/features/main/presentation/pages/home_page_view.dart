import 'package:flutter/material.dart';
import 'package:muhasib/core/dummy/dummy_data.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/main/presentation/widgets/bottom_action_card.dart';
import 'package:muhasib/features/main/presentation/widgets/cards_carousel.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_section.dart';
import 'package:muhasib/features/main/presentation/widgets/recent_actions_section.dart';
import 'package:muhasib/features/main/presentation/widgets/stats_cards_section.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({Key? key}) : super(key: key);

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  bool showBalance = false;
  int activeCardIndex = 0;
  final PageController _pageController = PageController();

  final List<CardData> cards = [
    CardData('الصندوق الرئيسي', '125,450.00', CardType.primary),
    CardData('الحساب الثانوي', '87,320.50', CardType.secondary),
    CardData('حساب التوفير', '250,890.75', CardType.tertiary),
    CardData('المحفظة الاستثمارية', '412,675.20', CardType.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'محاسب',
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              CardsCarousel(
                cards: cards,
                showBalance: showBalance,
                activeIndex: activeCardIndex,
                onPageChanged: (index) =>
                    setState(() => activeCardIndex = index),
                onToggleBalance: () =>
                    setState(() => showBalance = !showBalance),
              ),
              const QuickAccessSection(),
              const RecentActionsSection(),
              const StatsCardsSection(),
              const BottomActionCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
