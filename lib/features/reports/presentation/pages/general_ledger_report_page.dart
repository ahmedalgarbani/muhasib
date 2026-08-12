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

class GeneralLedgerReportPage extends StatefulWidget {
  const GeneralLedgerReportPage({super.key});
  @override
  State<GeneralLedgerReportPage> createState() => _GeneralLedgerReportPageState();
}

class _GeneralLedgerReportPageState extends State<GeneralLedgerReportPage> {
  _LedgerResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'دفتر الأستاذ العام',
      icon: Icons.menu_book,
      color: AppColors.brown700,
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _GeneralLedgerContent(filter: filter, onLoad: (r) => setState(() => _lastResult = r)),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final List<List<String>> data = [];
    for (var acc in _lastResult!.accounts) {
      data.add([acc.code, acc.name, acc.totalDebit.toStringAsFixed(2), acc.totalCredit.toStringAsFixed(2), acc.balance.toStringAsFixed(2)]);
    }
    await ExportService.printData(title: 'دفتر الأستاذ العام', headers: ['الكود', 'الحساب', 'مدين', 'دائن', 'الرصيد'], data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    final path = await ExportService.exportToExcel(fileName: 'general_ledger', headers: ['كود', 'اسم الحساب', 'إجمالي مدين', 'إجمالي دائن', 'الرصيد'], data: _lastResult!.accounts.map((a) => [a.code, a.name, a.totalDebit.toStringAsFixed(2), a.totalCredit.toStringAsFixed(2), a.balance.toStringAsFixed(2)]).toList());
    AppToast.showSuccess(context, 'تم تصدير Excel: $path');
  }
}

class _GeneralLedgerContent extends StatefulWidget {
  final ReportFilter filter;
  final Function(_LedgerResult) onLoad;
  const _GeneralLedgerContent({required this.filter, required this.onLoad});
  @override
  State<_GeneralLedgerContent> createState() => _GeneralLedgerContentState();
}

class _GeneralLedgerContentState extends State<_GeneralLedgerContent> {
  final _numberFormat = NumberFormat('#,##0.00', 'ar');
  int? _selectedAccountId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LedgerResult>(
      future: _load(widget.filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('خطأ: ${snapshot.error}'));
        final data = snapshot.data;
        if (data != null) WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad(data));
        if (data == null || data.accounts.isEmpty) return const Center(child: Text('لا توجد بيانات'));

        return Column(
          children: [
            _buildQuickSummary(data),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.accounts.length,
                itemBuilder: (context, index) {
                  final a = data.accounts[index];
                  final isSel = _selectedAccountId == a.id;
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: Colors.grey[100]!)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      onExpansionChanged: (v) => setState(() => _selectedAccountId = v ? a.id : null),
                      leading: Container(width: 4, height: 30, decoration: BoxDecoration(color: _getAccountTypeColor(a.type), borderRadius: BorderRadius.circular(AppRadius.xxs))),
                      title: Text('${a.code} - ${a.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('الرصيد: ${_numberFormat.format(a.balance)} ر.س', style: TextStyle(color: a.balance >= 0 ? Colors.blue : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      children: [
                         if (isSel) _AccountTransactionsView(accountId: a.id, filter: widget.filter),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickSummary(_LedgerResult data) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.brown[50], borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _sumItem('مدين', data.totalDebit, Colors.blue),
        _sumItem('دائن', data.totalCredit, Colors.green),
        _sumItem('الفرق', (data.totalDebit - data.totalCredit).abs(), Colors.red),
      ]),
    );
  }

  Widget _sumItem(String l, double v, Color c) => Column(children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.brown, fontWeight: FontWeight.bold)), Text(_numberFormat.format(v), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c))]);

  Color _getAccountTypeColor(int t) {
    switch (t) { case 0: return Colors.green; case 1: return Colors.red; case 2: return Colors.blue; case 3: return Colors.teal; case 4: return Colors.orange; default: return Colors.grey; }
  }

  Future<_LedgerResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      df = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }
    final rows = await db.rawQuery('''
      SELECT a.id, a.code, a.name, a.type, COALESCE(SUM(jel.debit_amount), 0) as td, COALESCE(SUM(jel.credit_amount), 0) as tc
      FROM accounts a INNER JOIN journal_entry_lines jel ON jel.account_id = a.id INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1 $df GROUP BY a.id ORDER BY a.code
    ''', args);
    final list = rows.map((m) => _LedgerAccount(id: m['id'] as int, code: m['code'] as String, name: m['name'] as String, type: m['type'] as int, totalDebit: (m['td'] as num).toDouble(), totalCredit: (m['tc'] as num).toDouble(), balance: (m['td'] as num).toDouble() - (m['tc'] as num).toDouble())).toList();
    return _LedgerResult(accounts: list, totalDebit: list.fold(0, (s, a) => s + a.totalDebit), totalCredit: list.fold(0, (s, a) => s + a.totalCredit));
  }
}

class _AccountTransactionsView extends StatelessWidget {
  final int accountId;
  final ReportFilter filter;
  const _AccountTransactionsView({required this.accountId, required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LedgerTransaction>>(
      future: _loadTxns(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator());
        final txns = snapshot.data!;
        if (txns.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد حركات تفصيلية', style: TextStyle(fontSize: 11, color: Colors.grey)));
        return Container(
          color: Colors.grey[50],
          child: Column(children: txns.map((t) => ListTile(dense: true, title: Text(t.description ?? 'بدون وصف', style: const TextStyle(fontSize: 11)), subtitle: Text(t.dateLabel, style: const TextStyle(fontSize: 9)), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(t.debit > 0 ? '+${t.debit}' : '-${t.credit}', style: TextStyle(fontSize: 11, color: t.debit > 0 ? Colors.blue : Colors.red, fontWeight: FontWeight.bold)), Text('رصيد: ${t.runningBalance.toStringAsFixed(1)}', style: const TextStyle(fontSize: 9, color: Colors.grey))]))).toList()),
        );
      },
    );
  }

  Future<List<_LedgerTransaction>> _loadTxns() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery('''
      SELECT je.entry_date, je.description, jel.debit_amount as d, jel.credit_amount as c FROM journal_entry_lines jel JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE jel.account_id = ? AND je.is_posted = 1 ORDER BY je.entry_date LIMIT 20
    ''', [accountId]);
    double rb = 0;
    return rows.map((m) { rb += (m['d'] as num).toDouble() - (m['c'] as num).toDouble(); return _LedgerTransaction(entryDate: m['entry_date'] as int, description: m['description'] as String?, debit: (m['d'] as num).toDouble(), credit: (m['c'] as num).toDouble(), runningBalance: rb); }).toList();
  }
}

class _LedgerResult { final List<_LedgerAccount> accounts; final double totalDebit, totalCredit; _LedgerResult({required this.accounts, required this.totalDebit, required this.totalCredit}); }
class _LedgerAccount { final int id, type; final String code, name; final double totalDebit, totalCredit, balance; _LedgerAccount({required this.id, required this.code, required this.name, required this.type, required this.totalDebit, required this.totalCredit, required this.balance}); }
class _LedgerTransaction { final int entryDate; final String? description; final double debit, credit, runningBalance; _LedgerTransaction({required this.entryDate, this.description, required this.debit, required this.credit, required this.runningBalance}); String get dateLabel { final d = DateTime.fromMillisecondsSinceEpoch(entryDate * 1000); return '${d.day}/${d.month}/${d.year}'; } }
