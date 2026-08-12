import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class BalanceSheetReportPage extends StatefulWidget {
  const BalanceSheetReportPage({super.key});
  @override
  State<BalanceSheetReportPage> createState() => _BalanceSheetReportPageState();
}

class _BalanceSheetReportPageState extends State<BalanceSheetReportPage> {
  _BalanceSheetResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير الميزانية العمومية',
      icon: Icons.account_balance,
      color: AppColors.materialPurple900,
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _BalanceSheetContent(filter: filter, onLoad: (r) => setState(() => _lastResult = r)),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final headers = ['البند', 'المبلغ'];
    final List<List<String>> data = [];
    data.add(['الأصول', '']);
    for (var r in _lastResult!.currentAssets) data.add(['  ${r.code} - ${r.name}', r.displayAmount.toStringAsFixed(2)]);
    data.add(['إجمالي الأصول', _lastResult!.totalAssets.toStringAsFixed(2)]);
    data.add(['الخصوم وحقوق الملكية', '']);
    for (var r in _lastResult!.equityRows) data.add(['  ${r.code} - ${r.name}', r.displayAmount.toStringAsFixed(2)]);
    data.add(['الإجمالي', (_lastResult!.totalLiabilities + _lastResult!.totalEquity).toStringAsFixed(2)]);

    await ExportService.printData(title: 'الميزانية العمومية', headers: headers, data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    final path = await ExportService.exportToExcel(fileName: 'balance_sheet', headers: ['كود الحساب', 'الاسم', 'المبلغ'], data: _lastResult!.currentAssets.map((r) => [r.code, r.name, r.displayAmount.toStringAsFixed(2)]).toList());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تصدير Excel: $path')));
  }
}

class _BalanceSheetContent extends StatelessWidget {
  final ReportFilter filter;
  final Function(_BalanceSheetResult) onLoad;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');
  _BalanceSheetContent({required this.filter, required this.onLoad});

  String _format(double v) => '${_numberFormat.format(v)} ر.س';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BalanceSheetResult>(
      future: _load(getIt<DatabaseService>(), filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('خطأ: ${snapshot.error}'));
        final data = snapshot.data;
        if (data != null) WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(data));
        if (data == null) return const Center(child: Text('لا توجد بيانات'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildEquationSummary(data),
              const SizedBox(height: 16),
              _buildSectionTile('الأصول', data.totalAssets, Colors.green, Icons.trending_up, data.currentAssets),
              const SizedBox(height: 16),
              _buildSectionTile('الخصوم وحقوق الملكية', data.totalLiabilities + data.totalEquity, Colors.blue, Icons.account_balance_wallet, [...data.currentLiabilities, ...data.equityRows]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEquationSummary(_BalanceSheetResult d) {
    final ok = d.isBalanced;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ok ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: ok ? Colors.green : Colors.red, width: 0.5)),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.warning, color: ok ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 12),
        Text(ok ? 'الميزانية متوازنة تماماً ✓' : 'فرق الميزانية: ${d.difference.abs().toStringAsFixed(2)} ⚠', style: TextStyle(fontWeight: FontWeight.bold, color: ok ? Colors.green[800] : Colors.red[800], fontSize: 13)),
      ]),
    );
  }

  Widget _buildSectionTile(String t, double v, Color c, IconData i, List<_AccountBalanceRow> rows) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg20), side: BorderSide(color: Colors.grey[200]!)),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg20))), child: Row(children: [Icon(i, color: c, size: 20), const SizedBox(width: 8), Expanded(child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14))), Text(_format(v), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15))])),
        ...rows.take(5).map((r) => ListTile(dense: true, title: Text(r.name, style: const TextStyle(fontSize: 12)), trailing: Text(_format(r.displayAmount)))),
        if (rows.length > 5) Padding(padding: const EdgeInsets.all(8), child: Text('وعشرة حسابات أخرى...', style: TextStyle(color: Colors.grey[400], fontSize: 10))),
      ]),
    );
  }

  Future<_BalanceSheetResult> _load(DatabaseService dbs, ReportFilter f) async {
    final db = await dbs.database;
    final asOf = (f.endDate ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final startOfPeriod = (f.startDate ?? DateTime(DateTime.now().year, 1, 1)).millisecondsSinceEpoch ~/ 1000;

    final accounts = await db.rawQuery('''
      SELECT a.id, a.code, a.name, a.type, COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as net
      FROM accounts a LEFT JOIN journal_entry_lines jel ON jel.account_id = a.id LEFT JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND (je.is_posted = 1 OR je.id IS NULL) AND (je.entry_date <= ? OR je.id IS NULL) AND a.type IN (1, 2)
      GROUP BY a.id, a.code, a.name, a.type HAVING net != 0 ORDER BY a.code
    ''', [asOf]);

    final niRes = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as ni
      FROM accounts a JOIN journal_entry_lines jel ON jel.account_id = a.id JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1 AND je.entry_date >= ? AND je.entry_date <= ? AND a.type IN (3, 4) AND COALESCE(je.reference_type, '') NOT IN ('opening_entry', 'opening_balance', 'closing')
    ''', [startOfPeriod, asOf]);
    final ni = (niRes.first['ni'] as num).toDouble();

    final curA = <_AccountBalanceRow>[], fixA = <_AccountBalanceRow>[], othA = <_AccountBalanceRow>[], curL = <_AccountBalanceRow>[], ltrL = <_AccountBalanceRow>[], equ = <_AccountBalanceRow>[];
    double tA = 0, tL = 0, tE = 0;

    for (final m in accounts) {
      final r = _AccountBalanceRow(id: m['id'] as int, code: m['code'] as String, name: m['name'] as String, type: m['type'] as int, net: (m['net'] as num).toDouble());
      if (r.type == 1) { tA += r.displayAmount; curA.add(r); }
      else if (r.type == 2 && r.code == '2002') { tE += r.displayAmount; equ.add(r); }
      else if (r.type == 2) { tL += r.displayAmount; curL.add(r); }
    }
    if (ni.abs() > 0.01) { equ.add(_AccountBalanceRow(id: -1, code: 'NI', name: 'صافي دخل الفترة الحالية', type: 2, net: -ni)); tE += ni; }

    return _BalanceSheetResult(currentAssets: curA, fixedAssets: fixA, otherAssets: othA, currentLiabilities: curL, longTermLiabilities: ltrL, equityRows: equ, totalAssets: tA, totalLiabilities: tL, totalEquity: tE, netIncome: ni);
  }
}

class _BalanceSheetResult { final List<_AccountBalanceRow> currentAssets, fixedAssets, otherAssets, currentLiabilities, longTermLiabilities, equityRows; final double totalAssets, totalLiabilities, totalEquity, netIncome; _BalanceSheetResult({required this.currentAssets, required this.fixedAssets, required this.otherAssets, required this.currentLiabilities, required this.longTermLiabilities, required this.equityRows, required this.totalAssets, required this.totalLiabilities, required this.totalEquity, required this.netIncome}); double get difference => totalAssets - (totalLiabilities + totalEquity); bool get isBalanced => difference.abs() < 0.01; }
class _AccountBalanceRow { final int id; final String code, name; final int type; final double net; _AccountBalanceRow({required this.id, required this.code, required this.name, required this.type, required this.net}); double get displayAmount => (type == 1 || type == 2) ? -net : net; }
