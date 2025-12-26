import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class CashFlowReportPage extends StatelessWidget {
  const CashFlowReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'التدفقات النقدية',
      icon: Icons.water_drop,
      color: const Color(0xFF00ACC1),
      reportBuilder: (filter) => _CashFlowContent(filter: filter),
    );
  }
}

class _CashFlowContent extends StatelessWidget {
  final ReportFilter filter;

  const _CashFlowContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CashFlowResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
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
                  title: 'إجمالي الداخل',
                  value: data.totalIn.toStringAsFixed(2),
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الخارج',
                  value: data.totalOut.toStringAsFixed(2),
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                ),
                ReportSummaryCard(
                  title: 'صافي التدفق',
                  value: data.net.toStringAsFixed(2),
                  icon: Icons.compare_arrows,
                  color: data.net >= 0 ? Colors.blue : Colors.red,
                ),
              ],
            ),
            Expanded(
              child: data.entries.isEmpty
                  ? const Center(child: Text('لا توجد حركات نقدية في الفترة المحددة'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.entries.length,
                      itemBuilder: (context, index) {
                        final e = data.entries[index];
                        return Card(
                          child: ListTile(
                            title: Text(e.description ?? ''),
                            subtitle: Text('${e.dateLabel} | ${e.accountName}'),
                            trailing: Text(
                              (e.net >= 0 ? '+${e.net.toStringAsFixed(2)}' : e.net.toStringAsFixed(2)),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: e.net >= 0 ? Colors.green : Colors.red,
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

  Future<_CashFlowResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;

    // Cash accounts are connected via account_connects:
    // 0 = banks, 1 = cashboxes
    final connects = await db.rawQuery(
      '''
      SELECT ac.c_id, a.id as account_id, a.name as account_name
      FROM account_connects ac
      INNER JOIN accounts a ON a.c_id = ac.c_id
      WHERE ac.account_connect_type IN (0, 1)
      ''',
    );

    final accountIds = connects
        .map((m) => m['account_id'] as int?)
        .whereType<int>()
        .toList();

    if (accountIds.isEmpty) {
      return const _CashFlowResult(totalIn: 0, totalOut: 0, entries: []);
    }

    final args = <Object?>[];
    final whereParts = <String>[
      'je.is_posted = 1',
      'jel.account_id IN (${accountIds.map((_) => '?').join(',')})',
    ];
    args.addAll(accountIds);

    if (filter.startDate != null && filter.endDate != null) {
      whereParts.add('je.entry_date >= ? AND je.entry_date <= ?');
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        je.entry_date,
        je.description,
        a.name as account_name,
        COALESCE(jel.debit_amount, 0) as debit_amount,
        COALESCE(jel.credit_amount, 0) as credit_amount
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE ${whereParts.join(' AND ')}
      ORDER BY je.entry_date DESC
      LIMIT 200
      ''',
      args,
    );

    final entries = rows.map((m) {
      final debit = (m['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (m['credit_amount'] as num?)?.toDouble() ?? 0.0;
      return _CashFlowEntry(
        entryDate: (m['entry_date'] as int?) ?? 0,
        description: m['description'] as String?,
        accountName: (m['account_name'] as String?) ?? '',
        net: debit - credit,
      );
    }).toList();

    final totalIn = entries.where((e) => e.net > 0).fold<double>(0, (s, e) => s + e.net);
    final totalOut = entries.where((e) => e.net < 0).fold<double>(0, (s, e) => s + e.net.abs());

    return _CashFlowResult(totalIn: totalIn, totalOut: totalOut, entries: entries);
  }
}

class _CashFlowResult {
  final double totalIn;
  final double totalOut;
  final List<_CashFlowEntry> entries;

  const _CashFlowResult({
    required this.totalIn,
    required this.totalOut,
    required this.entries,
  });

  double get net => totalIn - totalOut;
}

class _CashFlowEntry {
  final int entryDate;
  final String? description;
  final String accountName;
  final double net;

  const _CashFlowEntry({
    required this.entryDate,
    required this.description,
    required this.accountName,
    required this.net,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(entryDate * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}


