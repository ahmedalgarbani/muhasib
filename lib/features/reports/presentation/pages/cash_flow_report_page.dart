import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class CashFlowReportPage extends StatefulWidget {
  const CashFlowReportPage({super.key});
  @override
  State<CashFlowReportPage> createState() => _CashFlowReportPageState();
}

class _CashFlowReportPageState extends State<CashFlowReportPage> {
  _CashFlowResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير التدفقات النقدية',
      icon: Icons.water_drop,
      color: AppColors.materialCyan700,
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _CashFlowContent(filter: filter, onLoad: (r) => setState(() => _lastResult = r)),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final headers = ['الأنشطة', 'المبلغ'];
    final data = [
      ['الرصيد الافتتاحي', _lastResult!.openingBalance.toStringAsFixed(2)],
      ['صافي التدفق التشغيلي', _lastResult!.totalOperating.toStringAsFixed(2)],
      ['صافي التدفق الاستثماري', _lastResult!.totalInvesting.toStringAsFixed(2)],
      ['صافي التدفق التمويلي', _lastResult!.totalFinancing.toStringAsFixed(2)],
      ['صافي التدفق النقدي', _lastResult!.netCashFlow.toStringAsFixed(2)],
      ['الرصيد الختامي', _lastResult!.closingBalance.toStringAsFixed(2)],
    ];
    await ExportService.printData(title: 'تقرير التدفقات النقدية', headers: headers, data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    final path = await ExportService.exportToExcel(fileName: 'cash_flow', headers: ['النشاط', 'صافي القيمة'], data: [['التشغيلية', _lastResult!.totalOperating.toStringAsFixed(2)], ['الاستثمارية', _lastResult!.totalInvesting.toStringAsFixed(2)], ['التمويلية', _lastResult!.totalFinancing.toStringAsFixed(2)], ['الصافي العام', _lastResult!.netCashFlow.toStringAsFixed(2)]]);
    AppToast.showSuccess(context, 'تم تصدير Excel: $path');
  }
}

class _CashFlowContent extends StatelessWidget {
  final ReportFilter filter;
  final Function(_CashFlowResult) onLoad;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');
  _CashFlowContent({required this.filter, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CashFlowResult>(
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
            _buildQuickStat(data),
            const SizedBox(height: 16),
            _buildSection('الأنشطة التشغيلية', data.totalOperating, Colors.blue, Icons.business),
            const SizedBox(height: 12),
            _buildSection('الأنشطة الاستثمارية', data.totalInvesting, Colors.orange, Icons.trending_up),
            const SizedBox(height: 12),
            _buildSection('الأنشطة التمويلية', data.totalFinancing, Colors.purple, Icons.account_balance),
            const SizedBox(height: 20),
            _buildFinalSummary(data),
          ]),
        );
      },
    );
  }

  Widget _buildQuickStat(_CashFlowResult d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10)]),
      child: Column(children: [
        const Text('صافي التدفق النقدي', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Text('${_numberFormat.format(d.netCashFlow)} ر.س', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24, height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _mini('بداية', d.openingBalance),
          _mini('نهاية', d.closingBalance),
        ]),
      ]),
    );
  }

  Widget _mini(String l, double v) => Column(children: [Text(l, style: const TextStyle(color: Colors.white60, fontSize: 10)), Text(_numberFormat.format(v), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]);

  Widget _buildSection(String l, double v, Color c, IconData i) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg20), border: Border.all(color: Colors.grey[100]!)),
      child: Row(children: [
        Icon(i, color: c, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Text('${_numberFormat.format(v)} ر.س', style: TextStyle(color: v >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  Widget _buildFinalSummary(_CashFlowResult d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(AppRadius.lg20), border: Border.all(color: Colors.grey[200]!)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('التوافق مع أرصدة النقد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(d.closingBalance.toStringAsFixed(2) == d.actualCashBalance.toStringAsFixed(2) ? 'متطابق ✓' : 'فرق: ${(d.closingBalance - d.actualCashBalance).abs().toStringAsFixed(1)}', style: TextStyle(color: d.closingBalance.toStringAsFixed(2) == d.actualCashBalance.toStringAsFixed(2) ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Future<_CashFlowResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final connects = await db.rawQuery('SELECT a.id FROM account_connects ac JOIN accounts a ON a.c_id = ac.c_id WHERE ac.account_connect_type IN (0, 1)');
    final ids = connects.map((m) => m['id'] as int).toList();
    if (ids.isEmpty) return _CashFlowResult.empty();

    final start = (filter.startDate ?? DateTime(2020)).millisecondsSinceEpoch ~/ 1000;
    final end = (filter.endDate ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

    final openRes = await db.rawQuery('SELECT COALESCE(SUM(debit_amount - credit_amount), 0) as b FROM journal_entry_lines jel JOIN journal_entries je ON je.id = jel.journal_entry_id WHERE je.is_posted = 1 AND jel.account_id IN (${ids.join(',')}) AND je.entry_date < ?', [start]);
    final open = (openRes.first['b'] as num).toDouble();

    final actualRes = await db.rawQuery('SELECT COALESCE(SUM(debit_amount - credit_amount), 0) as b FROM journal_entry_lines jel JOIN journal_entries je ON je.id = jel.journal_entry_id WHERE je.is_posted = 1 AND jel.account_id IN (${ids.join(',')}) AND je.entry_date <= ?', [end]);
    final actual = (actualRes.first['b'] as num).toDouble();

    final rows = await db.rawQuery('SELECT je.reference_type, COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as net FROM journal_entry_lines jel JOIN journal_entries je ON je.id = jel.journal_entry_id WHERE je.is_posted = 1 AND jel.account_id IN (${ids.join(',')}) AND je.entry_date >= ? AND je.entry_date <= ? GROUP BY je.reference_type', [start, end]);

    double op = 0, inv = 0, fin = 0;
    for (final r in rows) {
      final n = (r['net'] as num).toDouble();
      final type = r['reference_type'] as String? ?? '';
      if (type.contains('sale') || type.contains('purchase') || type.contains('receipt') || type.contains('payment')) {
        op += n;
      } else if (type.contains('asset') || type.contains('investment')) inv += n;
      else if (type.contains('loan') || type.contains('capital')) fin += n;
      else op += n;
    }

    return _CashFlowResult(openingBalance: open, actualCashBalance: actual, totalOperating: op, totalInvesting: inv, totalFinancing: fin);
  }
}

class _CashFlowResult {
  final double openingBalance, actualCashBalance, totalOperating, totalInvesting, totalFinancing;
  _CashFlowResult({required this.openingBalance, required this.actualCashBalance, required this.totalOperating, required this.totalInvesting, required this.totalFinancing});
  double get netCashFlow => totalOperating + totalInvesting + totalFinancing;
  double get closingBalance => openingBalance + netCashFlow;
  factory _CashFlowResult.empty() => _CashFlowResult(openingBalance: 0, actualCashBalance: 0, totalOperating: 0, totalInvesting: 0, totalFinancing: 0);
}
