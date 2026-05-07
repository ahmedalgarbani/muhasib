import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

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
    final data = _lastResult!.rows.map((r) => [
      r.number.isNotEmpty ? r.number : '#${r.id}',
      r.dateLabel,
      r.partyName,
      r.statement ?? '',
      _getStatusLabel(r.status),
      '${r.amount.toStringAsFixed(2)} ر.س',
    ]).toList();

    await ExportService.printData(
      title: widget.title,
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    if (_lastResult == null) return;

    final headers = ['الرقم', 'التاريخ', 'الجهة', 'البيان', 'الحالة', 'المبلغ'];
    final data = _lastResult!.rows.map((r) => [
      r.number.isNotEmpty ? r.number : '#${r.id}',
      r.dateLabel,
      r.partyName,
      r.statement ?? '',
      _getStatusLabel(r.status),
      r.amount.toStringAsFixed(2),
    ]).toList();

    final path = await ExportService.exportToExcel(
      fileName: 'report_invoices',
      headers: headers,
      data: data,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تصدير ملف Excel بنجاح: $path')),
    );
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 1: return 'مُرحّلة';
      case 2: return 'مسودة';
      case 3: return 'ملغاة';
      case 4: return 'مرتجعة';
      default: return 'غير محدد';
    }
  }
}

class _InvoicesListContent extends StatelessWidget {
  final ReportFilter filter;
  final List<int> invoiceTypes;
  final String? partyTypeLabel;
  final Color themeColor;
  final Function(_InvoicesListResult) onLoad;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  _InvoicesListContent({
    required this.filter,
    required this.invoiceTypes,
    required this.partyTypeLabel,
    required this.themeColor,
    required this.onLoad,
  });

  String _formatCurrency(double value) {
    return '${_numberFormat.format(value)} ر.س';
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
          return Center(child: Text('خطأ في البيانات: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final data = snapshot.data;
        if (data == null || data.rows.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('لا توجد فواتير لهذه الفترة', style: TextStyle(color: Colors.grey)),
            ],
          ));
        }

        // Notify parent about loaded data for export
        onLoad(data);

        return Column(
          children: [
            _buildSummaryCards(data),
            _buildStatusSummary(data),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: data.rows.length,
                itemBuilder: (context, index) => _buildInvoiceCard(data.rows[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(_InvoicesListResult data) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSummaryCard('عدد الفواتير', '${data.count}', Icons.receipt_long, Colors.blue),
          _buildSummaryCard('إجمالي القيمة', _formatCurrency(data.total), Icons.payments, Colors.green),
          _buildSummaryCard('مُرحّلة بقيد', '${data.withJournalEntry}', Icons.account_balance, Colors.teal),
          if (data.withoutJournalEntry > 0)
            _buildSummaryCard('تنبيه: بدون قيد', '${data.withoutJournalEntry}', Icons.error_outline, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(_InvoicesListResult data) {
   return Container(
     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
     padding: const EdgeInsets.all(12),
     decoration: BoxDecoration(
       color: data.withoutJournalEntry == 0 ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: data.withoutJournalEntry == 0 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
     ),
     child: Row(
       children: [
         Icon(data.withoutJournalEntry == 0 ? Icons.check_circle : Icons.info, 
              color: data.withoutJournalEntry == 0 ? Colors.green : Colors.orange, size: 18),
         const SizedBox(width: 12),
         Text(
           data.withoutJournalEntry == 0 ? 'جميع الفواتير تمت معالجتها برمجياً ومحاسبياً.' : 'تنبيه: يوجد ${data.withoutJournalEntry} فواتير لم يُنشأ لها قيد محاسبي.',
           style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: data.withoutJournalEntry == 0 ? Colors.green[800] : Colors.orange[800]),
         ),
       ],
     ),
   );
  }

  Widget _buildInvoiceCard(_InvoiceRow r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: _getStatusColor(r.status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getStatusIcon(r.status), color: _getStatusColor(r.status)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(r.number.isNotEmpty ? r.number : '#${r.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_formatCurrency(r.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(r.partyName, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(r.dateLabel, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBadge(_getStatusLabel(r.status), _getStatusColor(r.status)),
                const SizedBox(width: 8),
                _buildBadge(r.hasJournalEntry ? 'محاسبية' : 'مسودة', r.hasJournalEntry ? Colors.teal : Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      case 4: return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1: return Icons.check_circle_outline;
      case 2: return Icons.mode_edit_outline;
      case 3: return Icons.cancel_outlined;
      case 4: return Icons.settings_backup_restore;
      default: return Icons.description_outlined;
    }
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 1: return 'مُرحّلة';
      case 2: return 'مسودة';
      case 3: return 'ملغاة';
      case 4: return 'مرتجعة';
      default: return 'غير محدد';
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
      whereParts.add('i.invoice_type IN (${invoiceTypes.map((_) => '?').join(',')})');
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

    final parsed = rows.map((m) => _InvoiceRow(
      id: (m['id'] as int?) ?? 0,
      number: (m['number'] as String?) ?? '',
      date: (m['date'] as int?) ?? 0,
      statement: m['statement'] as String?,
      amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
      partyName: (m['party_name'] as String?) ?? 'جهة غير محددة',
      invoiceType: (m['invoice_type'] as int?) ?? 0,
      status: (m['status'] as int?) ?? 1,
      hasJournalEntry: (m['has_journal_entry'] as int?) == 1,
    )).toList();

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
  _InvoicesListResult({required this.rows, required this.total, required this.withJournalEntry, required this.withoutJournalEntry});
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
  _InvoiceRow({required this.id, required this.number, required this.date, this.statement, required this.amount, required this.partyName, required this.invoiceType, required this.status, required this.hasJournalEntry});
  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(date * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}
