import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/main/presentation/cubit/main_cubit.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';
import 'package:muhasib/features/main/presentation/widgets/bottom_action_card.dart';
import 'package:muhasib/features/main/presentation/widgets/cards_carousel.dart';
import 'package:muhasib/features/main/presentation/widgets/home_summary_section.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_section.dart';
import 'package:muhasib/features/main/presentation/widgets/recent_actions_section.dart';
import 'package:muhasib/features/main/presentation/widgets/stats_cards_section.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  bool showBalance = false;
  int activeCardIndex = 0;

  final List<CardData> cards = [
    CardData('الصندوق الرئيسي', '0.00', CardType.primary),
    CardData('الحساب البنكي', '0.00', CardType.secondary),
    CardData('حساب التوفير', '0.00', CardType.tertiary),
    CardData('المحفظة الاستثمارية', '0.00', CardType.success),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MainCubit>()..loadDashboardData(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const CustomAppBar(
          title: 'محاسب',
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: BlocBuilder<MainCubit, MainState>(
              builder: (context, state) {
                int customersCount = 0;
                int suppliersCount = 0;
                List<RecentTransactionEntity> transactions = [];

                if (state is MainDashboardLoaded) {
                  customersCount = state.customersCount;
                  suppliersCount = state.suppliersCount;
                  transactions = state.recentTransactions;
                }

                final homeType = SettingsCache.homeScrrenType;
                final sections = <Widget>[];

                if (homeType == 2) {
                  sections.addAll([
                    const SizedBox(height: 12),
                    StatsCardsSection(
                      customersCount: customersCount,
                      suppliersCount: suppliersCount,
                    ),
                    const QuickAccessSection(
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                    ),
                    RecentActionsSection(transactions: transactions),
                    const HomeSummarySection(),
                  ]);
                } else if (homeType == 3) {
                  sections.addAll([
                    const SizedBox(height: 12),
                    const HomeSummarySection(),
                    RecentActionsSection(transactions: transactions),
                    const QuickAccessSection(useWrap: true),
                    StatsCardsSection(
                      customersCount: customersCount,
                      suppliersCount: suppliersCount,
                    ),
                  ]);
                } else {
                  sections.addAll([
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
                    RecentActionsSection(transactions: transactions),
                    StatsCardsSection(
                      customersCount: customersCount,
                      suppliersCount: suppliersCount,
                    ),
                    const BottomActionCard(),
                  ]);
                }
                sections.add(const SizedBox(height: 20));

                return Column(
                  children: sections,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
