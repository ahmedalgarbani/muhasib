import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';

class JournalReportPage extends StatelessWidget {
  const JournalReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير اليومية',
      icon: Icons.event_note,
      color: const Color(0xFF607D8B),
      reportBuilder: (filter) => _JournalReportContent(filter: filter),
    );
  }
}

class _JournalReportContent extends StatelessWidget {
  final ReportFilter filter;

  const _JournalReportContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_JournalEntryRow>>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('لا توجد قيود في الفترة المحددة'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final e = rows[index];
            return Card(
              child: ExpansionTile(
                title: Text('${e.number ?? ''} - ${e.description ?? ''}'),
                subtitle: Text('التاريخ: ${e.dateLabel} | مدين: ${e.totalDebit.toStringAsFixed(2)} | دائن: ${e.totalCredit.toStringAsFixed(2)}'),
                children: [
                  for (final l in e.lines)
                    ListTile(
                      dense: true,
                      title: Text('${l.accountCode} - ${l.accountName}'),
                      subtitle: l.notes == null ? null : Text(l.notes!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.debitAmount > 0 ? l.debitAmount.toStringAsFixed(2) : '-',
                            style: const TextStyle(color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l.creditAmount > 0 ? l.creditAmount.toStringAsFixed(2) : '-',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_JournalEntryRow>> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];

    String where = 'is_posted = 1';
    if (filter.startDate != null && filter.endDate != null) {
      where += ' AND entry_date >= ? AND entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final entries = await db.query(
      'journal_entries',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'entry_date DESC, id DESC',
    );

    final results = <_JournalEntryRow>[];
    for (final e in entries) {
      final lines = await db.rawQuery(
        '''
        SELECT
          jel.*,
          a.code AS account_code_fallback,
          a.name AS account_name_fallback
        FROM journal_entry_lines jel
        LEFT JOIN accounts a ON a.id = jel.account_id
        WHERE jel.journal_entry_id = ?
        ORDER BY jel.line_number, jel.id
        ''',
        [e['id']],
      );
      results.add(
        _JournalEntryRow.fromDb(e, lines),
      );
    }
    return results;
  }
}

class _JournalEntryRow {
  final int id;
  final String? number;
  final int entryDate;
  final String? description;
  final double totalDebit;
  final double totalCredit;
  final List<_JournalLineRow> lines;

  const _JournalEntryRow({
    required this.id,
    required this.number,
    required this.entryDate,
    required this.description,
    required this.totalDebit,
    required this.totalCredit,
    required this.lines,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(entryDate * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }

  factory _JournalEntryRow.fromDb(
    Map<String, dynamic> e,
    List<Map<String, dynamic>> lines,
  ) {
    return _JournalEntryRow(
      id: e['id'] as int,
      number: e['number'] as String?,
      entryDate: (e['entry_date'] as int?) ?? 0,
      description: e['description'] as String?,
      totalDebit: (e['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (e['total_credit'] as num?)?.toDouble() ?? 0.0,
      lines: lines.map(_JournalLineRow.fromDb).toList(),
    );
  }
}

class _JournalLineRow {
  final int id;
  final String accountCode;
  final String accountName;
  final double debitAmount;
  final double creditAmount;
  final String? notes;

  const _JournalLineRow({
    required this.id,
    required this.accountCode,
    required this.accountName,
    required this.debitAmount,
    required this.creditAmount,
    required this.notes,
  });

  factory _JournalLineRow.fromDb(Map<String, dynamic> l) {
    final code = (l['account_code'] as String?) ??
        (l['account_code_fallback'] as String?) ??
        '';
    final name = (l['account_name'] as String?) ??
        (l['account_name_fallback'] as String?) ??
        '';
    return _JournalLineRow(
      id: l['id'] as int,
      accountCode: code,
      accountName: name,
      debitAmount: (l['debit_amount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (l['credit_amount'] as num?)?.toDouble() ?? 0.0,
      notes: (l['notes'] as String?) ?? (l['description'] as String?),
    );
  }
}


