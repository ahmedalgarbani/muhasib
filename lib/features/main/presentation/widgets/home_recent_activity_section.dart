import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/theme/theme.dart';
import 'package:muhasib/core/constant/app_string.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/theme/app_spacing.dart';

/// ─────────────────────────────────────────────
/// Home Recent Activity Section
/// Merges sales and purchases for a unified timeline
/// ─────────────────────────────────────────────
class HomeRecentActivitySection extends StatelessWidget {
  const HomeRecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SalesCubit, SalesState>(
      builder: (context, salesState) {
        return BlocBuilder<PurchasesCubit, PurchasesState>(
          builder: (context, purchasesState) {
            List<InvoiceEntity> allActivities = [];

            if (salesState is SalesLoaded) {
              allActivities.addAll(salesState.invoices);
            }
            if (purchasesState is PurchaseInvoicesLoaded) {
              allActivities.addAll(purchasesState.invoices);
            }

            // Sort by date descending
            allActivities.sort((a, b) => b.date.compareTo(a.date));

            // Take top 5
            final latestActivities = allActivities.take(5).toList();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: AppConstant.defaultPadding,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.homeRecentActivity,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pushNamed(AppRoutes.salesList),
                        child: Text(
                          AppStrings.homeViewAll,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (latestActivities.isEmpty)
                    HomeRecentActivityEmptyState(isDark: isDark)
                  else
                    ...latestActivities.map((activity) {
                      return _ActivityItem(activity: activity);
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class HomeRecentActivityEmptyState extends StatelessWidget {
  const HomeRecentActivityEmptyState({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark ? AppColors.grey700 : AppColors.grey300,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.homeEmptyActivity,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.grey500 : AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Individual Activity Item
// ═══════════════════════════════════════════════
class _ActivityItem extends StatelessWidget {
  final InvoiceEntity activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine type (simplified logic: usually sales have specific types)
    // For now assuming sales/purchases based on their cubit source or specific type field if known
    // Let's check a field like parentInvoiceType or just use a generic color for now
    final isSale = activity.invoiceType == 1; // Assuming 1 = Sale, 2 = Purchase

    final color = isSale ? AppColors.success : AppColors.error;
    final icon = isSale
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final typeLabel = isSale
        ? AppStrings.drawerSales
        : AppStrings.drawerPurchases;

    final date = DateTime.fromMillisecondsSinceEpoch(activity.date * 1000);
    final dateStr = intl.DateFormat('yyyy-MM-dd HH:mm', 'ar').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.statement ?? typeLabel} #${activity.number}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  dateStr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                intl.NumberFormat('#,##0.00').format(activity.amount),
                style: AppTextStyles.numberMedium.copyWith(
                  color: isSale ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activity.currencyCode ?? 'YER',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
