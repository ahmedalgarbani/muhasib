import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class AgedReceivablesReportPage extends StatefulWidget {
  const AgedReceivablesReportPage({super.key});
  @override
  State<AgedReceivablesReportPage> createState() => _AgedReceivablesReportPageState();
}

class _AgedReceivablesReportPageState extends State<AgedReceivablesReportPage> {
  _AgedResult? _lastResult;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أعمار ديون العملاء',
      icon: Icons.hourglass_top,
      color: const Color(0xFFF44336),
      onPrint: _lastResult == null ? null : () => _exportPdf('تقرير أعمار ديون العملاء'),
      onExportExcel: _lastResult == null ? null : () => _exportExcel('aged_receivables'),
      reportBuilder: (filter) => _AgedInvoicesContent(filter: filter, titleLabel: 'العملاء', customerType: 1, invoiceTypes: const [1], onLoad: (r) => setState(() => _lastResult = r)),
    );
  }
  void _exportPdf(String title) => ExportService.printData(title: title, headers: ['الفترة', 'العدد', 'المبلغ المستحق'], data: _lastResult!.buckets.map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)]).toList());
  void _exportExcel(String fileName) => ExportService.exportToExcel(fileName: fileName, headers: ['فترة التأخير', 'عدد الفواتير', 'إجمالي المبلغ المتأخر'], data: _lastResult!.buckets.map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)]).toList());
}

class AgedPayablesReportPage extends StatefulWidget {
  const AgedPayablesReportPage({super.key});
  @override
  State<AgedPayablesReportPage> createState() => _AgedPayablesReportPageState();
}

class _AgedPayablesReportPageState extends State<AgedPayablesReportPage> {
  _AgedResult? _lastResult;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أعمار مستحقات الموردين',
      icon: Icons.hourglass_bottom,
      color: const Color(0xFFE64A19),
      onPrint: _lastResult == null ? null : () => _exportPdf('تقرير أعمار مستحقات الموردين'),
      onExportExcel: _lastResult == null ? null : () => _exportExcel('aged_payables'),
      reportBuilder: (filter) => _AgedInvoicesContent(filter: filter, titleLabel: 'الموردين', customerType: 2, invoiceTypes: const [2], onLoad: (r) => setState(() => _lastResult = r)),
    );
  }
  void _exportPdf(String title) => ExportService.printData(title: title, headers: ['الفترة', 'العدد', 'المبلغ المستحق'], data: _lastResult!.buckets.map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)]).toList());
  void _exportExcel(String fileName) => ExportService.exportToExcel(fileName: fileName, headers: ['فترة التأخير', 'عدد الفواتير', 'إجمالي المبلغ المتأخر'], data: _lastResult!.buckets.map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)]).toList());
}

class _AgedInvoicesContent extends StatelessWidget {
  final ReportFilter filter;
  final String titleLabel;
  final int customerType;
  final List<int> invoiceTypes;
  final Function(_AgedResult) onLoad;
  const _AgedInvoicesContent({required this.filter, required this.titleLabel, required this.customerType, required this.invoiceTypes, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AgedResult>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('خطأ: ${snapshot.error}'));
        final data = snapshot.data;
        if (data != null && data.buckets.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(data));
        if (data == null || data.buckets.isEmpty) return const Center(child: Text('لا توجد ديون متأخرة حالياً'));

        return Column(
          children: [
            ReportSummaryRow(cards: [
              ReportSummaryCard(title: 'إجمالي متأخر', value: data.total.toStringAsFixed(2), icon: Icons.warning, color: Colors.red),
              ReportSummaryCard(title: 'عدد المستندات', value: data.count.toString(), icon: Icons.receipt, color: Colors.blue),
              ReportSummaryCard(title: 'عدد $titleLabel', value: data.parties.toString(), icon: Icons.people, color: Colors.purple),
            ]),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: data.buckets.map((b) => Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(b.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('عدد الفواتير: ${b.count}', style: const TextStyle(fontSize: 12)),
                    trailing: Text('${b.amount.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                  ),
                )).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_AgedResult> _load() async {
    final db = await getIt<DatabaseService>().database;
    final now = DateTime.now();
    final asOf = (filter.endDate ?? now).millisecondsSinceEpoch ~/ 1000;
    final args = <Object?>[asOf, customerType];
    final typeClause = invoiceTypes.isEmpty ? '' : 'AND i.invoice_type IN (${invoiceTypes.map((_) => '?').join(',')})';
    if (invoiceTypes.isNotEmpty) args.addAll(invoiceTypes);

    final rows = await db.rawQuery('''
      SELECT i.id, i.due_date, COALESCE(i.final_amt, i.total_amount, i.amount, 0) as amount, i.customer_id
      FROM invoices i INNER JOIN customers c ON c.id = i.customer_id
      WHERE i.due_date IS NOT NULL AND i.due_date < ? AND c.type = ? AND i.payment_status != 2 AND COALESCE(i.approval_status, 1) != 3 $typeClause
    ''', args);

    final buckets = {'0-30': _AgedBucket(label: '0 - 30 يوم', amount: 0, count: 0), '31-60': _AgedBucket(label: '31 - 60 يوم', amount: 0, count: 0), '61-90': _AgedBucket(label: '61 - 90 يوم', amount: 0, count: 0), '90+': _AgedBucket(label: 'أكثر من 90 يوم', amount: 0, count: 0)};
    final partyIds = <int>{};
    for (final r in rows) {
      final amt = (r['amount'] as num).toDouble();
      partyIds.add(r['customer_id'] as int);
      final days = now.difference(DateTime.fromMillisecondsSinceEpoch((r['due_date'] as int) * 1000)).inDays;
      final key = days <= 30 ? '0-30' : days <= 60 ? '31-60' : days <= 90 ? '61-90' : '90+';
      buckets[key] = buckets[key]!.copyWith(amount: buckets[key]!.amount + amt, count: buckets[key]!.count + 1);
    }
    final list = buckets.values.where((b) => b.count > 0).toList();
    return _AgedResult(buckets: list, total: list.fold(0, (s, b) => s + b.amount), count: rows.length, parties: partyIds.length);
  }
}

class _AgedResult { final List<_AgedBucket> buckets; final double total; final int count, parties; _AgedResult({required this.buckets, required this.total, required this.count, required this.parties}); }
class _AgedBucket { final String label; final double amount; final int count; _AgedBucket({required this.label, required this.amount, required this.count}); 
_AgedBucket copyWith({double? amount, int? count}) => _AgedBucket(label: label, amount: amount ?? this.amount, count: count ?? this.count); }
