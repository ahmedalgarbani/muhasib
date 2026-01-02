import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

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
  final _numberFormat = NumberFormat('#,##0', 'ar');

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

  String _formatCurrency(double value) {
    return '${_numberFormat.format(value)} ر.س';
  }

  String _formatPercentage(double? value) {
    if (value == null) return '-';
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
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
                // Summary Cards Row
                _buildSummaryCards(summary),

                // Profit Margins Section
                if (summary.totalRevenue > 0) _buildProfitMarginsCard(summary),

                // Income Statement Table
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'قائمة الدخل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (summary.previousNetIncome != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        summary.isImproved == true ? Icons.trending_up : Icons.trending_down,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatPercentage(summary.netIncomeGrowth),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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

                        // Gross Profit
                        if (summary.grossProfit != 0) ...[
                          _buildHighlightedLine(
                            'مجمل الربح', 
                            summary.grossProfit, 
                            Colors.blue,
                            subtitle: 'هامش الربح: ${summary.grossProfitMargin.toStringAsFixed(1)}%',
                          ),
                          const Divider(height: 1),
                        ],

                        // Operating Income
                        if (summary.operatingIncome != summary.grossProfit) ...[
                          _buildHighlightedLine(
                            'الربح التشغيلي', 
                            summary.operatingIncome, 
                            Colors.indigo,
                            subtitle: 'هامش الربح التشغيلي: ${summary.operatingProfitMargin.toStringAsFixed(1)}%',
                          ),
                          const Divider(height: 1),
                        ],

                        // Net Income Before Tax (if tax exists)
                        if (summary.taxExpense > 0) ...[
                          _buildTotalLine('صافي الربح قبل الضريبة', summary.netIncomeBeforeTax, Colors.purple),
                          _buildTotalLine('ضريبة الدخل', summary.taxExpense, Colors.red),
                          const Divider(height: 1),
                        ],

                        // Final Net Income
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: summary.netIncome >= 0 
                                ? const Color(0xFF388E3C).withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'صافي الربح',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'هامش الربح: ${summary.netProfitMargin.toStringAsFixed(1)}%',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatCurrency(summary.netIncome),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: summary.netIncome >= 0 ? Colors.green[700] : Colors.red[700],
                                        ),
                                      ),
                                      if (summary.previousNetIncome != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              summary.isImproved == true ? Icons.arrow_upward : Icons.arrow_downward,
                                              size: 12,
                                              color: summary.isImproved == true ? Colors.green : Colors.red,
                                            ),
                                            Text(
                                              _formatPercentage(summary.netIncomeGrowth),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: summary.isImproved == true ? Colors.green : Colors.red,
                                              ),
                                            ),
                                            Text(
                                              ' عن الفترة السابقة',
                                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
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

  Widget _buildSummaryCards(IncomeStatementSummary summary) {
    final totalExpenses = summary.totalCostOfSales + 
                          summary.totalOperatingExpenses + 
                          summary.totalOtherExpenses +
                          summary.taxExpense;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildSummaryCard(
            'إجمالي الإيرادات',
            summary.totalRevenue,
            Icons.trending_up,
            Colors.green,
            growth: summary.revenueGrowth,
          ),
          if (summary.totalOtherIncome > 0)
            _buildSummaryCard(
              'إيرادات أخرى',
              summary.totalOtherIncome,
              Icons.attach_money,
              Colors.teal,
            ),
          _buildSummaryCard(
            'إجمالي المصروفات',
            totalExpenses,
            Icons.trending_down,
            Colors.red,
          ),
          _buildSummaryCard(
            'صافي الربح',
            summary.netIncome,
            summary.netIncome >= 0 ? Icons.account_balance_wallet : Icons.warning,
            summary.netIncome >= 0 ? Colors.blue : Colors.red,
            growth: summary.netIncomeGrowth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    IconData icon,
    Color color, {
    double? growth,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (growth != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: growth >= 0 ? Colors.green : Colors.red,
                ),
                Text(
                  _formatPercentage(growth),
                  style: TextStyle(
                    fontSize: 11,
                    color: growth >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfitMarginsCard(IncomeStatementSummary summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'نسب الربحية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMarginIndicator(
                      'هامش الربح الإجمالي',
                      summary.grossProfitMargin,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMarginIndicator(
                      'هامش الربح التشغيلي',
                      summary.operatingProfitMargin,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMarginIndicator(
                      'هامش الربح الصافي',
                      summary.netProfitMargin,
                      summary.netProfitMargin >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarginIndicator(String title, double percentage, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String categoryCode) {
    if (categoryCode.startsWith('4') || categoryCode == '42') {
      return Colors.green;  // Revenue
    } else if (categoryCode == '311') {
      return Colors.orange;  // Cost of Sales
    } else if (categoryCode == '31x') {
      return Colors.red;  // Operating Expenses
    } else if (categoryCode == '316') {
      return Colors.purple;  // Tax
    } else {
      return Colors.grey;  // Other
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ),
          Text(_formatCurrency(amount)),
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
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedLine(String title, double amount, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
            ],
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
