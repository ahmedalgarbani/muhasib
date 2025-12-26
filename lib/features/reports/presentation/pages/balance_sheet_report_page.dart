import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class BalanceSheetReportPage extends StatelessWidget {
  const BalanceSheetReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'الميزانية العمومية',
      icon: Icons.account_balance,
      color: const Color(0xFF7B1FA2),
      // Balance sheet is as-of date; we use the end date from filter.
      reportBuilder: (filter) => _BalanceSheetContent(filter: filter),
    );
  }
}

class _BalanceSheetContent extends StatelessWidget {
  final ReportFilter filter;

  const _BalanceSheetContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    final dbService = getIt<DatabaseService>();
    return FutureBuilder<_BalanceSheetResult>(
      future: _load(dbService, filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ: ${snapshot.error}'),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي الأصول',
                  value: '${data.totalAssets.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الخصوم',
                  value: '${data.totalLiabilities.toStringAsFixed(2)}',
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
                ReportSummaryCard(
                  title: 'حقوق الملكية (محسوبة)',
                  value: '${data.equity.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section(
                    title: 'الأصول',
                    color: Colors.green,
                    rows: data.assets,
                  ),
                  const SizedBox(height: 12),
                  _section(
                    title: 'الخصوم',
                    color: Colors.red,
                    rows: data.liabilities,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _section({
    required String title,
    required Color color,
    required List<_AccountBalanceRow> rows,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('لا توجد بيانات'),
              )
            else
              ...rows.map(
                (r) => ListTile(
                  dense: true,
                  title: Text('${r.code} - ${r.name}'),
                  trailing: Text(
                    r.displayAmount.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<_BalanceSheetResult> _load(
    DatabaseService databaseService,
    ReportFilter filter,
  ) async {
    final db = await databaseService.database;

    // Use endDate as "as-of". If no endDate, use now.
    final asOf = (filter.endDate ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

    final rows = await db.rawQuery(
      '''
      SELECT
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        a.type as account_type,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as net
      FROM accounts a
      LEFT JOIN journal_entry_lines jel ON jel.account_id = a.id
      LEFT JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1
        AND (je.is_posted = 1 OR je.id IS NULL)
        AND (je.entry_date <= ? OR je.id IS NULL)
        AND a.type IN (1, 2)
      GROUP BY a.id, a.code, a.name, a.type
      ORDER BY a.code
      ''',
      [asOf],
    );

    final assets = <_AccountBalanceRow>[];
    final liabilities = <_AccountBalanceRow>[];

    double totalAssets = 0;
    double totalLiabilities = 0;

    for (final m in rows) {
      final type = (m['account_type'] as int?) ?? 0;
      final net = (m['net'] as num?)?.toDouble() ?? 0.0; // debit - credit
      final row = _AccountBalanceRow(
        id: (m['account_id'] as int?) ?? 0,
        code: (m['account_code'] as String?) ?? '',
        name: (m['account_name'] as String?) ?? '',
        type: type,
        net: net,
      );

      if (type == 1) {
        // Assets: show positive (debit) net. If credit net, show as negative (rare).
        assets.add(row);
        totalAssets += row.displayAmount;
      } else if (type == 2) {
        // Liabilities: normal balance is credit, so display as positive credit = -(debit-credit)
        liabilities.add(row);
        totalLiabilities += row.displayAmount;
      }
    }

    final equity = totalAssets - totalLiabilities;

    return _BalanceSheetResult(
      assets: assets,
      liabilities: liabilities,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      equity: equity,
    );
  }
}

class _BalanceSheetResult {
  final List<_AccountBalanceRow> assets;
  final List<_AccountBalanceRow> liabilities;
  final double totalAssets;
  final double totalLiabilities;
  final double equity;

  const _BalanceSheetResult({
    required this.assets,
    required this.liabilities,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.equity,
  });
}

class _AccountBalanceRow {
  final int id;
  final String code;
  final String name;
  final int type; // 1 assets, 2 liabilities
  final double net; // debit - credit (as-of)

  const _AccountBalanceRow({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.net,
  });

  double get displayAmount {
    if (type == 2) return -net; // liabilities show credit as positive
    return net;
  }
}


