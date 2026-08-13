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
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/reports/presentation/widgets/journal_report_components.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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
      color: AppColors.blueGrey600,
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

    final headers = [
      'الرقم',
      'التاريخ',
      'البيان',
      'كود الحساب',
      'اسم الحساب',
      'مدين',
      'دائن',
    ];
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

    AppToast.showSuccess(context, 'تم تصدير ملف Excel بنجاح: $path');
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  TinySummaryWidget(
                    title: 'العدد',
                    value: '${data.entries.length}',
                    color: Colors.blue,
                  ),
                  TinySummaryWidget(
                    title: 'إجمالي مدين',
                    value: _formatCurrency(data.totalDebit),
                    color: Colors.teal,
                  ),
                  TinySummaryWidget(
                    title: 'إجمالي دائن',
                    value: _formatCurrency(data.totalCredit),
                    color: Colors.green,
                  ),
                  TinySummaryWidget(
                    title: 'المرحلة',
                    value: '${data.postedCount}',
                    color: Colors.indigo,
                  ),
                ],
              ),
            ),
            if (data.unbalancedCount > 0)
              WarningBannerWidget(
                message: 'تحذير: يوجد ${data.unbalancedCount} قيد غير متوازن!',
              ),
            Expanded(
              child: ListView.builder(
                padding: AppConstant.defaultPadding,
                itemCount: data.entries.length,
                itemBuilder: (context, index) => JournalEntryCardWidget(
                  entry: data.entries[index],
                  formatCurrency: _formatCurrency,
                ),
              ),
            ),
          ],
        );
      },
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

    final entriesRows = await db.query(
      'journal_entries',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'entry_date ASC, id ASC',
    );
    final List<_JournalEntryRow> entries = [];
    double tDebit = 0, tCredit = 0;
    int posted = 0, unbalanced = 0;

    for (final e in entriesRows) {
      final linesRows = await db.rawQuery(
        '''
        SELECT jel.*, a.code as acode, a.name as aname 
        FROM journal_entry_lines jel 
        LEFT JOIN accounts a ON a.id = jel.account_id 
        WHERE jel.journal_entry_id = ? 
        ORDER BY jel.line_number, jel.id
      ''',
        [e['id']],
      );

      final entry = _JournalEntryRow.fromDb(e, linesRows);
      entries.add(entry);
      tDebit += entry.totalDebit;
      tCredit += entry.totalCredit;
      if (entry.isPosted) posted++;
      if ((entry.totalDebit - entry.totalCredit).abs() > 0.01) unbalanced++;
    }

    return _JournalReportResult(
      entries: entries,
      totalDebit: tDebit,
      totalCredit: tCredit,
      postedCount: posted,
      unbalancedCount: unbalanced,
    );
  }
}

class _JournalReportResult {
  final List<_JournalEntryRow> entries;
  final double totalDebit, totalCredit;
  final int postedCount, unbalancedCount;
  int get draftCount => entries.length - postedCount;
  _JournalReportResult({
    required this.entries,
    required this.totalDebit,
    required this.totalCredit,
    required this.postedCount,
    required this.unbalancedCount,
  });
}

class _JournalEntryRow {
  final int id;
  final String? number, description, referenceType, referenceNumber;
  final int entryDate;
  final bool isPosted;
  final double totalDebit, totalCredit;
  final List<_JournalLineRow> lines;

  _JournalEntryRow({
    required this.id,
    this.number,
    this.description,
    this.referenceType,
    this.referenceNumber,
    required this.entryDate,
    required this.isPosted,
    required this.totalDebit,
    required this.totalCredit,
    required this.lines,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(entryDate * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }

  factory _JournalEntryRow.fromDb(
    Map<String, dynamic> e,
    List<Map<String, dynamic>> lines,
  ) {
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
      lines: lines
          .map(
            (l) => _JournalLineRow(
              id: l['id'] as int,
              accountCode:
                  (l['account_code'] as String?) ??
                  (l['acode'] as String?) ??
                  '',
              accountName:
                  (l['account_name'] as String?) ??
                  (l['aname'] as String?) ??
                  '',
              debitAmount: (l['debit_amount'] as num?)?.toDouble() ?? 0.0,
              creditAmount: (l['credit_amount'] as num?)?.toDouble() ?? 0.0,
              notes:
                  (l['notes'] as String?) ??
                  (l['description'] as String?) ??
                  '',
            ),
          )
          .toList(),
    );
  }
}

class _JournalLineRow {
  final int id;
  final String accountCode, accountName, notes;
  final double debitAmount, creditAmount;
  _JournalLineRow({
    required this.id,
    required this.accountCode,
    required this.accountName,
    required this.notes,
    required this.debitAmount,
    required this.creditAmount,
  });
}
