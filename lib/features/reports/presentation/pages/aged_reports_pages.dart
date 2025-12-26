import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class AgedReceivablesReportPage extends StatelessWidget {
  const AgedReceivablesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أعمار الديون',
      icon: Icons.schedule,
      color: const Color(0xFFFF5722),
      reportBuilder: (filter) => _AgedInvoicesContent(
        filter: filter,
        titleLabel: 'العملاء',
        customerType: 1,
        invoiceTypes: const [1], // sales invoices
      ),
    );
  }
}

class AgedPayablesReportPage extends StatelessWidget {
  const AgedPayablesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أعمار المستحقات',
      icon: Icons.history,
      color: const Color(0xFFF44336),
      reportBuilder: (filter) => _AgedInvoicesContent(
        filter: filter,
        titleLabel: 'الموردين',
        customerType: 2,
        invoiceTypes: const [2], // purchase invoices
      ),
    );
  }
}

class _AgedInvoicesContent extends StatelessWidget {
  final ReportFilter filter;
  final String titleLabel;
  final int customerType; // customers.type (1 customers, 2 suppliers)
  final List<int> invoiceTypes;

  const _AgedInvoicesContent({
    required this.filter,
    required this.titleLabel,
    required this.customerType,
    required this.invoiceTypes,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AgedResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null || data.buckets.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي متأخر',
                  value: data.total.toStringAsFixed(2),
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
                ReportSummaryCard(
                  title: 'عدد المستندات',
                  value: data.count.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'عدد $titleLabel',
                  value: data.parties.toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: data.buckets.map((b) {
                  return Card(
                    child: ListTile(
                      title: Text(b.label),
                      subtitle: Text('عدد: ${b.count}'),
                      trailing: Text(
                        b.amount.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_AgedResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;

    final now = DateTime.now();
    final asOf = (filter.endDate ?? now).millisecondsSinceEpoch ~/ 1000;

    final args = <Object?>[asOf, customerType];

    final typeClause = invoiceTypes.isEmpty
        ? ''
        : 'AND i.invoice_type IN (${invoiceTypes.map((_) => '?').join(',')})';
    args.addAll(invoiceTypes);

    // Consider only credit documents with due_date and not fully paid (payment_status != 2)
    final rows = await db.rawQuery(
      '''
      SELECT
        i.id,
        i.due_date,
        COALESCE(i.final_amt, i.total_amount, i.amount, 0) as amount,
        i.customer_id
      FROM invoices i
      INNER JOIN customers c ON c.id = i.customer_id
      WHERE i.due_date IS NOT NULL
        AND i.due_date < ?
        AND c.type = ?
        AND i.payment_status != 2
        $typeClause
      ''',
      args,
    );

    int count = 0;
    final partyIds = <int>{};
    final buckets = <String, _AgedBucket>{
      '0-30': const _AgedBucket(label: '0 - 30 يوم', amount: 0, count: 0),
      '31-60': const _AgedBucket(label: '31 - 60 يوم', amount: 0, count: 0),
      '61-90': const _AgedBucket(label: '61 - 90 يوم', amount: 0, count: 0),
      '90+': const _AgedBucket(label: 'أكثر من 90 يوم', amount: 0, count: 0),
    };

    for (final r in rows) {
      final due = (r['due_date'] as int?) ?? 0;
      final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
      final partyId = (r['customer_id'] as int?) ?? 0;
      partyIds.add(partyId);
      count += 1;

      final dueDate = DateTime.fromMillisecondsSinceEpoch(due * 1000);
      final days = now.difference(dueDate).inDays;

      final key = days <= 30
          ? '0-30'
          : days <= 60
              ? '31-60'
              : days <= 90
                  ? '61-90'
                  : '90+';

      final old = buckets[key]!;
      buckets[key] = old.copyWith(amount: old.amount + amount, count: old.count + 1);
    }

    final list = buckets.values.where((b) => b.count > 0).toList();
    final total = list.fold<double>(0, (s, b) => s + b.amount);

    return _AgedResult(
      buckets: list,
      total: total,
      count: count,
      parties: partyIds.length,
    );
  }
}

class _AgedResult {
  final List<_AgedBucket> buckets;
  final double total;
  final int count;
  final int parties;

  const _AgedResult({
    required this.buckets,
    required this.total,
    required this.count,
    required this.parties,
  });
}

class _AgedBucket {
  final String label;
  final double amount;
  final int count;

  const _AgedBucket({
    required this.label,
    required this.amount,
    required this.count,
  });

  _AgedBucket copyWith({double? amount, int? count}) {
    return _AgedBucket(
      label: label,
      amount: amount ?? this.amount,
      count: count ?? this.count,
    );
  }
}


