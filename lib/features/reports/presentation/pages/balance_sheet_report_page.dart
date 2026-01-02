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
                  title: 'إجمالي حقوق الملكية',
                  value: '${data.totalEquity.toStringAsFixed(2)}',
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
                  const SizedBox(height: 12),
                  _section(
                    title: 'حقوق الملكية',
                    color: Colors.blue,
                    rows: data.equityRows,
                  ),
                  const SizedBox(height: 12),
                  if ((data.totalAssets - (data.totalLiabilities + data.totalEquity)).abs() > 0.01)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red[100],
                      child: Text(
                        'تنبيه: الميزانية غير متوازنة! الفرق: ${(data.totalAssets - (data.totalLiabilities + data.totalEquity)).toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
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

    // 1. Fetch Permanent Accounts (Assets, Liabilities, Equity)
    // Account Types: 0=Assets, 1=Liabilities, 2=Equity
    final balanceSheetAccounts = await db.rawQuery(
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
        AND a.type IN (0, 1, 2)
      GROUP BY a.id, a.code, a.name, a.type
      HAVING net != 0
      ORDER BY a.code
      ''',
      [asOf],
    );

    // 2. Calculate Net Income (Revenue - Expenses) for Retained Earnings
    // Account Types: 3=Revenue, 4=Expenses
    // Revenue (Credit normal) -> Credit - Debit
    // Expenses (Debit normal) -> Debit - Credit
    // Net Income = Revenue - Expenses
    // In terms of (Debit - Credit):
    // Revenue net = (D - C) [usually negative]
    // Expenses net = (D - C) [usually positive]
    // Net Income = -(Revenue net) - (Expenses net) = - (Revenue net + Expenses net)
    // Or simply: Sum(Credit - Debit) for all P&L accounts.
    final netIncomeResult = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as net_income
      FROM accounts a
      JOIN journal_entry_lines jel ON jel.account_id = a.id
      JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1
        AND je.is_posted = 1
        AND je.entry_date <= ?
        AND a.type IN (3, 4)
      ''',
      [asOf],
    );
    
    final netIncome = (netIncomeResult.first['net_income'] as num?)?.toDouble() ?? 0.0;

    final assets = <_AccountBalanceRow>[];
    final liabilities = <_AccountBalanceRow>[];
    final equityRows = <_AccountBalanceRow>[];

    double totalAssets = 0;
    double totalLiabilities = 0;
    double totalEquityAccounts = 0;

    for (final m in balanceSheetAccounts) {
      final type = (m['account_type'] as int?) ?? 0;
      final net = (m['net'] as num?)?.toDouble() ?? 0.0; // debit - credit

      final row = _AccountBalanceRow(
        id: (m['account_id'] as int?) ?? 0,
        code: (m['account_code'] as String?) ?? '',
        name: (m['account_name'] as String?) ?? '',
        type: type,
        net: net,
      );

      if (type == 0) {
        // Assets (Debit Normal)
        assets.add(row);
        totalAssets += row.displayAmount;
      } else if (type == 1) {
        // Liabilities (Credit Normal)
        liabilities.add(row);
        totalLiabilities += row.displayAmount;
      } else if (type == 2) {
        // Equity (Credit Normal)
        equityRows.add(row);
        totalEquityAccounts += row.displayAmount;
      }
    }

    // Add Net Income to Equity
    if (netIncome != 0) {
      equityRows.add(_AccountBalanceRow(
        id: -1,
        code: 'NI',
        name: 'صافي دخل الفترة',
        type: 2, // Treat as Equity
        net: -netIncome, // Convert to (Debit - Credit) format for consistency with row.displayAmount logic (which negates for type 2)
      ));
      totalEquityAccounts += netIncome;
    }

    return _BalanceSheetResult(
      assets: assets,
      liabilities: liabilities,
      equityRows: equityRows,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalEquity: totalEquityAccounts,
    );
  }
}

class _BalanceSheetResult {
  final List<_AccountBalanceRow> assets;
  final List<_AccountBalanceRow> liabilities;
  final List<_AccountBalanceRow> equityRows;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;

  const _BalanceSheetResult({
    required this.assets,
    required this.liabilities,
    required this.equityRows,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
  });
}

class _AccountBalanceRow {
  final int id;
  final String code;
  final String name;
  final int type; // 0 assets, 1 liabilities, 2 equity
  final double net; // debit - credit (as-of)

  const _AccountBalanceRow({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.net,
  });

  double get displayAmount {
    if (type == 1 || type == 2) return -net; // liabilities and equity show credit as positive
    return net;
  }
}


