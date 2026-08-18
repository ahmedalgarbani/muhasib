import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/helpers/formatters.dart';
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
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  bool showBalance = true;
  int activeCardIndex = 0;

  List<CardData> _accountCards(List<AccountEntity> accounts) {
    return accounts
        .where((account) => account.isActive)
        .take(4)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => CardData(
            title: entry.value.name,
            balance: NumberFormatter.formatNumber(entry.value.balance),
            currency: 'YER',
            type: CardType.values[entry.key % CardType.values.length],
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MainCubit>()..loadDashboardData(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const CustomAppBar(title: 'محاسب'),
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
                final sections = <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً بك 👋',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'لوحة التحكم المالية الذكية',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ];

                if (homeType == 2) {
                  sections.addAll([
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 6),
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
                    BlocBuilder<AccountsCubit, AccountsState>(
                      builder: (context, accountsState) {
                        if (accountsState is! AccountsLoaded) {
                          return const SizedBox(height: 16);
                        }

                        final cards = _accountCards(accountsState.accounts);
                        if (cards.isEmpty) {
                          return const SizedBox(height: 16);
                        }

                        final safeIndex = activeCardIndex
                            .clamp(0, cards.length - 1)
                            .toInt();
                        return CardsCarousel(
                          cards: cards,
                          showBalance: showBalance,
                          activeIndex: safeIndex,
                          onPageChanged: (index) =>
                              setState(() => activeCardIndex = index),
                          onToggleBalance: () =>
                              setState(() => showBalance = !showBalance),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
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

                return Column(children: sections);
              },
            ),
          ),
        ),
      ),
    );
  }
}
