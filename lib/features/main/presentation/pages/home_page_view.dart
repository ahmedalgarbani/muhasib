import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/error_state_card.dart';
import 'package:muhasib/features/main/presentation/cubit/main_cubit.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';
import 'package:muhasib/features/main/presentation/widgets/bottom_action_card.dart';
import 'package:muhasib/features/main/presentation/widgets/cards_carousel.dart';
import 'package:muhasib/features/main/presentation/widgets/home_greeting_header.dart';
import 'package:muhasib/features/main/presentation/widgets/home_skeleton_loader.dart';
import 'package:muhasib/features/main/presentation/widgets/home_summary_section.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_section.dart';
import 'package:muhasib/features/main/presentation/widgets/recent_actions_section.dart';
import 'package:muhasib/features/main/presentation/widgets/staggered_entrance.dart';
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
          child: RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onRefresh: () async {
              final mainCubit = context.read<MainCubit>();
              context.read<AccountsCubit>().loadAllAccounts();
              mainCubit.loadDashboardData();
              await mainCubit.stream
                  .firstWhere((s) => s is MainDashboardLoaded || s is MainError)
                  .timeout(
                    const Duration(seconds: 6),
                    onTimeout: () => const MainDashboardLoaded(
                      customersCount: 0,
                      suppliersCount: 0,
                      recentTransactions: [],
                    ),
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: BlocBuilder<MainCubit, MainState>(
                builder: (context, state) {
                  if (state is MainError) {
                    return Column(
                      children: [
                        const HomeGreetingHeader(),
                        const SizedBox(height: 6),
                        ErrorStateCard(
                          message: state.message,
                          onRetry: () =>
                              context.read<MainCubit>().loadDashboardData(),
                        ),
                      ],
                    );
                  }

                  if (state is! MainDashboardLoaded) {
                    return const Column(
                      children: [
                        HomeGreetingHeader(),
                        SizedBox(height: 6),
                        HomeSkeletonLoader(),
                      ],
                    );
                  }

                  final sections = _buildSections(state);
                  return Column(
                    children: [
                      const HomeGreetingHeader(),
                      StaggeredEntrance(
                        key: ValueKey(state.runtimeType),
                        children: sections,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(MainDashboardLoaded state) {
    final homeType = SettingsCache.homeScrrenType;
    final sections = <Widget>[const SizedBox(height: 6)];

    if (homeType == 2) {
      sections.addAll([
        StatsCardsSection(
          customersCount: state.customersCount,
          suppliersCount: state.suppliersCount,
        ),
        const QuickAccessSection(crossAxisCount: 2, childAspectRatio: 1.8),
        RecentActionsSection(transactions: state.recentTransactions),
        const HomeSummarySection(),
      ]);
    } else if (homeType == 3) {
      sections.addAll([
        const HomeSummarySection(),
        RecentActionsSection(transactions: state.recentTransactions),
        const QuickAccessSection(useWrap: true),
        StatsCardsSection(
          customersCount: state.customersCount,
          suppliersCount: state.suppliersCount,
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
              onPageChanged: (index) => setState(() => activeCardIndex = index),
              onToggleBalance: () => setState(() => showBalance = !showBalance),
            );
          },
        ),
        const SizedBox(height: 4),
        const QuickAccessSection(),
        RecentActionsSection(transactions: state.recentTransactions),
        StatsCardsSection(
          customersCount: state.customersCount,
          suppliersCount: state.suppliersCount,
        ),
        const BottomActionCard(),
      ]);
    }
    sections.add(const SizedBox(height: 10));
    return sections;
  }
}
