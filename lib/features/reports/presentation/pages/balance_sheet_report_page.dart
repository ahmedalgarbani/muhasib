import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

class BalanceSheetReportPage extends StatelessWidget {
  const BalanceSheetReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'الميزانية العمومية',
      icon: Icons.account_balance,
      color: const Color(0xFF7B1FA2),
      reportBuilder: (filter) => _BalanceSheetContent(filter: filter),
    );
  }
}

class _BalanceSheetContent extends StatelessWidget {
  final ReportFilter filter;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  _BalanceSheetContent({required this.filter});

  String _formatCurrency(double value) {
    return '${_numberFormat.format(value)} ر.س';
  }

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ: ${snapshot.error}'),
              ],
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final isBalanced = data.difference.abs() < 0.01;

        return Column(
          children: [
            // Summary Cards
            _buildSummaryCards(data, isBalanced),

            // Balance Equation Verification
            _buildEquationCard(data, isBalanced),

            // Main Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ASSETS SECTION
                  _buildSectionCard(
                    title: 'الأصول',
                    color: Colors.green,
                    icon: Icons.trending_up,
                    subsections: [
                      if (data.currentAssets.isNotEmpty)
                        _SubSection(
                          title: 'الأصول المتداولة',
                          rows: data.currentAssets,
                          total: data.totalCurrentAssets,
                        ),
                      if (data.fixedAssets.isNotEmpty)
                        _SubSection(
                          title: 'الأصول الثابتة',
                          rows: data.fixedAssets,
                          total: data.totalFixedAssets,
                        ),
                      if (data.otherAssets.isNotEmpty)
                        _SubSection(
                          title: 'أصول أخرى',
                          rows: data.otherAssets,
                          total: data.totalOtherAssets,
                        ),
                    ],
                    grandTotal: data.totalAssets,
                    grandTotalLabel: 'إجمالي الأصول',
                  ),

                  const SizedBox(height: 16),

                  // LIABILITIES SECTION
                  _buildSectionCard(
                    title: 'الخصوم',
                    color: Colors.red,
                    icon: Icons.trending_down,
                    subsections: [
                      if (data.currentLiabilities.isNotEmpty)
                        _SubSection(
                          title: 'الخصوم المتداولة',
                          rows: data.currentLiabilities,
                          total: data.totalCurrentLiabilities,
                        ),
                      if (data.longTermLiabilities.isNotEmpty)
                        _SubSection(
                          title: 'الخصوم طويلة الأجل',
                          rows: data.longTermLiabilities,
                          total: data.totalLongTermLiabilities,
                        ),
                    ],
                    grandTotal: data.totalLiabilities,
                    grandTotalLabel: 'إجمالي الخصوم',
                  ),

                  const SizedBox(height: 16),

                  // EQUITY SECTION
                  _buildSectionCard(
                    title: 'حقوق الملكية',
                    color: Colors.blue,
                    icon: Icons.account_balance_wallet,
                    subsections: [
                      _SubSection(
                        title: 'رأس المال والاحتياطيات',
                        rows: data.equityRows,
                        total: data.totalEquity,
                      ),
                    ],
                    grandTotal: data.totalEquity,
                    grandTotalLabel: 'إجمالي حقوق الملكية',
                    showNetIncome: true,
                    netIncome: data.netIncome,
                    retainedEarnings: data.retainedEarnings,
                  ),

                  const SizedBox(height: 16),

                  // LIABILITIES + EQUITY TOTAL
                  _buildGrandTotalCard(
                    'إجمالي الخصوم وحقوق الملكية',
                    data.totalLiabilities + data.totalEquity,
                    Colors.purple,
                    isBalanced: isBalanced,
                    assetsTotal: data.totalAssets,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(_BalanceSheetResult data, bool isBalanced) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildSummaryCard('الأصول', data.totalAssets, Icons.trending_up, Colors.green),
          _buildSummaryCard('الخصوم', data.totalLiabilities, Icons.trending_down, Colors.red),
          _buildSummaryCard('حقوق الملكية', data.totalEquity, Icons.account_balance_wallet, Colors.blue),
          _buildSummaryCard(
            'صافي الدخل',
            data.netIncome,
            data.netIncome >= 0 ? Icons.thumb_up : Icons.thumb_down,
            data.netIncome >= 0 ? Colors.teal : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatCurrency(value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEquationCard(_BalanceSheetResult data, bool isBalanced) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: isBalanced ? Colors.green[50] : Colors.red[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBalanced ? Icons.check_circle : Icons.warning,
                    color: isBalanced ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBalanced ? 'المعادلة المحاسبية متوازنة ✓' : 'تحذير: الميزانية غير متوازنة!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isBalanced ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Accounting Equation Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _equationElement('الأصول', data.totalAssets, Colors.green),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _equationElement('الخصوم', data.totalLiabilities, Colors.red),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _equationElement('حقوق الملكية', data.totalEquity, Colors.blue),
                  ],
                ),
              ),
              if (!isBalanced) ...[
                const SizedBox(height: 8),
                Text(
                  'الفرق: ${_formatCurrency(data.difference)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _equationElement(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          _numberFormat.format(value),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required IconData icon,
    required List<_SubSection> subsections,
    required double grandTotal,
    required String grandTotalLabel,
    bool showNetIncome = false,
    double netIncome = 0,
    double retainedEarnings = 0,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),

          // Subsections
          ...subsections.map((sub) => _buildSubsection(sub, color)),

          // Net Income (for Equity section)
          if (showNetIncome && netIncome != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.teal.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(netIncome >= 0 ? Icons.add_circle : Icons.remove_circle,
                          color: netIncome >= 0 ? Colors.teal : Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      const Text('صافي دخل الفترة الحالية',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(
                    _formatCurrency(netIncome),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: netIncome >= 0 ? Colors.teal : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

          // Grand Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(grandTotalLabel, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(_formatCurrency(grandTotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsection(_SubSection sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subsection Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: color.withOpacity(0.05),
          child: Text(sub.title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
        ),
        // Rows
        ...sub.rows.map((r) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text('${r.code} - ${r.name}', style: const TextStyle(fontSize: 13)),
              ),
              Text(_formatCurrency(r.displayAmount), style: const TextStyle(fontSize: 13)),
            ],
          ),
        )),
        // Subtotal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('مجموع ${sub.title}', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey[700])),
              Text(_formatCurrency(sub.total), style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey[700])),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildGrandTotalCard(String title, double value, Color color, {required bool isBalanced, required double assetsTotal}) {
    return Card(
      color: isBalanced ? Colors.purple[50] : Colors.red[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                Text(_formatCurrency(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              ],
            ),
            if (isBalanced)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text('= إجمالي الأصول (${_formatCurrency(assetsTotal)})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
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
    final startOfPeriod = (filter.startDate ?? DateTime(DateTime.now().year, 1, 1)).millisecondsSinceEpoch ~/ 1000;

    // 1. Fetch Permanent Accounts (Assets, Liabilities, Equity)
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

    // 2. Calculate Net Income for the PERIOD (not all time)
    // This ensures we only show current period's net income in equity
    // Retained earnings from prior periods should already be in Retained Earnings account
    final netIncomeResult = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as net_income
      FROM accounts a
      JOIN journal_entry_lines jel ON jel.account_id = a.id
      JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1
        AND je.is_posted = 1
        AND je.entry_date >= ?
        AND je.entry_date <= ?
        AND a.type IN (3, 4)
        AND COALESCE(je.reference_type, '') NOT IN ('opening_entry', 'opening_balance', 'closing')
      ''',
      [startOfPeriod, asOf],
    );
    
    final netIncome = (netIncomeResult.first['net_income'] as num?)?.toDouble() ?? 0.0;

    // 3. Calculate Retained Earnings (all prior periods net income)
    final retainedEarningsResult = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as retained
      FROM accounts a
      JOIN journal_entry_lines jel ON jel.account_id = a.id
      JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1
        AND je.is_posted = 1
        AND je.entry_date < ?
        AND a.type IN (3, 4)
        AND COALESCE(je.reference_type, '') NOT IN ('opening_entry', 'opening_balance', 'closing')
      ''',
      [startOfPeriod],
    );
    
    final retainedEarnings = (retainedEarningsResult.first['retained'] as num?)?.toDouble() ?? 0.0;

    // Classify accounts into subcategories
    final currentAssets = <_AccountBalanceRow>[];
    final fixedAssets = <_AccountBalanceRow>[];
    final otherAssets = <_AccountBalanceRow>[];
    final currentLiabilities = <_AccountBalanceRow>[];
    final longTermLiabilities = <_AccountBalanceRow>[];
    final equityRows = <_AccountBalanceRow>[];

    double totalCurrentAssets = 0;
    double totalFixedAssets = 0;
    double totalOtherAssets = 0;
    double totalCurrentLiabilities = 0;
    double totalLongTermLiabilities = 0;
    double totalEquityAccounts = 0;

    for (final m in balanceSheetAccounts) {
      final type = (m['account_type'] as int?) ?? 0;
      final net = (m['net'] as num?)?.toDouble() ?? 0.0;
      final code = (m['account_code'] as String?) ?? '';

      final row = _AccountBalanceRow(
        id: (m['account_id'] as int?) ?? 0,
        code: code,
        name: (m['account_name'] as String?) ?? '',
        type: type,
        net: net,
      );

      if (type == 0) {
        // Assets - classify by code pattern
        // 11x = Current Assets (Cash, Receivables, Inventory)
        // 12x = Fixed Assets (Property, Equipment)
        // 13x+ = Other Assets
        if (code.startsWith('11')) {
          currentAssets.add(row);
          totalCurrentAssets += row.displayAmount;
        } else if (code.startsWith('12')) {
          fixedAssets.add(row);
          totalFixedAssets += row.displayAmount;
        } else {
          otherAssets.add(row);
          totalOtherAssets += row.displayAmount;
        }
      } else if (type == 1) {
        // Liabilities - classify by code pattern
        // 21x = Current Liabilities (Payables, Short-term)
        // 22x+ = Long-term Liabilities
        if (code.startsWith('21')) {
          currentLiabilities.add(row);
          totalCurrentLiabilities += row.displayAmount;
        } else {
          longTermLiabilities.add(row);
          totalLongTermLiabilities += row.displayAmount;
        }
      } else if (type == 2) {
        // Equity
        equityRows.add(row);
        totalEquityAccounts += row.displayAmount;
      }
    }

    // Add Retained Earnings if exists and not already in accounts
    if (retainedEarnings.abs() > 0.01) {
      equityRows.add(_AccountBalanceRow(
        id: -2,
        code: 'RE',
        name: 'أرباح محتجزة (فترات سابقة)',
        type: 2,
        net: -retainedEarnings,
      ));
      totalEquityAccounts += retainedEarnings;
    }

    // Add Current Period Net Income
    if (netIncome.abs() > 0.01) {
      equityRows.add(_AccountBalanceRow(
        id: -1,
        code: 'NI',
        name: 'صافي دخل الفترة الحالية',
        type: 2,
        net: -netIncome,
      ));
      totalEquityAccounts += netIncome;
    }

    final totalAssets = totalCurrentAssets + totalFixedAssets + totalOtherAssets;
    final totalLiabilities = totalCurrentLiabilities + totalLongTermLiabilities;

    return _BalanceSheetResult(
      currentAssets: currentAssets,
      fixedAssets: fixedAssets,
      otherAssets: otherAssets,
      currentLiabilities: currentLiabilities,
      longTermLiabilities: longTermLiabilities,
      equityRows: equityRows,
      totalCurrentAssets: totalCurrentAssets,
      totalFixedAssets: totalFixedAssets,
      totalOtherAssets: totalOtherAssets,
      totalCurrentLiabilities: totalCurrentLiabilities,
      totalLongTermLiabilities: totalLongTermLiabilities,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalEquity: totalEquityAccounts,
      netIncome: netIncome,
      retainedEarnings: retainedEarnings,
    );
  }
}

class _SubSection {
  final String title;
  final List<_AccountBalanceRow> rows;
  final double total;

  const _SubSection({
    required this.title,
    required this.rows,
    required this.total,
  });
}

class _BalanceSheetResult {
  final List<_AccountBalanceRow> currentAssets;
  final List<_AccountBalanceRow> fixedAssets;
  final List<_AccountBalanceRow> otherAssets;
  final List<_AccountBalanceRow> currentLiabilities;
  final List<_AccountBalanceRow> longTermLiabilities;
  final List<_AccountBalanceRow> equityRows;
  
  final double totalCurrentAssets;
  final double totalFixedAssets;
  final double totalOtherAssets;
  final double totalCurrentLiabilities;
  final double totalLongTermLiabilities;
  
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double netIncome;
  final double retainedEarnings;

  const _BalanceSheetResult({
    required this.currentAssets,
    required this.fixedAssets,
    required this.otherAssets,
    required this.currentLiabilities,
    required this.longTermLiabilities,
    required this.equityRows,
    required this.totalCurrentAssets,
    required this.totalFixedAssets,
    required this.totalOtherAssets,
    required this.totalCurrentLiabilities,
    required this.totalLongTermLiabilities,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.netIncome,
    required this.retainedEarnings,
  });

  /// Difference for balance check: Assets - (Liabilities + Equity)
  /// Should be 0 if balanced
  double get difference => totalAssets - (totalLiabilities + totalEquity);

  /// Check if balance sheet is balanced
  bool get isBalanced => difference.abs() < 0.01;

  /// Working Capital = Current Assets - Current Liabilities
  double get workingCapital => totalCurrentAssets - totalCurrentLiabilities;

  /// Current Ratio = Current Assets / Current Liabilities
  double get currentRatio => totalCurrentLiabilities > 0 ? totalCurrentAssets / totalCurrentLiabilities : 0;

  /// Debt to Equity Ratio
  double get debtToEquityRatio => totalEquity > 0 ? totalLiabilities / totalEquity : 0;
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

  /// Display amount with correct sign for each account type
  /// Assets (Debit Normal): positive net = positive display
  /// Liabilities & Equity (Credit Normal): negative net = positive display
  double get displayAmount {
    if (type == 1 || type == 2) return -net;
    return net;
  }
}
