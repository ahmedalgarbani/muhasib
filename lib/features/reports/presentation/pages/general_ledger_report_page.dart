import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class GeneralLedgerReportPage extends StatelessWidget {
  const GeneralLedgerReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'دفتر الأستاذ العام',
      icon: Icons.menu_book,
      color: const Color(0xFF5D4037),
      reportBuilder: (filter) => _GeneralLedgerContent(filter: filter),
    );
  }
}

class _GeneralLedgerContent extends StatelessWidget {
  final ReportFilter filter;

  const _GeneralLedgerContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LedgerResult>(
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
                  title: 'إجمالي المدين',
                  value: data.totalDebit.toStringAsFixed(2),
                  icon: Icons.arrow_upward,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الدائن',
                  value: data.totalCredit.toStringAsFixed(2),
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'الفرق',
                  value: (data.totalDebit - data.totalCredit).toStringAsFixed(2),
                  icon: Icons.compare_arrows,
                  color: (data.totalDebit - data.totalCredit).abs() < 0.01
                      ? Colors.green
                      : Colors.red,
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
                      title: Text('${r.code} - ${r.name}'),
                      subtitle: Text(
                        'مدين: ${r.debit.toStringAsFixed(2)} | دائن: ${r.credit.toStringAsFixed(2)}',
                      ),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () {
                        // Reuse Account Statement report; user can select account, but we pass focus by navigating.
                        context.push(AppRoutes.reportsAccountStatement);
                      },
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

  Future<_LedgerResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;

    final args = <Object?>[];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount), 0) as debit,
        COALESCE(SUM(jel.credit_amount), 0) as credit
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON jel.account_id = a.id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING (debit != 0 OR credit != 0)
      ORDER BY a.code
      ''',
      args,
    );

    final parsed = rows.map((m) {
      return _LedgerRow(
        id: (m['account_id'] as int?) ?? 0,
        code: (m['account_code'] as String?) ?? '',
        name: (m['account_name'] as String?) ?? '',
        debit: (m['debit'] as num?)?.toDouble() ?? 0.0,
        credit: (m['credit'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final totalDebit = parsed.fold<double>(0, (s, r) => s + r.debit);
    final totalCredit = parsed.fold<double>(0, (s, r) => s + r.credit);

    return _LedgerResult(
      rows: parsed,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
    );
  }
}

class _LedgerResult {
  final List<_LedgerRow> rows;
  final double totalDebit;
  final double totalCredit;

  const _LedgerResult({
    required this.rows,
    required this.totalDebit,
    required this.totalCredit,
  });
}

class _LedgerRow {
  final int id;
  final String code;
  final String name;
  final double debit;
  final double credit;

  const _LedgerRow({
    required this.id,
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
  });
}


