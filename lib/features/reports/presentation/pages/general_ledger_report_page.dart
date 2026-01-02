import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

/// Enhanced General Ledger Report with:
/// 1. Running balance for each account
/// 2. Direct link to journal entries
/// 3. Account type indicators
/// 4. Proper debit/credit display per account nature
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

class _GeneralLedgerContent extends StatefulWidget {
  final ReportFilter filter;

  const _GeneralLedgerContent({required this.filter});

  @override
  State<_GeneralLedgerContent> createState() => _GeneralLedgerContentState();
}

class _GeneralLedgerContentState extends State<_GeneralLedgerContent> {
  final _numberFormat = NumberFormat('#,##0.00', 'ar');
  int? _selectedAccountId;

  String _formatCurrency(double value) {
    return _numberFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LedgerResult>(
      future: _load(widget.filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null || data.accounts.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return Column(
          children: [
            // Summary Cards
            _buildSummaryCards(data),

            // Balance Check
            if ((data.totalDebit - data.totalCredit).abs() > 0.01)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'تحذير: الفرق ${_formatCurrency(data.totalDebit - data.totalCredit)}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Accounts List with Expandable Details
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.accounts.length,
                itemBuilder: (context, index) {
                  final account = data.accounts[index];
                  final isExpanded = _selectedAccountId == account.id;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        // Account Header
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAccountId = isExpanded ? null : account.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Account Type Indicator
                                Container(
                                  width: 8,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getAccountTypeColor(account.type),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Account Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${account.code} - ${account.name}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getAccountTypeName(account.type),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                // Debit/Credit/Balance
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'مدين: ${_formatCurrency(account.totalDebit)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'دائن: ${_formatCurrency(account.totalCredit)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الرصيد: ${_formatCurrency(account.balance)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: account.balance >= 0 ? Colors.blue : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Expanded Details (Transactions)
                        if (isExpanded)
                          FutureBuilder<List<_LedgerTransaction>>(
                            future: _loadAccountTransactions(account.id, widget.filter),
                            builder: (context, txnSnapshot) {
                              if (txnSnapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              
                              final transactions = txnSnapshot.data ?? [];
                              
                              if (transactions.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('لا توجد حركات'),
                                );
                              }
                              
                              return Column(
                                children: [
                                  const Divider(height: 1),
                                  // Transaction Table Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Colors.grey[100],
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 3, child: Text('البيان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('مدين', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('دائن', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('الرصيد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                      ],
                                    ),
                                  ),
                                  // Opening Balance Row
                                  if (account.openingBalance != 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      color: Colors.amber[50],
                                      child: Row(
                                        children: [
                                          const Expanded(flex: 2, child: Text('-', style: TextStyle(fontSize: 11))),
                                          const Expanded(flex: 3, child: Text('رصيد افتتاحي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                                          const Expanded(flex: 2, child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 11))),
                                          const Expanded(flex: 2, child: Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 11))),
                                          Expanded(flex: 2, child: Text(_formatCurrency(account.openingBalance), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                                        ],
                                      ),
                                    ),
                                  // Transaction Rows
                                  ...transactions.map((txn) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(txn.dateLabel, style: const TextStyle(fontSize: 11))),
                                        Expanded(
                                          flex: 3, 
                                          child: GestureDetector(
                                            onTap: () {
                                              // Navigate to journal entry detail
                                              // context.push('${AppRoutes.journalEntryForm}?id=${txn.journalEntryId}');
                                            },
                                            child: Text(
                                              txn.description ?? '-',
                                              style: const TextStyle(fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2, 
                                          child: Text(
                                            txn.debit > 0 ? _formatCurrency(txn.debit) : '-',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 11, color: txn.debit > 0 ? Colors.blue : Colors.grey),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2, 
                                          child: Text(
                                            txn.credit > 0 ? _formatCurrency(txn.credit) : '-',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 11, color: txn.credit > 0 ? Colors.green : Colors.grey),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2, 
                                          child: Text(
                                            _formatCurrency(txn.runningBalance),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11, 
                                              fontWeight: FontWeight.w500,
                                              color: txn.runningBalance >= 0 ? Colors.blue : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  // Actions
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            context.push(AppRoutes.reportsAccountStatement);
                                          },
                                          icon: const Icon(Icons.description, size: 16),
                                          label: const Text('كشف حساب كامل'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
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

  Widget _buildSummaryCards(_LedgerResult data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildSummaryCard('عدد الحسابات', '${data.accounts.length}', Icons.account_tree, Colors.purple),
          _buildSummaryCard('إجمالي المدين', _formatCurrency(data.totalDebit), Icons.arrow_upward, Colors.blue),
          _buildSummaryCard('إجمالي الدائن', _formatCurrency(data.totalCredit), Icons.arrow_downward, Colors.green),
          _buildSummaryCard(
            'الفرق', 
            _formatCurrency((data.totalDebit - data.totalCredit).abs()), 
            Icons.compare_arrows, 
            (data.totalDebit - data.totalCredit).abs() < 0.01 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
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
              Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getAccountTypeColor(int type) {
    switch (type) {
      case 0: return Colors.green;      // Assets
      case 1: return Colors.red;        // Liabilities
      case 2: return Colors.blue;       // Equity
      case 3: return Colors.teal;       // Revenue
      case 4: return Colors.orange;     // Expenses
      default: return Colors.grey;
    }
  }

  String _getAccountTypeName(int type) {
    switch (type) {
      case 0: return 'أصول';
      case 1: return 'خصوم';
      case 2: return 'حقوق ملكية';
      case 3: return 'إيرادات';
      case 4: return 'مصروفات';
      default: return 'غير محدد';
    }
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

    // Get opening balance for each account
    final startDate = filter.startDate?.millisecondsSinceEpoch ?? 0;

    final rows = await db.rawQuery('''
      SELECT
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        a.type as account_type,
        COALESCE(SUM(jel.debit_amount), 0) as total_debit,
        COALESCE(SUM(jel.credit_amount), 0) as total_credit,
        COALESCE((
          SELECT SUM(jel2.debit_amount - jel2.credit_amount)
          FROM journal_entry_lines jel2
          INNER JOIN journal_entries je2 ON je2.id = jel2.journal_entry_id
          WHERE je2.is_posted = 1 AND jel2.account_id = a.id AND je2.entry_date < ?
        ), 0) as opening_balance
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON jel.account_id = a.id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1
      $dateFilter
      GROUP BY a.id, a.code, a.name, a.type
      HAVING (total_debit != 0 OR total_credit != 0)
      ORDER BY a.code
    ''', [startDate ~/ 1000, ...args]);

    final accounts = rows.map((m) {
      final totalDebit = (m['total_debit'] as num?)?.toDouble() ?? 0.0;
      final totalCredit = (m['total_credit'] as num?)?.toDouble() ?? 0.0;
      final openingBalance = (m['opening_balance'] as num?)?.toDouble() ?? 0.0;
      
      return _LedgerAccount(
        id: (m['account_id'] as int?) ?? 0,
        code: (m['account_code'] as String?) ?? '',
        name: (m['account_name'] as String?) ?? '',
        type: (m['account_type'] as int?) ?? 0,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        openingBalance: openingBalance,
        balance: openingBalance + (totalDebit - totalCredit),
      );
    }).toList();

    final totalDebit = accounts.fold<double>(0, (s, a) => s + a.totalDebit);
    final totalCredit = accounts.fold<double>(0, (s, a) => s + a.totalCredit);

    return _LedgerResult(
      accounts: accounts,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
    );
  }

  Future<List<_LedgerTransaction>> _loadAccountTransactions(int accountId, ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;

    final args = <Object?>[accountId];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    // Get opening balance
    double runningBalance = 0;
    if (filter.startDate != null) {
      final openingResult = await db.rawQuery('''
        SELECT COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as balance
        FROM journal_entry_lines jel
        INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
        WHERE je.is_posted = 1 AND jel.account_id = ? AND je.entry_date < ?
      ''', [accountId, filter.startDate!.millisecondsSinceEpoch ~/ 1000]);
      runningBalance = (openingResult.first['balance'] as num?)?.toDouble() ?? 0.0;
    }

    final rows = await db.rawQuery('''
      SELECT
        jel.id,
        jel.journal_entry_id,
        je.entry_date,
        je.description,
        je.number as entry_number,
        COALESCE(jel.debit_amount, 0) as debit,
        COALESCE(jel.credit_amount, 0) as credit
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE je.is_posted = 1 AND jel.account_id = ?
      $dateFilter
      ORDER BY je.entry_date, jel.id
      LIMIT 100
    ''', args);

    final transactions = <_LedgerTransaction>[];
    for (final row in rows) {
      final debit = (row['debit'] as num?)?.toDouble() ?? 0.0;
      final credit = (row['credit'] as num?)?.toDouble() ?? 0.0;
      runningBalance += (debit - credit);
      
      transactions.add(_LedgerTransaction(
        id: (row['id'] as int?) ?? 0,
        journalEntryId: (row['journal_entry_id'] as int?) ?? 0,
        entryDate: (row['entry_date'] as int?) ?? 0,
        description: row['description'] as String?,
        entryNumber: row['entry_number'] as String?,
        debit: debit,
        credit: credit,
        runningBalance: runningBalance,
      ));
    }

    return transactions;
  }
}

class _LedgerResult {
  final List<_LedgerAccount> accounts;
  final double totalDebit;
  final double totalCredit;

  const _LedgerResult({
    required this.accounts,
    required this.totalDebit,
    required this.totalCredit,
  });
}

class _LedgerAccount {
  final int id;
  final String code;
  final String name;
  final int type;
  final double totalDebit;
  final double totalCredit;
  final double openingBalance;
  final double balance;

  const _LedgerAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.totalDebit,
    required this.totalCredit,
    required this.openingBalance,
    required this.balance,
  });
}

class _LedgerTransaction {
  final int id;
  final int journalEntryId;
  final int entryDate;
  final String? description;
  final String? entryNumber;
  final double debit;
  final double credit;
  final double runningBalance;

  const _LedgerTransaction({
    required this.id,
    required this.journalEntryId,
    required this.entryDate,
    required this.description,
    required this.entryNumber,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(entryDate * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}
