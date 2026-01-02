import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

/// Enhanced Invoices List Report with:
/// 1. Invoice status indicators (posted/cancelled/returned)
/// 2. Journal entry linkage verification
/// 3. Color-coded status badges
class InvoicesListReportPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<int> invoiceTypes;
  final String? partyTypeLabel;

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
        themeColor: color,
      ),
    );
  }
}

class _InvoicesListContent extends StatelessWidget {
  final ReportFilter filter;
  final List<int> invoiceTypes;
  final String? partyTypeLabel;
  final Color themeColor;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  _InvoicesListContent({
    required this.filter,
    required this.invoiceTypes,
    required this.partyTypeLabel,
    required this.themeColor,
  });

  String _formatCurrency(double value) {
    return '${_numberFormat.format(value)} ر.س';
  }

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
            // Summary Cards
            _buildSummaryCards(data),

            // Status Summary
            _buildStatusSummary(data),

            // Invoice List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.rows.length,
                itemBuilder: (context, index) {
                  final r = data.rows[index];
                  return _buildInvoiceCard(r);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(_InvoicesListResult data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildSummaryCard('عدد المستندات', '${data.count}', Icons.receipt, Colors.blue),
          _buildSummaryCard('الإجمالي', _formatCurrency(data.total), Icons.monetization_on, Colors.green),
          _buildSummaryCard('المتوسط', _formatCurrency(data.count > 0 ? data.total / data.count : 0), Icons.analytics, Colors.purple),
          _buildSummaryCard('مع قيود', '${data.withJournalEntry}', Icons.check_circle, Colors.teal),
          if (data.withoutJournalEntry > 0)
            _buildSummaryCard('بدون قيود', '${data.withoutJournalEntry}', Icons.warning, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
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
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 10))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(_InvoicesListResult data) {
    if (data.withoutJournalEntry == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text('جميع الفواتير مرتبطة بقيود محاسبية ✓',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'يوجد ${data.withoutJournalEntry} فاتورة بدون قيد محاسبي!',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(_InvoiceRow r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(r.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(r.status),
                color: _getStatusColor(r.status),
                size: 20,
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(r.number.isNotEmpty ? r.number : '#${r.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            // Journal Entry Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: r.hasJournalEntry ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    r.hasJournalEntry ? Icons.link : Icons.link_off,
                    size: 12,
                    color: r.hasJournalEntry ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    r.hasJournalEntry ? 'قيد' : 'بدون',
                    style: TextStyle(
                      fontSize: 10,
                      color: r.hasJournalEntry ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(r.dateLabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (partyTypeLabel != null && r.partyName.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(r.partyName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
            if (r.statement != null && r.statement!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(r.statement!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
            // Status Label
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(r.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(r.status),
                  style: TextStyle(fontSize: 10, color: _getStatusColor(r.status), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatCurrency(r.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(_getInvoiceTypeName(r.invoiceType), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1: return Colors.green;    // Posted/Completed
      case 2: return Colors.orange;   // Draft
      case 3: return Colors.red;      // Cancelled
      case 4: return Colors.purple;   // Returned
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1: return Icons.check_circle;
      case 2: return Icons.edit;
      case 3: return Icons.cancel;
      case 4: return Icons.undo;
      default: return Icons.receipt;
    }
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 1: return 'مُرحّلة';
      case 2: return 'مسودة';
      case 3: return 'ملغاة';
      case 4: return 'مرتجعة';
      default: return 'غير محدد';
    }
  }

  String _getInvoiceTypeName(int type) {
    switch (type) {
      case 1: return 'مبيعات';
      case 2: return 'مشتريات';
      case 3: return 'عرض سعر';
      case 4: return 'مرتجع مبيعات';
      case 5: return 'مرتجع مشتريات';
      default: return '';
    }
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

    final rows = await db.rawQuery('''
      SELECT
        i.id,
        i.number,
        i.date,
        i.statement,
        i.invoice_type,
        COALESCE(i.status, 1) as status,
        COALESCE(i.final_amt, i.total_amount, i.amount, 0) as amount,
        c.name as party_name,
        CASE WHEN EXISTS (
          SELECT 1 FROM journal_entries je 
          WHERE (je.reference_type LIKE '%sale%' OR je.reference_type LIKE '%purchase%' OR je.reference_type LIKE '%return%')
            AND je.reference_id = i.id
        ) THEN 1 ELSE 0 END as has_journal_entry
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      $where
      ORDER BY i.date DESC, i.id DESC
    ''', args);

    final parsed = rows.map((m) {
      return _InvoiceRow(
        id: (m['id'] as int?) ?? 0,
        number: (m['number'] as String?) ?? '',
        date: (m['date'] as int?) ?? 0,
        statement: m['statement'] as String?,
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        partyName: (m['party_name'] as String?) ?? '',
        invoiceType: (m['invoice_type'] as int?) ?? 0,
        status: (m['status'] as int?) ?? 1,
        hasJournalEntry: (m['has_journal_entry'] as int?) == 1,
      );
    }).toList();

    final total = parsed.fold<double>(0, (s, r) => s + r.amount);
    final withEntry = parsed.where((r) => r.hasJournalEntry).length;

    return _InvoicesListResult(
      rows: parsed,
      total: total,
      withJournalEntry: withEntry,
      withoutJournalEntry: parsed.length - withEntry,
    );
  }
}

class _InvoicesListResult {
  final List<_InvoiceRow> rows;
  final double total;
  final int withJournalEntry;
  final int withoutJournalEntry;
  int get count => rows.length;

  const _InvoicesListResult({
    required this.rows,
    required this.total,
    required this.withJournalEntry,
    required this.withoutJournalEntry,
  });
}

class _InvoiceRow {
  final int id;
  final String number;
  final int date;
  final String? statement;
  final double amount;
  final String partyName;
  final int invoiceType;
  final int status;
  final bool hasJournalEntry;

  const _InvoiceRow({
    required this.id,
    required this.number,
    required this.date,
    required this.statement,
    required this.amount,
    required this.partyName,
    required this.invoiceType,
    required this.status,
    required this.hasJournalEntry,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(date * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}
