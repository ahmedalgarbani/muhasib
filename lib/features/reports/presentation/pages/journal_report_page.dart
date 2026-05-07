import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

class JournalReportPage extends StatefulWidget {
  const JournalReportPage({super.key});

  @override
  State<JournalReportPage> createState() => _JournalReportPageState();
}

class _JournalReportPageState extends State<JournalReportPage> {
  _JournalReportResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير اليومية العامة',
      icon: Icons.auto_stories,
      color: const Color(0xFF455A64),
      onPrint: _lastResult == null ? null : () => _exportPdf(context),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(context),
      reportBuilder: (filter) => _JournalReportContent(
        filter: filter,
        onLoad: (result) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _lastResult = result);
          });
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (_lastResult == null) return;
    
    final headers = ['الرقم', 'التاريخ', 'البيان', 'الحساب', 'مدين', 'دائن'];
    final List<List<String>> data = [];
    
    for (final entry in _lastResult!.entries) {
      for (int i = 0; i < entry.lines.length; i++) {
        final line = entry.lines[i];
        data.add([
          i == 0 ? (entry.number ?? '#${entry.id}') : '',
          i == 0 ? entry.dateLabel : '',
          i == 0 ? (entry.description ?? '') : '',
          '${line.accountCode} - ${line.accountName}',
          line.debitAmount > 0 ? line.debitAmount.toStringAsFixed(2) : '0.00',
          line.creditAmount > 0 ? line.creditAmount.toStringAsFixed(2) : '0.00',
        ]);
      }
    }

    await ExportService.printData(
      title: 'تقرير اليومية العامة',
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    if (_lastResult == null) return;

    final headers = ['الرقم', 'التاريخ', 'البيان', 'كود الحساب', 'اسم الحساب', 'مدين', 'دائن'];
    final List<List<String>> data = [];

    for (final entry in _lastResult!.entries) {
      for (final line in entry.lines) {
        data.add([
          entry.number ?? '#${entry.id}',
          entry.dateLabel,
          entry.description ?? '',
          line.accountCode,
          line.accountName,
          line.debitAmount.toStringAsFixed(2),
          line.creditAmount.toStringAsFixed(2),
        ]);
      }
    }

    final path = await ExportService.exportToExcel(
      fileName: 'journal_report',
      headers: headers,
      data: data,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تصدير ملف Excel بنجاح: $path')),
    );
  }
}

class _JournalReportContent extends StatelessWidget {
  final ReportFilter filter;
  final Function(_JournalReportResult) onLoad;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  _JournalReportContent({required this.filter, required this.onLoad});

