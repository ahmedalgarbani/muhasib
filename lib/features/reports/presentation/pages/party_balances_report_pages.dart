import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class CustomerBalancesReportPage extends StatelessWidget {
  const CustomerBalancesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أرصدة العملاء',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF388E3C),
      showDateFilter: false,
      reportBuilder: (_) => const _PartyBalancesContent(
        titleLabel: 'العملاء',
        customerType: 1,
      ),
    );
  }
}

class SupplierBalancesReportPage extends StatelessWidget {
  const SupplierBalancesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أرصدة الموردين',
      icon: Icons.account_balance,
      color: const Color(0xFF00ACC1),
      showDateFilter: false,
      reportBuilder: (_) => const _PartyBalancesContent(
        titleLabel: 'الموردين',
        customerType: 2,
      ),
    );
  }
}

class CustomerStatementReportPage extends StatelessWidget {
  const CustomerStatementReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Minimal: list customers; detailed statement can be opened from Account Statement report.
    return const CustomerBalancesReportPage();
  }
}

class SupplierStatementReportPage extends StatelessWidget {
  const SupplierStatementReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Minimal: list suppliers; detailed statement can be opened from Account Statement report.
    return const SupplierBalancesReportPage();
  }
}

class _PartyBalancesContent extends StatelessWidget {
  final String titleLabel;
  final int customerType; // customers.type: 1 customer, 2 supplier

  const _PartyBalancesContent({
    required this.titleLabel,
    required this.customerType,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_PartyBalanceRow>>(
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

        final total = rows.fold<double>(0, (s, r) => s + r.balance);

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'عدد $titleLabel',
                  value: rows.length.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الأرصدة',
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
                      subtitle: Text('الرصيد: ${r.balance.toStringAsFixed(2)}'),
                      trailing: Text(
                        r.balance.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: r.balance >= 0 ? Colors.green : Colors.red,
                        ),
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

  Future<List<_PartyBalanceRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.id,
        c.name,
        COALESCE(a.balance, 0) as balance
      FROM customers c
      LEFT JOIN accounts a ON a.id = c.account_id
      WHERE c.is_active = 1 AND c.type = ?
      ORDER BY balance DESC
      ''',
      [customerType],
    );

    return rows.map((m) {
      return _PartyBalanceRow(
        id: (m['id'] as int?) ?? 0,
        name: (m['name'] as String?) ?? '',
        balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}

class _PartyBalanceRow {
  final int id;
  final String name;
  final double balance;

  const _PartyBalanceRow({
    required this.id,
    required this.name,
    required this.balance,
  });
}


