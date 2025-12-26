import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/sales_summary_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class SalesSummaryReportPage extends StatelessWidget {
  const SalesSummaryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SalesSummaryCubit>()..loadSalesSummary(),
      child: ReportBasePage(
        title: 'ملخص المبيعات',
        icon: Icons.summarize,
        color: const Color(0xFF388E3C),
        reportBuilder: (filter) => _SalesSummaryContent(filter: filter),
      ),
    );
  }
}

class _SalesSummaryContent extends StatefulWidget {
  final ReportFilter filter;

  const _SalesSummaryContent({required this.filter});

  @override
  State<_SalesSummaryContent> createState() => _SalesSummaryContentState();
}

class _SalesSummaryContentState extends State<_SalesSummaryContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesSummaryCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_SalesSummaryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      context.read<SalesSummaryCubit>().updateDateRange(widget.filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesSummaryCubit, SalesSummaryState>(
      builder: (context, state) {
        if (state is SalesSummaryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SalesSummaryError) {
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
                    context.read<SalesSummaryCubit>().refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is SalesSummaryLoaded) {
          final summary = state.summary;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                ReportSummaryRow(
                  cards: [
                    ReportSummaryCard(
                      title: 'إجمالي المبيعات',
                      value: '${summary.totalSales.toStringAsFixed(0)} ر.س',
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    ReportSummaryCard(
                      title: 'عدد الفواتير',
                      value: '${summary.invoiceCount}',
                      icon: Icons.receipt,
                      color: Colors.blue,
                    ),
                    ReportSummaryCard(
                      title: 'الخصومات',
                      value: '${summary.totalDiscounts.toStringAsFixed(0)} ر.س',
                      icon: Icons.discount,
                      color: Colors.orange,
                    ),
                    ReportSummaryCard(
                      title: 'صافي المبيعات',
                      value: '${summary.netSales.toStringAsFixed(0)} ر.س',
                      icon: Icons.account_balance_wallet,
                      color: Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Daily Sales Chart
                if (summary.dailySales.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المبيعات اليومية',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildDailySalesChart(summary.dailySales),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (summary.dailySales.isNotEmpty)
                  const SizedBox(height: 16),

                // Top products
                if (summary.topProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أكثر المنتجات مبيعاً',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildTopProductsList(summary.topProducts),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (summary.topProducts.isNotEmpty)
                  const SizedBox(height: 16),

                // Top customers
                if (summary.topCustomers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أكثر العملاء شراءً',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildTopCustomersList(summary.topCustomers),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        }

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }

  Widget _buildDailySalesChart(Map<String, double> dailySales) {
    if (dailySales.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)),
      );
    }

    final entries = dailySales.entries.toList();
    if (entries.length > 7) {
      entries.removeRange(0, entries.length - 7);
    }

    final maxValue = entries.isEmpty ? 1.0 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((entry) {
        final heightPercent = maxValue > 0 ? entry.value / maxValue : 0.0;
        final date = DateTime.tryParse(entry.key);
        final dayName = _getDayName(date);
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(entry.value / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 140 * heightPercent,
                decoration: BoxDecoration(
                  color: const Color(0xFF388E3C),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dayName,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(DateTime? date) {
    if (date == null) return '';
    final days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[date.weekday % 7];
  }

  Widget _buildTopProductsList(List<TopProductEntity> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text('لا توجد منتجات', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: products.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: index < products.length - 1
                ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF388E3C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${product.quantity.toStringAsFixed(0)} وحدة', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text(
                '${product.totalAmount.toStringAsFixed(0)} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCustomersList(List<TopCustomerEntity> customers) {
    if (customers.isEmpty) {
      return const Center(
        child: Text('لا يوجد عملاء', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: customers.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final customer = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: index < customers.length - 1
                ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF388E3C).withOpacity(0.1),
                child: Text(
                  customer.customerName.isNotEmpty ? customer.customerName.substring(0, 1) : '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${customer.invoiceCount} فاتورة', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text(
                '${customer.totalPurchases.toStringAsFixed(0)} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