  String _formatCurrency(double value) => _numberFormat.format(value);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_JournalReportResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null || data.entries.isEmpty) {
          return const Center(child: Text('لا توجد قيود في الفترة المحددة'));
        }

        onLoad(data);

        return Column(
          children: [
            _buildSummaryRow(data),
            if (data.unbalancedCount > 0)
              _buildWarning('تحذير: يوجد ${data.unbalancedCount} قيد غير متوازن!'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.entries.length,
                itemBuilder: (context, index) => _buildEntryCard(data.entries[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(_JournalReportResult data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _buildTinySummary('العدد', '${data.entries.length}', Colors.blue),
          _buildTinySummary('إجمالي مدين', _formatCurrency(data.totalDebit), Colors.teal),
          _buildTinySummary('إجمالي دائن', _formatCurrency(data.totalCredit), Colors.green),
          _buildTinySummary('المرحلة', '${data.postedCount}', Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildTinySummary(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildWarning(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.2))),
      child: Row(children: [const Icon(Icons.error, color: Colors.red, size: 18), const SizedBox(width: 8), Text(message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))]),
    );
  }

  Widget _buildEntryCard(_JournalEntryRow entry) {
    final isBalanced = (entry.totalDebit - entry.totalCredit).abs() < 0.01;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: entry.isPosted ? const Color(0xFF546E7A) : Colors.orange.withOpacity(0.8), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              children: [
                Text(entry.number ?? '#${entry.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.description ?? 'بدون وصف', style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                Text(entry.dateLabel, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
              ],
            ),
          ),
          ...entry.lines.map((l) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('${l.accountCode} - ${l.accountName}', style: const TextStyle(fontSize: 13))),
                Expanded(child: Text(l.debitAmount > 0 ? _formatCurrency(l.debitAmount) : '-', textAlign: TextAlign.center, style: TextStyle(color: Colors.blue[700], fontSize: 12))),
                Expanded(child: Text(l.creditAmount > 0 ? _formatCurrency(l.creditAmount) : '-', textAlign: TextAlign.center, style: TextStyle(color: Colors.green[700], fontSize: 12))),
              ],
            ),
          )),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: isBalanced ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(isBalanced ? 'قيد متوازن ✓' : 'غير متوازن ⚠', style: TextStyle(color: isBalanced ? Colors.green[700] : Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Text(_formatCurrency(entry.totalDebit), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                    const SizedBox(width: 16),
                    Text(_formatCurrency(entry.totalCredit), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<_JournalReportResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String where = '1=1';
    if (filter.startDate != null && filter.endDate != null) {
      where += ' AND entry_date >= ? AND entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final entriesRows = await db.query('journal_entries', where: where, whereArgs: args.isEmpty ? null : args, orderBy: 'entry_date ASC, id ASC');
    final List<_JournalEntryRow> entries = [];
    double tDebit = 0, tCredit = 0;
    int posted = 0, unbalanced = 0;

    for (final e in entriesRows) {
      final linesRows = await db.rawQuery('''
        SELECT jel.*, a.code as acode, a.name as aname 
        FROM journal_entry_lines jel 
        LEFT JOIN accounts a ON a.id = jel.account_id 
        WHERE jel.journal_entry_id = ? 
        ORDER BY jel.line_number, jel.id
      ''', [e['id']]);

      final entry = _JournalEntryRow.fromDb(e, linesRows);
      entries.add(entry);
      tDebit += entry.totalDebit;
      tCredit += entry.totalCredit;
      if (entry.isPosted) posted++;
      if ((entry.totalDebit - entry.totalCredit).abs() > 0.01) unbalanced++;
    }

    return _JournalReportResult(entries: entries, totalDebit: tDebit, totalCredit: tCredit, postedCount: posted, unbalancedCount: unbalanced);
  }
}

class _JournalReportResult {
  final List<_JournalEntryRow> entries;
  final double totalDebit, totalCredit;
  final int postedCount, unbalancedCount;
  int get draftCount => entries.length - postedCount;
  _JournalReportResult({required this.entries, required this.totalDebit, required this.totalCredit, required this.postedCount, required this.unbalancedCount});
}

class _JournalEntryRow {
  final int id;
  final String? number, description, referenceType, referenceNumber;
  final int entryDate;
  final bool isPosted;
  final double totalDebit, totalCredit;
  final List<_JournalLineRow> lines;

  _JournalEntryRow({required this.id, this.number, this.description, this.referenceType, this.referenceNumber, required this.entryDate, required this.isPosted, required this.totalDebit, required this.totalCredit, required this.lines});

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(entryDate * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }

  factory _JournalEntryRow.fromDb(Map<String, dynamic> e, List<Map<String, dynamic>> lines) {
    return _JournalEntryRow(
      id: e['id'] as int,
      number: e['number'] as String?,
      entryDate: (e['entry_date'] as int?) ?? 0,
      description: e['description'] as String?,
      referenceType: e['reference_type'] as String?,
      referenceNumber: e['reference_number'] as String?,
      isPosted: (e['is_posted'] as int?) == 1,
      totalDebit: (e['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (e['total_credit'] as num?)?.toDouble() ?? 0.0,
      lines: lines.map((l) => _JournalLineRow(
        id: l['id'] as int,
        accountCode: (l['account_code'] as String?) ?? (l['acode'] as String?) ?? '',
        accountName: (l['account_name'] as String?) ?? (l['aname'] as String?) ?? '',
        debitAmount: (l['debit_amount'] as num?)?.toDouble() ?? 0.0,
        creditAmount: (l['credit_amount'] as num?)?.toDouble() ?? 0.0,
        notes: (l['notes'] as String?) ?? (l['description'] as String?) ?? '',
      )).toList(),
    );
  }
}

class _JournalLineRow {
  final int id;
  final String accountCode, accountName, notes;
  final double debitAmount, creditAmount;
  _JournalLineRow({required this.id, required this.accountCode, required this.accountName, required this.notes, required this.debitAmount, required this.creditAmount});
}
