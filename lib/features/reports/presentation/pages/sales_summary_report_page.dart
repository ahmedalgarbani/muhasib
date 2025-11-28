import 'package:flutter/material.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class SalesSummaryReportPage extends StatelessWidget {
  const SalesSummaryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'ملخص المبيعات',
      icon: Icons.summarize,
      color: const Color(0xFF388E3C),
      reportBuilder: (filter) => _SalesSummaryContent(filter: filter),
    );
  }
}

class _SalesSummaryContent extends StatelessWidget {
  final ReportFilter filter;

  const _SalesSummaryContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          ReportSummaryRow(
            cards: const [
              ReportSummaryCard(
                title: 'إجمالي المبيعات',
                value: '125,500 ر.س',
                icon: Icons.attach_money,
                color: Colors.green,
                change: 12.5,
              ),
              ReportSummaryCard(
                title: 'عدد الفواتير',
                value: '45',
                icon: Icons.receipt,
                color: Colors.blue,
                change: 8.2,
              ),
              ReportSummaryCard(
                title: 'الخصومات',
                value: '3,200 ر.س',
                icon: Icons.discount,
                color: Colors.orange,
                change: -5.0,
              ),
              ReportSummaryCard(
                title: 'الضرائب',
                value: '18,825 ر.س',
                icon: Icons.percent,
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Charts section
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
                      'المبيعات حسب الفترة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildSimpleBarChart(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Top products
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
                    _buildTopProductsList(),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Top customers
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
                    _buildTopCustomersList(),
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

  Widget _buildSimpleBarChart() {
    final data = [
      _ChartData('السبت', 15000),
      _ChartData('الأحد', 22000),
      _ChartData('الاثنين', 18500),
      _ChartData('الثلاثاء', 25000),
      _ChartData('الأربعاء', 20000),
      _ChartData('الخميس', 28000),
      _ChartData('الجمعة', 12000),
    ];

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final heightPercent = item.value / maxValue;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${(item.value / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 140 * heightPercent,
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTopProductsList() {
    final products = [
      _ProductSale('هاتف آيفون 15', 25, 45000),
      _ProductSale('سماعات أيربودز', 40, 28000),
      _ProductSale('شاحن سريع', 85, 12750),
      _ProductSale('كفر حماية', 120, 9600),
      _ProductSale('واقي شاشة', 200, 8000),
    ];

    return Column(
      children: products.asMap().entries.map((entry) {
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
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${product.quantity} وحدة', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text(
                '${product.total.toStringAsFixed(0)} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCustomersList() {
    final customers = [
      _CustomerSale('شركة التقنية المتقدمة', 12, 35000),
      _CustomerSale('مؤسسة الأمل', 8, 22500),
      _CustomerSale('محمد أحمد', 15, 18000),
      _CustomerSale('سارة خالد', 6, 12000),
      _CustomerSale('عبدالله محمد', 10, 9500),
    ];

    return Column(
      children: customers.asMap().entries.map((entry) {
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
                  customer.name.substring(0, 1),
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
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${customer.invoiceCount} فاتورة', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text(
                '${customer.total.toStringAsFixed(0)} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}

class _ProductSale {
  final String name;
  final int quantity;
  final double total;
  _ProductSale(this.name, this.quantity, this.total);
}

class _CustomerSale {
  final String name;
  final int invoiceCount;
  final double total;
  _CustomerSale(this.name, this.invoiceCount, this.total);
}

