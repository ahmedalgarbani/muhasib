import 'package:flutter/material.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class IncomeStatementReportPage extends StatelessWidget {
  const IncomeStatementReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'قائمة الدخل',
      icon: Icons.trending_up,
      color: const Color(0xFF388E3C),
      reportBuilder: (filter) => _IncomeStatementContent(filter: filter),
    );
  }
}

class _IncomeStatementContent extends StatelessWidget {
  final ReportFilter filter;

  const _IncomeStatementContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary cards
          const ReportSummaryRow(
            cards: [
              ReportSummaryCard(
                title: 'إجمالي الإيرادات',
                value: '180,000 ر.س',
                icon: Icons.trending_up,
                color: Colors.green,
                change: 15.2,
              ),
              ReportSummaryCard(
                title: 'إجمالي المصروفات',
                value: '140,000 ر.س',
                icon: Icons.trending_down,
                color: Colors.red,
                change: 8.5,
              ),
              ReportSummaryCard(
                title: 'صافي الربح',
                value: '40,000 ر.س',
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
                change: 22.5,
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

                  // Revenue section
                  _buildSectionHeader('الإيرادات', Colors.green),
                  _buildLineItem('إيرادات المبيعات', 150000),
                  _buildLineItem('إيرادات الخدمات', 25000),
                  _buildLineItem('إيرادات أخرى', 5000),
                  _buildTotalLine('إجمالي الإيرادات', 180000, Colors.green),

                  const Divider(height: 1),

                  // Cost of Sales section
                  _buildSectionHeader('تكلفة المبيعات', Colors.orange),
                  _buildLineItem('تكلفة البضاعة المباعة', 100000),
                  _buildLineItem('مصاريف شحن المشتريات', 5000),
                  _buildTotalLine('إجمالي تكلفة المبيعات', 105000, Colors.orange),

                  const Divider(height: 1),
                  _buildTotalLine('مجمل الربح', 75000, Colors.blue, isBold: true),
                  const Divider(height: 1),

                  // Operating Expenses section
                  _buildSectionHeader('المصروفات التشغيلية', Colors.red),
                  _buildLineItem('رواتب وأجور', 20000),
                  _buildLineItem('إيجارات', 8000),
                  _buildLineItem('كهرباء ومياه', 2000),
                  _buildLineItem('مصاريف إدارية', 3000),
                  _buildLineItem('مصاريف تسويق', 2000),
                  _buildTotalLine('إجمالي المصروفات التشغيلية', 35000, Colors.red),

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
                          '40,000 ر.س',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
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

