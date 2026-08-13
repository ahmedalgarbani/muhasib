import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/reports/presentation/widgets/invoice_report_components.dart';

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

    AppToast.showSuccess(context, 'تم تصدير ملف Excel بنجاح: $path');
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 1:
        return 'مُرحّلة';
      case 2:
        return 'مسودة';
      case 3:
        return 'ملغاة';
      case 4:
        return 'مرتجعة';
      default:
        return 'غير محدد';
    }
  }
}

class _InvoicesListContent extends StatelessWidget {
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

  String _formatCurrency(double value) {
    return NumberFormatter.formatCurrency(value, symbol: 'ر.س');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InvoicesListResult>(
      future: _load(filter),
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
        if (data == null || data.rows.isEmpty) {
          return const EmptyStateWidget(
            title: 'لا توجد فواتير لهذه الفترة',
            icon: Icons.inbox,
            iconSize: 64,
          );
        }

        // Notify parent about loaded data for export
        onLoad(data);

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
                itemBuilder: (context, index) =>
                    InvoiceReportCardWidget(
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


  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.mode_edit_outline;
      case 3:
        return Icons.cancel_outlined;
      case 4:
        return Icons.settings_backup_restore;
      default:
        return Icons.description_outlined;
    }
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 1:
        return 'مُرحّلة';
      case 2:
        return 'مسودة';
      case 3:
        return 'ملغاة';
      case 4:
        return 'مرتجعة';
      default:
        return 'غير محدد';
    }
  }

  Future<_InvoicesListResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    final whereParts = <String>[];

    if (filter.startDate != null && filter.endDate != null) {
      whereParts.add('i.date >= ? AND i.date <= ?');
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }
    if (invoiceTypes.isNotEmpty) {
      whereParts.add(
        'i.invoice_type IN (${invoiceTypes.map((_) => '?').join(',')})',
      );
      args.addAll(invoiceTypes);
    }
    final where = whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT
        i.id,
        i.number,
        i.date,
        i.statement,
        i.invoice_type,
        COALESCE(i.approval_status, 1) as status,
        COALESCE(i.final_amt, i.total_amount, i.amount, 0) as amount,
        c.name as party_name,
        CASE WHEN EXISTS (SELECT 1 FROM journal_entries je WHERE je.reference_id = i.id AND je.reference_type IN ('sales', 'purchase', 'sales_return', 'purchase_return')) THEN 1 ELSE 0 END as has_journal_entry
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      $where
      ORDER BY i.date DESC, i.id DESC
    ''', args);

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
    final d = DateTime.fromMillisecondsSinceEpoch(date * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}
