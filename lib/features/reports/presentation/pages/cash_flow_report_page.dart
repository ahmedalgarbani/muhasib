import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

/// Enhanced Cash Flow Report with:
/// 1. Opening and closing cash balances
/// 2. Activity classification (Operating, Investing, Financing)
/// 3. Balance verification with actual cash accounts
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
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  _CashFlowContent({required this.filter});

  String _formatCurrency(double value) {
    return '${_numberFormat.format(value)} ر.س';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CashFlowResult>(
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
        if (data == null) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final balanceMatches = (data.closingBalance - data.actualCashBalance).abs() < 0.01;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Summary Cards
              _buildBalanceSummary(data, balanceMatches),

              const SizedBox(height: 16),

              // Balance Verification
              _buildBalanceVerification(data, balanceMatches),

              const SizedBox(height: 16),

              // Activities Breakdown
              _buildActivitySection(
                'الأنشطة التشغيلية',
                'Operating Activities',
                Icons.business,
                Colors.blue,
                data.operatingActivities,
                data.totalOperating,
              ),

              const SizedBox(height: 12),

              _buildActivitySection(
                'الأنشطة الاستثمارية',
                'Investing Activities',
                Icons.trending_up,
                Colors.orange,
                data.investingActivities,
                data.totalInvesting,
              ),

              const SizedBox(height: 12),

              _buildActivitySection(
                'الأنشطة التمويلية',
                'Financing Activities',
                Icons.account_balance,
                Colors.purple,
                data.financingActivities,
                data.totalFinancing,
              ),

              const SizedBox(height: 16),

              // Net Change Summary
              _buildNetChangeSummary(data),

              const SizedBox(height: 16),

              // Detailed Transactions
              if (data.entries.isNotEmpty)
                _buildTransactionsList(data.entries),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceSummary(_CashFlowResult data, bool matches) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildBalanceCard('الرصيد الافتتاحي', data.openingBalance, Colors.grey)),
                const SizedBox(width: 8),
                Expanded(child: _buildBalanceCard('صافي التدفق', data.netCashFlow, 
                    data.netCashFlow >= 0 ? Colors.green : Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _buildBalanceCard('الرصيد الختامي', data.closingBalance, Colors.blue)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _buildBalanceCard('إجمالي الداخل', data.totalIn, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildBalanceCard('إجمالي الخارج', data.totalOut, Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(value),
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceVerification(_CashFlowResult data, bool matches) {
    return Card(
      color: matches ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(matches ? Icons.check_circle : Icons.warning,
                color: matches ? Colors.green : Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matches ? 'الرصيد متطابق ✓' : 'تحذير: الرصيد غير متطابق!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: matches ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الرصيد الفعلي في حسابات النقد: ${_formatCurrency(data.actualCashBalance)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<_CashFlowEntry> entries,
    double total,
  ) {
    if (entries.isEmpty && total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(
          'صافي: ${_formatCurrency(total)}',
          style: TextStyle(color: total >= 0 ? Colors.green : Colors.red),
        ),
        children: [
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد حركات'),
            )
          else
            ...entries.map((e) => ListTile(
              dense: true,
              title: Text(e.description ?? 'بدون وصف', style: const TextStyle(fontSize: 13)),
              subtitle: Text('${e.dateLabel} | ${e.accountName}', style: const TextStyle(fontSize: 11)),
              trailing: Text(
                e.net >= 0 ? '+${_formatCurrency(e.net)}' : _formatCurrency(e.net),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: e.net >= 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildNetChangeSummary(_CashFlowResult data) {
    return Card(
      color: const Color(0xFF00ACC1).withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('ملخص التغير في النقدية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _buildSummaryRow('الرصيد الافتتاحي', data.openingBalance),
            _buildSummaryRow('صافي الأنشطة التشغيلية', data.totalOperating, 
                color: data.totalOperating >= 0 ? Colors.green : Colors.red),
            _buildSummaryRow('صافي الأنشطة الاستثمارية', data.totalInvesting,
                color: data.totalInvesting >= 0 ? Colors.green : Colors.red),
            _buildSummaryRow('صافي الأنشطة التمويلية', data.totalFinancing,
                color: data.totalFinancing >= 0 ? Colors.green : Colors.red),
            const Divider(),
            _buildSummaryRow('صافي التغير في النقدية', data.netCashFlow,
                color: data.netCashFlow >= 0 ? Colors.green : Colors.red, isBold: true),
            _buildSummaryRow('الرصيد الختامي', data.closingBalance, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<_CashFlowEntry> entries) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.list, color: Colors.grey),
        title: const Text('تفاصيل الحركات'),
        subtitle: Text('${entries.length} حركة'),
        children: entries.map((e) => ListTile(
          dense: true,
          title: Text(e.description ?? 'بدون وصف'),
          subtitle: Text('${e.dateLabel} | ${e.accountName} | ${e.referenceType ?? ""}'),
          trailing: Text(
            e.net >= 0 ? '+${_formatCurrency(e.net)}' : _formatCurrency(e.net),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: e.net >= 0 ? Colors.green : Colors.red,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Future<_CashFlowResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;

    // Get cash account IDs (banks=0, cashboxes=1)
    final connects = await db.rawQuery('''
      SELECT ac.c_id, a.id as account_id, a.name as account_name
      FROM account_connects ac
      INNER JOIN accounts a ON a.c_id = ac.c_id
      WHERE ac.account_connect_type IN (0, 1)
    ''');

    final accountIds = connects
        .map((m) => m['account_id'] as int?)
        .whereType<int>()
        .toList();

    if (accountIds.isEmpty) {
      return const _CashFlowResult(
        openingBalance: 0,
        closingBalance: 0,
        actualCashBalance: 0,
        totalIn: 0,
        totalOut: 0,
        totalOperating: 0,
        totalInvesting: 0,
        totalFinancing: 0,
        operatingActivities: [],
        investingActivities: [],
        financingActivities: [],
        entries: [],
      );
    }

    final startSec = (filter.startDate ?? DateTime(2020)).millisecondsSinceEpoch ~/ 1000;
    final endSec = (filter.endDate ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

    // 1. Calculate Opening Balance (before period start)
    final openingResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as balance
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE je.is_posted = 1 
        AND jel.account_id IN (${accountIds.join(',')})
        AND je.entry_date < ?
    ''', [startSec]);
    final openingBalance = (openingResult.first['balance'] as num?)?.toDouble() ?? 0.0;

    // 2. Calculate Actual Current Balance (up to period end)
    final actualResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as balance
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE je.is_posted = 1 
        AND jel.account_id IN (${accountIds.join(',')})
        AND je.entry_date <= ?
    ''', [endSec]);
    final actualCashBalance = (actualResult.first['balance'] as num?)?.toDouble() ?? 0.0;

    // 3. Get all cash movements during period
    final rows = await db.rawQuery('''
      SELECT
        je.id as entry_id,
        je.entry_date,
        je.description,
        je.reference_type,
        a.name as account_name,
        COALESCE(jel.debit_amount, 0) as debit_amount,
        COALESCE(jel.credit_amount, 0) as credit_amount
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE je.is_posted = 1
        AND jel.account_id IN (${accountIds.join(',')})
        AND je.entry_date >= ? AND je.entry_date <= ?
      ORDER BY je.entry_date, jel.id
    ''', [startSec, endSec]);

    final entries = <_CashFlowEntry>[];
    final operatingActivities = <_CashFlowEntry>[];
    final investingActivities = <_CashFlowEntry>[];
    final financingActivities = <_CashFlowEntry>[];

    double totalIn = 0;
    double totalOut = 0;

    for (final m in rows) {
      final debit = (m['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (m['credit_amount'] as num?)?.toDouble() ?? 0.0;
      final net = debit - credit;
      final refType = (m['reference_type'] as String?) ?? '';

      final entry = _CashFlowEntry(
        entryId: (m['entry_id'] as int?) ?? 0,
        entryDate: (m['entry_date'] as int?) ?? 0,
        description: m['description'] as String?,
        accountName: (m['account_name'] as String?) ?? '',
        referenceType: refType,
        net: net,
      );

      entries.add(entry);

      if (net > 0) {
        totalIn += net;
      } else {
        totalOut += net.abs();
      }

      // Classify by reference_type
      if (_isOperatingActivity(refType)) {
        operatingActivities.add(entry);
      } else if (_isInvestingActivity(refType)) {
        investingActivities.add(entry);
      } else if (_isFinancingActivity(refType)) {
        financingActivities.add(entry);
      } else {
        // Default to operating
        operatingActivities.add(entry);
      }
    }

    final totalOperating = operatingActivities.fold<double>(0, (s, e) => s + e.net);
    final totalInvesting = investingActivities.fold<double>(0, (s, e) => s + e.net);
    final totalFinancing = financingActivities.fold<double>(0, (s, e) => s + e.net);
    final netCashFlow = totalIn - totalOut;
    final closingBalance = openingBalance + netCashFlow;

    return _CashFlowResult(
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      actualCashBalance: actualCashBalance,
      totalIn: totalIn,
      totalOut: totalOut,
      totalOperating: totalOperating,
      totalInvesting: totalInvesting,
      totalFinancing: totalFinancing,
      operatingActivities: operatingActivities,
      investingActivities: investingActivities,
      financingActivities: financingActivities,
      entries: entries,
    );
  }

  bool _isOperatingActivity(String refType) {
    return refType.contains('sale') || 
           refType.contains('purchase') || 
           refType.contains('receipt') ||
           refType.contains('payment') ||
           refType.contains('expense');
  }

  bool _isInvestingActivity(String refType) {
    return refType.contains('asset') || 
           refType.contains('investment') ||
           refType.contains('equipment');
  }

  bool _isFinancingActivity(String refType) {
    return refType.contains('loan') || 
           refType.contains('capital') ||
           refType.contains('dividend') ||
           refType.contains('equity');
  }
}

class _CashFlowResult {
  final double openingBalance;
  final double closingBalance;
  final double actualCashBalance;
  final double totalIn;
  final double totalOut;
  final double totalOperating;
  final double totalInvesting;
  final double totalFinancing;
  final List<_CashFlowEntry> operatingActivities;
  final List<_CashFlowEntry> investingActivities;
  final List<_CashFlowEntry> financingActivities;
  final List<_CashFlowEntry> entries;

  const _CashFlowResult({
    required this.openingBalance,
    required this.closingBalance,
    required this.actualCashBalance,
    required this.totalIn,
    required this.totalOut,
    required this.totalOperating,
    required this.totalInvesting,
    required this.totalFinancing,
    required this.operatingActivities,
    required this.investingActivities,
    required this.financingActivities,
    required this.entries,
  });

  double get netCashFlow => totalIn - totalOut;
}

class _CashFlowEntry {
  final int entryId;
  final int entryDate;
  final String? description;
  final String accountName;
  final String? referenceType;
  final double net;

  const _CashFlowEntry({
    required this.entryId,
    required this.entryDate,
    required this.description,
    required this.accountName,
    required this.referenceType,
    required this.net,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(entryDate * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}
