import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/constant/app_string.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/theme.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';

/// ─────────────────────────────────────────────
/// Home Summary Section – dynamic data from cubits
/// Shows real totals or '—' when loading/empty
/// ─────────────────────────────────────────────
class HomeSummarySection extends StatelessWidget {
  const HomeSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Accounts & Sales
          Row(
            children: [
              Expanded(
                child: BlocBuilder<AccountsCubit, AccountsState>(
                  builder: (context, state) {
                    final count = state is AccountsLoaded
                        ? state.accounts.length.toString()
                        : '—';
                    return _SummaryCard(
                      icon: Icons.account_balance_rounded,
                      title: AppStrings.drawerAccounts,
                      value: count,
                      cardColor: AppColors.primary,
                      onTap: () =>
                          GoRouter.of(context).push(AppRoutes.accountsGuide),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlocBuilder<SalesCubit, SalesState>(
                  builder: (context, state) {
                    final count = state is SalesLoaded
                        ? state.invoices.length.toString()
                        : '—';
                    return _SummaryCard(
                      icon: Icons.receipt_long_rounded,
                      title: AppStrings.salesListTitle,
                      value: count,
                      cardColor: AppColors.materialTeal600,
                      onTap: () =>
                          GoRouter.of(context).push(AppRoutes.salesList),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Products & Reports
          Row(
            children: [
              Expanded(
                child: BlocBuilder<ProductsCubit, ProductsState>(
                  builder: (context, state) {
                    final count = state is ProductsLoaded
                        ? state.products.length.toString()
                        : '—';
                    return _SummaryCard(
                      icon: Icons.inventory_2_rounded,
                      title: AppStrings.drawerProducts,
                      value: count,
                      cardColor: AppColors.materialDeepOrange500,
                      onTap: () =>
                          GoRouter.of(context).push(AppRoutes.itemsManage),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.bar_chart_rounded,
                  title: AppStrings.drawerReports,
                  value: '',
                  labelOverride: AppStrings.homeViewAll,
                  cardColor: AppColors.materialPurple500,
                  onTap: () => GoRouter.of(context).push(AppRoutes.reports),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Individual Summary Card
// ═══════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? labelOverride;
  final Color cardColor;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.cardColor,
    this.labelOverride,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            // Title
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            // Value or label override
            if (labelOverride != null)
              Text(
                labelOverride!,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              )
            else
              Text(
                value,
                style: AppTextStyles.numberLarge.copyWith(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
