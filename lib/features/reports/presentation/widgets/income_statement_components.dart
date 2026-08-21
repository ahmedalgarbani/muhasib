import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class IncomeStatementSummaryRowWidget extends StatelessWidget {
  final IncomeStatementSummary summary;
  final String Function(double) formatCurrency;

  const IncomeStatementSummaryRowWidget({
    super.key,
    required this.summary,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final totalExpenses = s.totalOperatingExpenses + s.totalCostOfSales;
    final isProfit = s.netIncome >= 0;
    final marginPercent = s.totalRevenue > 0
        ? (s.netIncome / s.totalRevenue * 100)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: ReportKpiCard(
            title: 'إجمالي الإيرادات',
            value: formatCurrency(s.totalRevenue),
            icon: Icons.trending_up,
            color: Colors.green[700]!,
            subtitle: 'جميع دخل الفعالية',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ReportKpiCard(
            title: 'إجمالي التكاليف والمصروفات',
            value: formatCurrency(totalExpenses),
            icon: Icons.trending_down,
            color: Colors.red[700]!,
            subtitle: 'مبيعات + تشغيل',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ReportKpiCard(
            title: isProfit ? 'صافي الربح' : 'صافي الخسارة',
            value: formatCurrency(s.netIncome),
            icon: isProfit ? Icons.account_balance : Icons.warning,
            color: isProfit ? Colors.teal[700]! : Colors.deepOrange[700]!,
            trendText: '${marginPercent.toStringAsFixed(1)}%',
            isPositiveTrend: isProfit,
            subtitle: 'هامش الربحية',
          ),
        ),
      ],
    );
  }
}

class IncomeStatementCategoryWidget extends StatelessWidget {
  final IncomeStatementEntity category;
  final String Function(double) formatCurrency;

  const IncomeStatementCategoryWidget({
    super.key,
    required this.category,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppConstant.defaultPadding,
          child: Text(
            category.categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blueGrey,
            ),
          ),
        ),
        ...category.items.map(
          (i) => ListTile(
            dense: true,
            title: Text(i.accountName, style: const TextStyle(fontSize: 13)),
            trailing: Text(
              formatCurrency(i.amount),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي ${category.categoryName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                formatCurrency(category.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class IncomeStatementFinalResultWidget extends StatelessWidget {
  final IncomeStatementSummary summary;
  final String Function(double) formatCurrency;

  const IncomeStatementFinalResultWidget({
    super.key,
    required this.summary,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = summary.netIncome >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isProfit ? Colors.green[50] : Colors.red[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isProfit ? 'صافي الربح' : 'صافي الخسارة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green[800] : Colors.red[800],
            ),
          ),
          Text(
            formatCurrency(summary.netIncome),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }
}
