import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class IncomeStatementReportPage extends StatelessWidget {
  const IncomeStatementReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<IncomeStatementCubit>()..loadIncomeStatement(),
      child: ReportBasePage(
        title: 'قائمة الدخل',
        icon: Icons.trending_up,
        color: const Color(0xFF388E3C),
        reportBuilder: (filter) => _IncomeStatementContent(filter: filter),
      ),
    );
  }
}

class _IncomeStatementContent extends StatefulWidget {
  final ReportFilter filter;

  const _IncomeStatementContent({required this.filter});

  @override
  State<_IncomeStatementContent> createState() => _IncomeStatementContentState();
}

class _IncomeStatementContentState extends State<_IncomeStatementContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeStatementCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_IncomeStatementContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      context.read<IncomeStatementCubit>().updateDateRange(widget.filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomeStatementCubit, IncomeStatementState>(
      builder: (context, state) {
        if (state is IncomeStatementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is IncomeStatementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'خطأ: ${state.message}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<IncomeStatementCubit>().refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is IncomeStatementLoaded) {
          final summary = state.summary;
          final categories = state.categories;

          if (categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد بيانات في الفترة المحددة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Summary cards
                ReportSummaryRow(
                  cards: [
                    ReportSummaryCard(
                      title: 'إجمالي الإيرادات',
                      value: '${summary.totalRevenue.toStringAsFixed(0)} ر.س',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                    ReportSummaryCard(
                      title: 'إجمالي المصروفات',
                      value: '${(summary.totalCostOfSales + summary.totalOperatingExpenses + summary.totalOtherExpenses).toStringAsFixed(0)} ر.س',
                      icon: Icons.trending_down,
                      color: Colors.red,
                    ),
                    ReportSummaryCard(
                      title: 'صافي الربح',
                      value: '${summary.netIncome.toStringAsFixed(0)} ر.س',
                      icon: Icons.account_balance_wallet,
                      color: summary.netIncome >= 0 ? Colors.blue : Colors.red,
                    ),
                  ],
                ),

                // Income Statement Table
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF388E3C),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Text(
                            'قائمة الدخل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Dynamic sections from data
                        ...categories.expand((category) => [
                          _buildSectionHeader(
                            category.categoryName, 
                            _getCategoryColor(category.categoryCode),
                          ),
                          ...category.items.map((item) => 
                            _buildLineItem(item.accountName, item.amount)
                          ),
                          _buildTotalLine(
                            'إجمالي ${category.categoryName}', 
                            category.totalAmount, 
                            _getCategoryColor(category.categoryCode),
                          ),
                          const Divider(height: 1),
                        ]),

                        // Gross Profit (if applicable)
                        if (summary.grossProfit != 0)
                          _buildTotalLine('مجمل الربح', summary.grossProfit, Colors.blue, isBold: true),
                        if (summary.grossProfit != 0)
                          const Divider(height: 1),

                        // Net Income
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: const Color(0xFF388E3C).withOpacity(0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'صافي الربح',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${summary.netIncome.toStringAsFixed(0)} ر.س',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: summary.netIncome >= 0 ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }

  Color _getCategoryColor(String categoryCode) {
    switch (categoryCode) {
      case '4':
        return Colors.green;
      case '51':
        return Colors.orange;
      case '52':
        return Colors.red;
      case '53':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withOpacity(0.1),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLineItem(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(title),
          ),
          Text('${amount.toStringAsFixed(0)} ر.س'),
        ],
      ),
    );
  }

  Widget _buildTotalLine(String title, double amount, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isBold ? color.withOpacity(0.05) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} ر.س',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

