import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

/// Enhanced Journal Report with:
/// 1. Chronological ordering preservation
/// 2. Posted vs Draft status indicators
/// 3. Balance verification per entry
/// 4. Protection indicators for posted entries
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
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  _JournalReportContent({required this.filter});

  String _formatCurrency(double value) {
    return _numberFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_JournalReportResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                Text('خطأ: ${snapshot.error}'),
              ],
            ),
          );
        }
        final data = snapshot.data;
        if (data == null || data.entries.isEmpty) {
          return const Center(child: Text('لا توجد قيود في الفترة المحددة'));
        }

        return Column(
          children: [
            // Summary Row
            _buildSummaryCards(data),

            // Integrity Check
            if (data.unbalancedCount > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تحذير: يوجد ${data.unbalancedCount} قيد غير متوازن!',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Journal Entries List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.entries.length,
                itemBuilder: (context, index) {
                  final entry = data.entries[index];
                  return _buildJournalEntryCard(context, entry, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(_JournalReportResult data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildSummaryCard('عدد القيود', '${data.entries.length}', Icons.event_note, Colors.blue),
          _buildSummaryCard('المرحّلة', '${data.postedCount}', Icons.check_circle, Colors.green),
          _buildSummaryCard('المسودات', '${data.draftCount}', Icons.edit_note, Colors.orange),
          _buildSummaryCard('إجمالي المدين', _formatCurrency(data.totalDebit), Icons.arrow_upward, Colors.blue),
          _buildSummaryCard('إجمالي الدائن', _formatCurrency(data.totalCredit), Icons.arrow_downward, Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildJournalEntryCard(BuildContext context, _JournalEntryRow entry, int index) {
    final isBalanced = (entry.totalDebit - entry.totalCredit).abs() < 0.01;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: entry.isPosted ? const Color(0xFF607D8B) : Colors.orange,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Entry Number & Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.isPosted ? Icons.lock : Icons.edit,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.number ?? '#${entry.id}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Description
                Expanded(
                  child: Text(
                    entry.description ?? 'بدون وصف',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Date
                Text(
                  entry.dateLabel,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),

          // Balance Check Warning
          if (!isBalanced)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.red[100],
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'قيد غير متوازن! الفرق: ${_formatCurrency((entry.totalDebit - entry.totalCredit).abs())}',
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
              ),
            ),

          // Reference Info
          if (entry.referenceType != null || entry.referenceNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.link, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'المرجع: ${entry.referenceType ?? ''} ${entry.referenceNumber ?? ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Lines Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[200],
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('مدين', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue))),
                Expanded(flex: 2, child: Text('دائن', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
              ],
            ),
          ),

          // Lines
          ...entry.lines.map((line) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${line.accountCode} - ${line.accountName}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (line.notes != null && line.notes!.isNotEmpty)
                        Text(
                          line.notes!,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    line.debitAmount > 0 ? _formatCurrency(line.debitAmount) : '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: line.debitAmount > 0 ? Colors.blue : Colors.grey),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    line.creditAmount > 0 ? _formatCurrency(line.creditAmount) : '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: line.creditAmount > 0 ? Colors.green : Colors.grey),
                  ),
                ),
              ],
            ),
          )),

          // Totals Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      // Posted Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.isPosted ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.isPosted ? 'مُرحَّل ✓' : 'مسودة',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (entry.isPosted)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatCurrency(entry.totalDebit),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatCurrency(entry.totalCredit),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<_JournalReportResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];

    // Include both posted and draft entries for transparency
    String where = '1=1';
    if (filter.startDate != null && filter.endDate != null) {
      where += ' AND entry_date >= ? AND entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final entries = await db.query(
      'journal_entries',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'entry_date ASC, id ASC',  // Chronological order
    );

    final results = <_JournalEntryRow>[];
    double totalDebit = 0;
    double totalCredit = 0;
    int postedCount = 0;
    int draftCount = 0;
    int unbalancedCount = 0;

    for (final e in entries) {
      final lines = await db.rawQuery('''
        SELECT
          jel.*,
          a.code AS account_code_fallback,
          a.name AS account_name_fallback
        FROM journal_entry_lines jel
        LEFT JOIN accounts a ON a.id = jel.account_id
        WHERE jel.journal_entry_id = ?
        ORDER BY jel.line_number, jel.id
      ''', [e['id']]);

      final entry = _JournalEntryRow.fromDb(e, lines);
      results.add(entry);

      totalDebit += entry.totalDebit;
      totalCredit += entry.totalCredit;

      if (entry.isPosted) {
        postedCount++;
      } else {
        draftCount++;
      }

      if ((entry.totalDebit - entry.totalCredit).abs() > 0.01) {
        unbalancedCount++;
      }
    }

    return _JournalReportResult(
      entries: results,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      postedCount: postedCount,
      draftCount: draftCount,
      unbalancedCount: unbalancedCount,
    );
  }
}

class _JournalReportResult {
  final List<_JournalEntryRow> entries;
  final double totalDebit;
  final double totalCredit;
  final int postedCount;
  final int draftCount;
  final int unbalancedCount;

  const _JournalReportResult({
    required this.entries,
    required this.totalDebit,
    required this.totalCredit,
    required this.postedCount,
    required this.draftCount,
    required this.unbalancedCount,
  });
}

class _JournalEntryRow {
  final int id;
  final String? number;
  final int entryDate;
  final String? description;
  final String? referenceType;
  final String? referenceNumber;
  final bool isPosted;
  final double totalDebit;
  final double totalCredit;
  final List<_JournalLineRow> lines;

  const _JournalEntryRow({
    required this.id,
    required this.number,
    required this.entryDate,
    required this.description,
    required this.referenceType,
    required this.referenceNumber,
    required this.isPosted,
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
      referenceType: e['reference_type'] as String?,
      referenceNumber: e['reference_number'] as String?,
      isPosted: (e['is_posted'] as int?) == 1,
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
