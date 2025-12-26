import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class PurchaseSummaryReportPage extends StatelessWidget {
  const PurchaseSummaryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'ملخص المشتريات',
      icon: Icons.shopping_cart,
      color: const Color(0xFF1976D2),
      reportBuilder: (filter) => _PurchaseSummaryContent(filter: filter),
    );
  }
}

class _PurchaseSummaryContent extends StatelessWidget {
  final ReportFilter filter;

  const _PurchaseSummaryContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PurchaseSummaryResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي المشتريات',
                  value: data.totalPurchases.toStringAsFixed(2),
                  icon: Icons.shopping_cart,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'مرتجعات المشتريات',
                  value: data.totalReturns.toStringAsFixed(2),
                  icon: Icons.assignment_return,
                  color: Colors.red,
                ),
                ReportSummaryCard(
                  title: 'صافي المشتريات',
                  value: data.netPurchases.toStringAsFixed(2),
                  icon: Icons.calculate,
                  color: Colors.blue,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section(
                    title: 'أفضل الموردين',
                    rows: data.topSuppliers,
                    empty: 'لا توجد بيانات',
                  ),
                  const SizedBox(height: 12),
                  _section(
                    title: 'أفضل الأصناف',
                    rows: data.topProducts,
                    empty: 'لا توجد بيانات',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _section({
    required String title,
    required List<_NameTotalRow> rows,
    required String empty,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(empty),
              )
            else
              ...rows.map(
                (r) => ListTile(
                  dense: true,
                  title: Text(r.name),
                  trailing: Text(
                    r.total.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<_PurchaseSummaryResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND i.date >= ? AND i.date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final totals = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as total_purchases,
        COALESCE(SUM(CASE WHEN i.invoice_type = 5 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as total_returns
      FROM invoices i
      WHERE (i.invoice_type = 2 OR i.invoice_type = 5)
      $dateFilter
      ''',
      args,
    );

    final totalPurchases = (totals.first['total_purchases'] as num?)?.toDouble() ?? 0.0;
    final totalReturns = (totals.first['total_returns'] as num?)?.toDouble() ?? 0.0;

    final topSuppliers = await db.rawQuery(
      '''
      SELECT
        c.name as name,
        COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total
      FROM invoices i
      INNER JOIN customers c ON c.id = i.customer_id
      WHERE i.invoice_type = 2
      $dateFilter
      GROUP BY c.id, c.name
      ORDER BY total DESC
      LIMIT 10
      ''',
      args,
    );

    final topProducts = await db.rawQuery(
      '''
      SELECT
        cat.name as name,
        COALESCE(SUM(il.total_amount), 0) as total
      FROM invoice_lines il
      INNER JOIN invoices i ON i.id = il.invoice_id
      LEFT JOIN categories cat ON cat.id = il.category_id
      WHERE i.invoice_type = 2
      $dateFilter
      GROUP BY cat.id, cat.name
      ORDER BY total DESC
      LIMIT 10
      ''',
      args,
    );

    return _PurchaseSummaryResult(
      totalPurchases: totalPurchases,
      totalReturns: totalReturns,
      topSuppliers: topSuppliers
          .map((m) => _NameTotalRow((m['name'] as String?) ?? '', (m['total'] as num?)?.toDouble() ?? 0.0))
          .toList(),
      topProducts: topProducts
          .map((m) => _NameTotalRow((m['name'] as String?) ?? '', (m['total'] as num?)?.toDouble() ?? 0.0))
          .toList(),
    );
  }
}

class _PurchaseSummaryResult {
  final double totalPurchases;
  final double totalReturns;
  final List<_NameTotalRow> topSuppliers;
  final List<_NameTotalRow> topProducts;

  const _PurchaseSummaryResult({
    required this.totalPurchases,
    required this.totalReturns,
    required this.topSuppliers,
    required this.topProducts,
  });

  double get netPurchases => totalPurchases - totalReturns;
}

class _NameTotalRow {
  final String name;
  final double total;
  const _NameTotalRow(this.name, this.total);
}


