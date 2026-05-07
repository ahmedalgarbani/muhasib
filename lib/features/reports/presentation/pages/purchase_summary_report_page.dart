import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

class PurchaseSummaryReportPage extends StatefulWidget {
  const PurchaseSummaryReportPage({super.key});
  @override
  State<PurchaseSummaryReportPage> createState() => _PurchaseSummaryReportPageState();
}

class _PurchaseSummaryReportPageState extends State<PurchaseSummaryReportPage> {
  _PurchaseSummaryResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير ملخص المشتريات',
      icon: Icons.shopping_basket,
      color: const Color(0xFFE64A19),
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _PurchaseSummaryContent(filter: filter, onLoad: (r) => setState(() => _lastResult = r)),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final data = [
      ['إجمالي المشتريات', _lastResult!.totalPurchases.toStringAsFixed(2)],
      ['المرتجعات', _lastResult!.totalReturns.toStringAsFixed(2)],
      ['صافي المشتريات', _lastResult!.netPurchases.toStringAsFixed(2)],
      ['الضرائب', _lastResult!.totalTaxes.toStringAsFixed(2)],
      ['الخصومات', _lastResult!.totalDiscounts.toStringAsFixed(2)],
    ];
    await ExportService.printData(title: 'ملخص المشتريات', headers: ['البيان', 'المبلغ'], data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    await ExportService.exportToExcel(fileName: 'purchase_summary', headers: ['البيان', 'المبلغ'], data: [['إجمالي المشتريات', _lastResult!.totalPurchases.toStringAsFixed(2)], ['المرتجعات', _lastResult!.totalReturns.toStringAsFixed(2)], ['صافي المشتريات', _lastResult!.netPurchases.toStringAsFixed(2)]]);
  }
}

class _PurchaseSummaryContent extends StatelessWidget {
  final ReportFilter filter;
  final Function(_PurchaseSummaryResult) onLoad;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');
  _PurchaseSummaryContent({required this.filter, required this.onLoad});

  String _format(double v) => '${_numberFormat.format(v)} ر.س';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PurchaseSummaryResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('خطأ: ${snapshot.error}'));
        final data = snapshot.data;
        if (data != null) WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(data));
        if (data == null) return const Center(child: Text('لا توجد بيانات'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildMainStat(data),
            const SizedBox(height: 16),
            _buildDetailsRow(data),
            const SizedBox(height: 16),
            _buildTopSuppliers(data),
          ]),
        );
      },
    );
  }

  Widget _buildMainStat(_PurchaseSummaryResult d) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE64A19), Color(0xFFFF7043)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.2), blurRadius: 10)]),
      child: Column(children: [
        const Text('صافي مشتريات الفترة', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(_format(d.netPurchases), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24, height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _miniStat('إجمالي', _format(d.totalPurchases)),
          _miniStat('المرتجعات', _format(d.totalReturns)),
          _miniStat('الفواتير', '${d.invoiceCount}'),
        ]),
      ]),
    );
  }

  Widget _miniStat(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.white, fontSize: 10)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]);

  Widget _buildDetailsRow(_PurchaseSummaryResult d) => Row(children: [Expanded(child: _infoCard('الضرائب', d.totalTaxes, Colors.purple, Icons.receipt)), const SizedBox(width: 12), Expanded(child: _infoCard('الخصومات', d.totalDiscounts, Colors.teal, Icons.local_offer))]);

  Widget _infoCard(String l, double v, Color c, IconData i) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.1))), child: Row(children: [Icon(i, color: c, size: 20), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), Text(_format(v), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c))])]));

  Widget _buildTopSuppliers(_PurchaseSummaryResult d) {
    if (d.topSuppliers.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[200]!)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.local_shipping, color: Colors.blue),
        title: const Text('أكثر الموردين تعاملاً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: d.topSuppliers.take(5).map<Widget>((s) => ListTile(dense: true, title: Text(s.name, style: const TextStyle(fontSize: 13)), trailing: Text(_format(s.total), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
      ),
    );
  }

  Future<_PurchaseSummaryResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      df = 'AND i.date >= ? AND i.date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }
    final totals = await db.rawQuery('SELECT COUNT(CASE WHEN i.invoice_type = 2 THEN 1 END) as ic, COUNT(CASE WHEN i.invoice_type = 5 THEN 1 END) as rc, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as tp, COALESCE(SUM(CASE WHEN i.invoice_type = 5 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as tr, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.tax_amt, 0) END), 0) as tx, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.discount_amt, 0) END), 0) as td FROM invoices i WHERE (i.invoice_type = 2 OR i.invoice_type = 5) AND COALESCE(i.approval_status, 1) != 3 $df', args);
    final top = await db.rawQuery('SELECT c.name, COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total FROM invoices i JOIN customers c ON c.id = i.customer_id WHERE i.invoice_type = 2 AND COALESCE(i.approval_status, 1) != 3 $df GROUP BY c.id ORDER BY total DESC LIMIT 5', args);
    return _PurchaseSummaryResult(totalPurchases: (totals.first['tp'] as num).toDouble(), totalReturns: (totals.first['tr'] as num).toDouble(), totalTaxes: (totals.first['tx'] as num).toDouble(), totalDiscounts: (totals.first['td'] as num).toDouble(), invoiceCount: totals.first['ic'] as int, topSuppliers: top.map((m) => _SupplierRow(name: m['name'] as String, total: (m['total'] as num).toDouble())).toList());
  }
}

class _PurchaseSummaryResult { final double totalPurchases, totalReturns, totalTaxes, totalDiscounts; final int invoiceCount; final List<_SupplierRow> topSuppliers; _PurchaseSummaryResult({required this.totalPurchases, required this.totalReturns, required this.totalTaxes, required this.totalDiscounts, required this.invoiceCount, required this.topSuppliers}); double get netPurchases => totalPurchases - totalReturns; }
class _SupplierRow { final String name; final double total; _SupplierRow({required this.name, required this.total}); }
