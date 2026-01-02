import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

/// Enhanced Sales Summary Report with:
/// 1. Revenue comparison with General Ledger
/// 2. Customer receivables summary
/// 3. Invoice status breakdown
class SalesSummaryReportPage extends StatelessWidget {
  const SalesSummaryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SalesSummaryCubit>()..loadSalesSummary(),
      child: ReportBasePage(
        title: 'ملخص المبيعات',
        icon: Icons.point_of_sale,
        color: const Color(0xFF1565C0),
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
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

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

  String _formatCurrency(double value) {
    return '${_numberFormat.format(value)} ر.س';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesSummaryCubit, SalesSummaryState>(
      builder: (context, state) {
        if (state is SalesSummaryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SalesSummaryError) {
          return Center(child: Text('خطأ: ${state.message}'));
        }

        if (state is SalesSummaryLoaded) {
          final summary = state.summary;

          return FutureBuilder<_LedgerComparison>(
            future: _loadLedgerComparison(widget.filter),
            builder: (context, ledgerSnapshot) {
              final ledgerData = ledgerSnapshot.data;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Summary Cards
                    _buildMainSummaryCards(summary),

                    const SizedBox(height: 16),

                    // Ledger Comparison Card (NEW)
                    if (ledgerData != null)
                      _buildLedgerComparisonCard(summary, ledgerData),

                    const SizedBox(height: 16),

                    // Financial Breakdown
                    _buildFinancialBreakdown(summary),

                    const SizedBox(height: 16),

                    // Invoice Status Breakdown
                    if (ledgerData != null)
                      _buildInvoiceStatusCard(ledgerData),

                    const SizedBox(height: 16),

                    // Top Products
                    if (summary.topProducts.isNotEmpty)
                      _buildTopProductsCard(summary),

                    const SizedBox(height: 16),

                    // Top Customers
                    if (summary.topCustomers.isNotEmpty)
                      _buildTopCustomersCard(summary),
                  ],
                ),
              );
            },
          );
        }

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }

  Widget _buildMainSummaryCards(dynamic summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryTile('إجمالي المبيعات', summary.totalSales, Colors.green, Icons.trending_up)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryTile('المرتجعات', summary.totalReturns, Colors.red, Icons.undo)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _buildSummaryTile('الخصومات', summary.totalDiscounts, Colors.orange, Icons.local_offer)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryTile('الضرائب', summary.totalTaxes, Colors.purple, Icons.receipt)),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('صافي المبيعات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    _formatCurrency(summary.netSales),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatCurrency(value), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLedgerComparisonCard(dynamic summary, _LedgerComparison ledger) {
    final difference = summary.netSales - ledger.salesRevenue;
    final isMatch = difference.abs() < 0.01;

    return Card(
      color: isMatch ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isMatch ? Icons.check_circle : Icons.warning,
                    color: isMatch ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(
                  isMatch ? 'متطابق مع دفتر الأستاذ ✓' : 'تحذير: يوجد فرق مع دفتر الأستاذ!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatch ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صافي المبيعات (الفواتير)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text(_formatCurrency(summary.netSales), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إيراد المبيعات (دفتر الأستاذ)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text(_formatCurrency(ledger.salesRevenue), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            if (!isMatch) ...[
              const SizedBox(height: 8),
              Text(
                'الفرق: ${_formatCurrency(difference.abs())}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialBreakdown(dynamic summary) {
    final totalSales = summary.totalSales;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text('التحليل المالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _buildBreakdownRow('عدد الفواتير', '${summary.invoiceCount}', null),
            _buildBreakdownRow('عدد المرتجعات', '${summary.returnCount}', null),
            _buildBreakdownRow('عدد العملاء', '${summary.customerCount}', null),
            const Divider(),
            _buildBreakdownRow('نسبة المرتجعات', 
                '${totalSales > 0 ? (summary.totalReturns / totalSales * 100).toStringAsFixed(1) : 0}%',
                summary.totalReturns / totalSales > 0.1 ? Colors.red : Colors.green),
            _buildBreakdownRow('نسبة الخصومات',
                '${totalSales > 0 ? (summary.totalDiscounts / totalSales * 100).toStringAsFixed(1) : 0}%',
                null),
            _buildBreakdownRow('متوسط الفاتورة',
                _formatCurrency(summary.invoiceCount > 0 ? summary.totalSales / summary.invoiceCount : 0),
                null),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatusCard(_LedgerComparison ledger) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.purple),
                SizedBox(width: 8),
                Text('حالة الفواتير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _buildStatusRow('فواتير مع قيود', ledger.invoicesWithEntry, Colors.green),
            _buildStatusRow('فواتير بدون قيود', ledger.invoicesWithoutEntry, 
                ledger.invoicesWithoutEntry > 0 ? Colors.red : Colors.grey),
            if (ledger.invoicesWithoutEntry > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يوجد فواتير بدون قيود محاسبية - يرجى مراجعتها!',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard(dynamic summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.inventory_2, color: Colors.purple),
        title: const Text('أكثر المنتجات مبيعًا'),
        children: [
          ...summary.topProducts.take(5).map((p) => ListTile(
            dense: true,
            title: Text(p.productName),
            subtitle: Text('الكمية: ${p.quantity.toStringAsFixed(0)} | المرات: ${p.salesCount}'),
            trailing: Text(_formatCurrency(p.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Widget _buildTopCustomersCard(dynamic summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.people, color: Colors.teal),
        title: const Text('أكثر العملاء شراءً'),
        children: [
          ...summary.topCustomers.take(5).map((c) => ListTile(
            dense: true,
            title: Text(c.customerName),
            subtitle: Text('عدد الفواتير: ${c.invoiceCount}'),
            trailing: Text(_formatCurrency(c.totalPurchases), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Future<_LedgerComparison> _loadLedgerComparison(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;

    String dateFilter = '';
    final args = <Object?>[];
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    // Get sales revenue from General Ledger (Sales accounts - type=3 or code starts with 41)
    final salesRevenueResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as revenue
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE je.is_posted = 1 
        AND (a.type = 3 OR a.code LIKE '41%')
        AND je.reference_type LIKE '%sale%'
        $dateFilter
    ''', args);
    
    final salesRevenue = (salesRevenueResult.first['revenue'] as num?)?.toDouble() ?? 0.0;

    // Check invoices with/without journal entries
    String invoiceDateFilter = '';
    final invoiceArgs = <Object?>[1]; // invoice_type = 1 (sales)
    if (filter.startDate != null && filter.endDate != null) {
      invoiceDateFilter = 'AND date >= ? AND date <= ?';
      invoiceArgs.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      invoiceArgs.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final invoiceStatusResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN EXISTS (
          SELECT 1 FROM journal_entries je 
          WHERE je.reference_type = 'sales_invoice' AND je.reference_id = i.id
        ) THEN 1 END) as with_entry
      FROM invoices i
      WHERE invoice_type = ?
      $invoiceDateFilter
    ''', invoiceArgs);

    final total = (invoiceStatusResult.first['total'] as int?) ?? 0;
    final withEntry = (invoiceStatusResult.first['with_entry'] as int?) ?? 0;

    return _LedgerComparison(
      salesRevenue: salesRevenue,
      invoicesWithEntry: withEntry,
      invoicesWithoutEntry: total - withEntry,
    );
  }
}

class _LedgerComparison {
  final double salesRevenue;
  final int invoicesWithEntry;
  final int invoicesWithoutEntry;

  const _LedgerComparison({
    required this.salesRevenue,
    required this.invoicesWithEntry,
    required this.invoicesWithoutEntry,
  });
}
