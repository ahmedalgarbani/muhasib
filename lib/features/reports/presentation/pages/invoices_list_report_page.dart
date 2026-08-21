import 'package:flutter/material.dart';
import 'package:muhasib/core/enums/approval_status.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/invoice_report_components.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';

class InvoicesListReportPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<int> invoiceTypes;
  final String? partyTypeLabel;

  const InvoicesListReportPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.invoiceTypes,
    this.partyTypeLabel,
  });

  @override
  State<InvoicesListReportPage> createState() => _InvoicesListReportPageState();
}

class _InvoicesListReportPageState extends State<InvoicesListReportPage> {
  _InvoicesListResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: widget.title,
      icon: widget.icon,
      color: widget.color,
      onPrint: _lastResult == null ? null : () => _exportPdf(context),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(context),
      reportBuilder: (filter) => _InvoicesListContent(
        filter: filter,
        invoiceTypes: widget.invoiceTypes,
        partyTypeLabel: widget.partyTypeLabel,
        themeColor: widget.color,
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

    final headers = ['الرقم', 'التاريخ', 'الجهة', 'البيان', 'الحالة', 'المبلغ'];
    final data = _lastResult!.rows
        .map(
          (r) => [
            r.number.isNotEmpty ? r.number : '#${r.id}',
            r.dateLabel,
            r.partyName,
            r.statement ?? '',
            _getStatusLabel(r.status),
            '${r.amount.toStringAsFixed(2)} ر.س',
          ],
        )
        .toList();

    await ExportService.printData(
      title: widget.title,
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    if (_lastResult == null) return;

    final headers = ['الرقم', 'التاريخ', 'الجهة', 'البيان', 'الحالة', 'المبلغ'];
    final data = _lastResult!.rows
        .map(
          (r) => [
            r.number.isNotEmpty ? r.number : '#${r.id}',
            r.dateLabel,
            r.partyName,
            r.statement ?? '',
            _getStatusLabel(r.status),
            r.amount.toStringAsFixed(2),
          ],
        )
        .toList();

    final path = await ExportService.exportToExcel(
      fileName: 'report_invoices',
      headers: headers,
      data: data,
    );

    if (!context.mounted) return;
    AppToast.showSuccess(context, 'تم تصدير ملف Excel بنجاح: $path');
  }

  String _getStatusLabel(int status) {
    return ApprovalStatus.tryFromValue(status)?.labelAr ?? 'غير محدد';
  }
}

class _InvoicesListContent extends StatefulWidget {
  final ReportFilter filter;
  final List<int> invoiceTypes;
  final String? partyTypeLabel;
  final Color themeColor;
  final Function(_InvoicesListResult) onLoad;

  const _InvoicesListContent({
    required this.filter,
    required this.invoiceTypes,
    required this.partyTypeLabel,
    required this.themeColor,
    required this.onLoad,
  });

  @override
  State<_InvoicesListContent> createState() => _InvoicesListContentState();
}

class _InvoicesListContentState extends State<_InvoicesListContent> {
  late Future<_InvoicesListResult> _future;
  _InvoicesListResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _InvoicesListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load(widget.filter);
  }

  String _formatCurrency(double value) {
    return NumberFormatter.formatCurrency(value, symbol: 'ر.س');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InvoicesListResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'خطأ في البيانات: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final data = snapshot.data;
        if (data != null && data != _notifiedResult) {
          _notifiedResult = data;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(data),
          );
        }
        if (data == null || data.rows.isEmpty) {
          return const EmptyStateWidget(
            title: 'لا توجد فواتير لهذه الفترة',
            icon: Icons.inbox,
            iconSize: 64,
          );
        }

        return Column(
          children: [
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  InvoiceReportSummaryCardWidget(
                    title: 'عدد الفواتير',
                    value: '${data.count}',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                  InvoiceReportSummaryCardWidget(
                    title: 'إجمالي القيمة',
                    value: _formatCurrency(data.total),
                    icon: Icons.payments,
                    color: Colors.green,
                  ),
                  InvoiceReportSummaryCardWidget(
                    title: 'مُرحّلة بقيد',
                    value: '${data.withJournalEntry}',
                    icon: Icons.account_balance,
                    color: Colors.teal,
                  ),
                  if (data.withoutJournalEntry > 0)
                    InvoiceReportSummaryCardWidget(
                      title: 'تنبيه: بدون قيد',
                      value: '${data.withoutJournalEntry}',
                      icon: Icons.error_outline,
                      color: Colors.orange,
                    ),
                ],
              ),
            ),
            InvoiceReportStatusSummaryWidget(
              withoutJournalEntry: data.withoutJournalEntry,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: data.rows.length,
                itemBuilder: (context, index) => InvoiceReportCardWidget(
                  row: data.rows[index],
                  formattedCurrency: _formatCurrency(data.rows[index].amount),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_InvoicesListResult> _load(ReportFilter filter) async {
    final ds = getIt<ReportsLocalDataSource>();
    final rows = await ds.getInvoiceList(
      filter: filter,
      invoiceTypes: widget.invoiceTypes,
    );

    final parsed = rows
        .map(
          (m) => _InvoiceRow(
            id: (m['id'] as int?) ?? 0,
            number: (m['number'] as String?) ?? '',
            date: (m['date'] as int?) ?? 0,
            statement: m['statement'] as String?,
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            partyName: (m['party_name'] as String?) ?? 'جهة غير محددة',
            invoiceType: (m['invoice_type'] as int?) ?? 0,
            status: (m['status'] as int?) ?? 1,
            hasJournalEntry: (m['has_journal_entry'] as int?) == 1,
          ),
        )
        .toList();

    return _InvoicesListResult(
      rows: parsed,
      total: parsed.fold(0, (s, r) => s + r.amount),
      withJournalEntry: parsed.where((r) => r.hasJournalEntry).length,
      withoutJournalEntry: parsed.where((r) => !r.hasJournalEntry).length,
    );
  }
}

class _InvoicesListResult {
  final List<_InvoiceRow> rows;
  final double total;
  final int withJournalEntry;
  final int withoutJournalEntry;
  int get count => rows.length;
  _InvoicesListResult({
    required this.rows,
    required this.total,
    required this.withJournalEntry,
    required this.withoutJournalEntry,
  });
}

class _InvoiceRow {
  final int id;
  final String number;
  final int date;
  final String? statement;
  final double amount;
  final String partyName;
  final int invoiceType;
  final int status;
  final bool hasJournalEntry;
  _InvoiceRow({
    required this.id,
    required this.number,
    required this.date,
    this.statement,
    required this.amount,
    required this.partyName,
    required this.invoiceType,
    required this.status,
    required this.hasJournalEntry,
  });
  String get dateLabel {
    final d = dateTimeFromReportTimestamp(date);
    return '${d.day}/${d.month}/${d.year}';
  }
}
