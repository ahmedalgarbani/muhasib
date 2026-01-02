import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class SalesByCustomerReportPage extends StatelessWidget {
  const SalesByCustomerReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مبيعات حسب العميل',
      icon: Icons.people,
      color: const Color(0xFF388E3C),
      reportBuilder: (filter) => _AggregateByPartyContent(
        filter: filter,
        invoiceType: 1, // sales
        titleLabel: 'العميل',
      ),
    );
  }
}

class PurchaseBySupplierReportPage extends StatelessWidget {
  const PurchaseBySupplierReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مشتريات حسب المورد',
      icon: Icons.local_shipping,
      color: const Color(0xFF388E3C),
      reportBuilder: (filter) => _AggregateByPartyContent(
        filter: filter,
        invoiceType: 2, // purchase
        titleLabel: 'المورد',
      ),
    );
  }
}

class DailySalesReportPage extends StatelessWidget {
  const DailySalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'المبيعات اليومية',
      icon: Icons.today,
      color: const Color(0xFF00ACC1),
      reportBuilder: (filter) => _DailyTotalsContent(filter: filter, invoiceType: 1),
    );
  }
}

class SalesByProductReportPage extends StatelessWidget {
  const SalesByProductReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مبيعات حسب المنتج',
      icon: Icons.inventory_2,
      color: const Color(0xFF7B1FA2),
      reportBuilder: (filter) => _AggregateByProductContent(
        filter: filter,
        invoiceType: 1,
      ),
    );
  }
}

class PurchaseByProductReportPage extends StatelessWidget {
  const PurchaseByProductReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مشتريات حسب المنتج',
      icon: Icons.category,
      color: const Color(0xFF7B1FA2),
      reportBuilder: (filter) => _AggregateByProductContent(
        filter: filter,
        invoiceType: 2,
      ),
    );
  }
}

class _AggregateByPartyContent extends StatelessWidget {
  final ReportFilter filter;
  final int invoiceType;
  final String titleLabel;

  const _AggregateByPartyContent({
    required this.filter,
    required this.invoiceType,
    required this.titleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_PartyRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final total = rows.fold<double>(0, (s, r) => s + r.total);
        final count = rows.fold<int>(0, (s, r) => s + r.count);

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'عدد المستندات',
                  value: count.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'الإجمالي',
                  value: total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'عدد ${titleLabel}',
                  value: rows.length.toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(r.name),
                      subtitle: Text('عدد: ${r.count}'),
                      trailing: Text(
                        r.total.toStringAsFixed(2),
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

  Future<List<_PartyRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[invoiceType];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND i.date >= ? AND i.date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        c.id as party_id,
        c.name as party_name,
        COUNT(i.id) as doc_count,
        COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total
      FROM invoices i
      INNER JOIN customers c ON c.id = i.customer_id
      WHERE i.invoice_type = ?
        AND COALESCE(i.status, 1) != 3
      $dateFilter
      GROUP BY c.id, c.name
      ORDER BY total DESC
      ''',
      args,
    );

    return rows.map((m) {
      return _PartyRow(
        id: (m['party_id'] as int?) ?? 0,
        name: (m['party_name'] as String?) ?? '',
        count: (m['doc_count'] as int?) ?? 0,
        total: (m['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}

class _AggregateByProductContent extends StatelessWidget {
  final ReportFilter filter;
  final int invoiceType;

  const _AggregateByProductContent({
    required this.filter,
    required this.invoiceType,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ProductRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final total = rows.fold<double>(0, (s, r) => s + r.total);

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'عدد الأصناف',
                  value: rows.length.toString(),
                  icon: Icons.category,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الكمية',
                  value: rows.fold<double>(0, (s, r) => s + r.qty).toStringAsFixed(2),
                  icon: Icons.inventory,
                  color: Colors.purple,
                ),
                ReportSummaryCard(
                  title: 'الإجمالي',
                  value: total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(r.name),
                      subtitle: Text('كمية: ${r.qty.toStringAsFixed(2)}'),
                      trailing: Text(
                        r.total.toStringAsFixed(2),
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

  Future<List<_ProductRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[invoiceType];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND i.date >= ? AND i.date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        c.id as product_id,
        c.name as product_name,
        COALESCE(SUM(il.quantity), 0) as qty,
        COALESCE(SUM(il.total_amount), 0) as total
      FROM invoice_lines il
      INNER JOIN invoices i ON i.id = il.invoice_id
      LEFT JOIN categories c ON c.id = il.category_id
      WHERE i.invoice_type = ?
        AND COALESCE(i.status, 1) != 3
      $dateFilter
      GROUP BY c.id, c.name
      ORDER BY total DESC
      ''',
      args,
    );

    return rows.map((m) {
      return _ProductRow(
        id: (m['product_id'] as int?) ?? 0,
        name: (m['product_name'] as String?) ?? '',
        qty: (m['qty'] as num?)?.toDouble() ?? 0.0,
        total: (m['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}

class _DailyTotalsContent extends StatelessWidget {
  final ReportFilter filter;
  final int invoiceType;

  const _DailyTotalsContent({
    required this.filter,
    required this.invoiceType,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_DailyRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final total = rows.fold<double>(0, (s, r) => s + r.total);
        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'الإجمالي',
                  value: total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'عدد الأيام',
                  value: rows.length.toString(),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'المتوسط اليومي',
                  value: (total / rows.length).toStringAsFixed(2),
                  icon: Icons.analytics,
                  color: Colors.purple,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(r.day),
                      trailing: Text(
                        r.total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('عدد المستندات: ${r.count}'),
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

  Future<List<_DailyRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[invoiceType];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND i.date >= ? AND i.date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        date(i.date, 'unixepoch') as day,
        COUNT(i.id) as cnt,
        COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total
      FROM invoices i
      WHERE i.invoice_type = ?
        AND COALESCE(i.status, 1) != 3
      $dateFilter
      GROUP BY date(i.date, 'unixepoch')
      ORDER BY day
      ''',
      args,
    );


    return rows.map((m) {
      return _DailyRow(
        day: (m['day'] as String?) ?? '',
        count: (m['cnt'] as int?) ?? 0,
        total: (m['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}

class _PartyRow {
  final int id;
  final String name;
  final int count;
  final double total;

  const _PartyRow({
    required this.id,
    required this.name,
    required this.count,
    required this.total,
  });
}

class _ProductRow {
  final int id;
  final String name;
  final double qty;
  final double total;

  const _ProductRow({
    required this.id,
    required this.name,
    required this.qty,
    required this.total,
  });
}

class _DailyRow {
  final String day;
  final int count;
  final double total;

  const _DailyRow({
    required this.day,
    required this.count,
    required this.total,
  });
}


