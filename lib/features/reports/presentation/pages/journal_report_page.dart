import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
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

    if (!context.mounted) return;
    AppToast.showSuccess(context, 'تم تصدير ملف Excel بنجاح: $path');
  }
}

class _JournalReportContent extends StatefulWidget {
  final ReportFilter filter;
  final Function(_JournalReportResult) onLoad;

  const _JournalReportContent({required this.filter, required this.onLoad});

  @override
  State<_JournalReportContent> createState() => _JournalReportContentState();
}

class _JournalReportContentState extends State<_JournalReportContent> {
  late Future<_JournalReportResult> _future;
  _JournalReportResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _JournalReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load(widget.filter);
  }

  String _formatCurrency(double value) => NumberFormatter.formatNumber(value);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_JournalReportResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data != null && data != _notifiedResult) {
          _notifiedResult = data;
          if (data.entries.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onLoad(data),
            );
          }
        }
        if (data == null || data.entries.isEmpty) {
          return const Center(child: Text('لا توجد قيود في الفترة المحددة'));
        }

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
    final ds = getIt<ReportsLocalDataSource>();
    final entriesRows = await ds.getJournalEntries(filter: filter);
    final List<_JournalEntryRow> entries = [];
    double tDebit = 0, tCredit = 0;
    int posted = 0, unbalanced = 0;

    for (final e in entriesRows) {
      final linesRows = await ds.getJournalEntryLines(
        journalEntryId: e['id'] as int,
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
    final d = dateTimeFromReportTimestamp(entryDate);
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
