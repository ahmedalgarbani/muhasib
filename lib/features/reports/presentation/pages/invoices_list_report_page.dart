import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class InvoicesListReportPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<int> invoiceTypes;
  final String? partyTypeLabel; // 'عميل' / 'مورد'

  const InvoicesListReportPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.invoiceTypes,
    this.partyTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: title,
      icon: icon,
      color: color,
      reportBuilder: (filter) => _InvoicesListContent(
        filter: filter,
        invoiceTypes: invoiceTypes,
        partyTypeLabel: partyTypeLabel,
      ),
    );
  }
}

class _InvoicesListContent extends StatelessWidget {
  final ReportFilter filter;
  final List<int> invoiceTypes;
  final String? partyTypeLabel;

  const _InvoicesListContent({
    required this.filter,
    required this.invoiceTypes,
    required this.partyTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InvoicesListResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null || data.rows.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'عدد المستندات',
                  value: data.count.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'الإجمالي',
                  value: data.total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'المتوسط',
                  value: (data.count == 0 ? 0 : data.total / data.count).toStringAsFixed(2),
                  icon: Icons.analytics,
                  color: Colors.purple,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.rows.length,
                itemBuilder: (context, index) {
                  final r = data.rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(r.number),
                      subtitle: Text(
                        '${r.dateLabel}'
                        '${partyTypeLabel != null ? ' | $partyTypeLabel: ${r.partyName}' : ''}'
                        '${r.statement == null || r.statement!.isEmpty ? '' : ' | ${r.statement}'}',
                      ),
                      trailing: Text(
                        r.amount.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

    final rows = await db.rawQuery(
      '''
      SELECT
        i.id,
        i.number,
        i.date,
        i.statement,
        COALESCE(i.final_amt, i.total_amount, i.amount, 0) as amount,
        c.name as party_name
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      $where
      ORDER BY i.date DESC, i.id DESC
      ''',
      args,
    );

    final parsed = rows.map((m) {
      return _InvoiceRow(
        id: (m['id'] as int?) ?? 0,
        number: (m['number'] as String?) ?? '',
        date: (m['date'] as int?) ?? 0,
        statement: m['statement'] as String?,
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        partyName: (m['party_name'] as String?) ?? '',
      );
    }).toList();

    final total = parsed.fold<double>(0, (s, r) => s + r.amount);
    return _InvoicesListResult(rows: parsed, total: total);
  }
}

class _InvoicesListResult {
  final List<_InvoiceRow> rows;
  final double total;
  int get count => rows.length;

  const _InvoicesListResult({
    required this.rows,
    required this.total,
  });
}

class _InvoiceRow {
  final int id;
  final String number;
  final int date;
  final String? statement;
  final double amount;
  final String partyName;

  const _InvoiceRow({
    required this.id,
    required this.number,
    required this.date,
    required this.statement,
    required this.amount,
    required this.partyName,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(date * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}


