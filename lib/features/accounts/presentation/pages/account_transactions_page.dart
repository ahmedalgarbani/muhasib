import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';

class AccountTransactionsPage extends StatefulWidget {
  final AccountEntity account;

  const AccountTransactionsPage({super.key, required this.account});

  @override
  State<AccountTransactionsPage> createState() =>
      _AccountTransactionsPageState();
}

class _AccountTransactionsPageState extends State<AccountTransactionsPage> {
  String selectedPeriod = 'الكل';
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  double totalDebit = 0.0;
  double totalCredit = 0.0;
  double currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);

    try {
      final databaseService = getIt<DatabaseService>();
      final db = await databaseService.database;

      // Build the query based on selected period
      List<dynamic> whereArgs = [widget.account.id];

      if (selectedPeriod != 'الكل') {
        whereArgs.add(startDate.millisecondsSinceEpoch ~/ 1000);
        whereArgs.add(endDate.millisecondsSinceEpoch ~/ 1000);
      }

      // Use the journal as the single source of truth (double-entry).
      final journalEntries = await db.rawQuery('''
        SELECT 
          je.id,
          je.number as entry_number,
          je.entry_date as date,
          je.description,
          jel.debit_amount,
          jel.credit_amount,
          jel.notes,
          'journal' as source_type
        FROM journal_entry_lines jel
        JOIN journal_entries je ON je.id = jel.journal_entry_id
        WHERE jel.account_id = ?
        ${selectedPeriod != 'الكل' ? 'AND je.entry_date >= ? AND je.entry_date <= ?' : ''}
        ORDER BY je.entry_date DESC, je.id DESC
      ''', whereArgs);

      final allTransactions = [...journalEntries];

      // Calculate totals and running balance (descending dates):
      // start from current balance and walk backwards.
      double runningBalance = widget.account.balance;
      totalDebit = 0.0;
      totalCredit = 0.0;

      for (final transaction in allTransactions) {
        final debit = (transaction['debit_amount'] as num?)?.toDouble() ?? 0.0;
        final credit =
            (transaction['credit_amount'] as num?)?.toDouble() ?? 0.0;

        totalDebit += debit;
        totalCredit += credit;
        transaction['balance'] = runningBalance;
        runningBalance -= (debit - credit);
      }

      currentBalance = widget.account.balance;

      setState(() {
        transactions = allTransactions;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        AppToast.showError(context, 'خطأ في تحميل الحركات: ${e.toString()}');
      }
    }
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      locale: const Locale('ar', 'SA'),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        selectedPeriod = 'مخصص';
      });
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: '${widget.account.name} - كود: ${widget.account.code}',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            onPressed: () {
              // TODO: Export to PDF
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Period Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPeriodOption('الكل'),
                    _buildPeriodOption('يومي'),
                    _buildPeriodOption('شهري'),
                    _buildPeriodOption('سنوي'),
                  ],
                ),
                const SizedBox(height: 12),
                // Date Range
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'من: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'إلى: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Table Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'البيان',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'مدين',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'دائن',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'الرصيد',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'التاريخ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد حركات في الفترة المحددة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
          ),
        ],
      ),

      // Bottom Summary
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'مدين',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          NumberFormat('#,##0.00').format(totalDebit),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'دائن',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          NumberFormat('#,##0.00').format(totalCredit),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الرصيد الحالي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  NumberFormat('#,##0.00').format(currentBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: currentBalance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(String label) {
    bool isSelected = selectedPeriod == label;
    return InkWell(
      onTap: () {
        setState(() {
          selectedPeriod = label;

          // Update date range based on selection
          final now = DateTime.now();
          switch (label) {
            case 'يومي':
              startDate = DateTime(now.year, now.month, now.day);
              endDate = now;
              break;
            case 'شهري':
              startDate = DateTime(now.year, now.month, 1);
              endDate = now;
              break;
            case 'سنوي':
              startDate = DateTime(now.year, 1, 1);
              endDate = now;
              break;
            case 'الكل':
              startDate = DateTime(2020, 1, 1);
              endDate = now;
              break;
          }
        });
        _loadTransactions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(AppRadius.lg20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      (transaction['date'] as int) * 1000,
    );
    final debit = (transaction['debit_amount'] ?? 0.0) as double;
    final credit = (transaction['credit_amount'] ?? 0.0) as double;
    final balance = (transaction['balance'] ?? 0.0) as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // Show transaction details
          _showTransactionDetails(transaction);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Description
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['description'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (transaction['entry_number'] != null)
                          Text(
                            'رقم: ${transaction['entry_number']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Debit
                  Expanded(
                    child: Text(
                      debit > 0 ? NumberFormat('#,##0.00').format(debit) : '-',
                      style: TextStyle(
                        color: debit > 0 ? Colors.red : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Credit
                  Expanded(
                    child: Text(
                      credit > 0
                          ? NumberFormat('#,##0.00').format(credit)
                          : '-',
                      style: TextStyle(
                        color: credit > 0 ? Colors.green : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Balance
                  Expanded(
                    child: Text(
                      NumberFormat('#,##0.00').format(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.blue : Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Date
                  Expanded(
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              if (transaction['notes'] != null &&
                  transaction['notes'].toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction['notes'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg20),
        ),
      ),
      builder: (context) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          (transaction['date'] as int) * 1000,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تفاصيل الحركة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('النوع', transaction['description'] ?? ''),
              _buildDetailRow(
                'الرقم',
                transaction['entry_number']?.toString() ?? '-',
              ),
              _buildDetailRow('التاريخ', DateFormat('yyyy-MM-dd').format(date)),
              _buildDetailRow(
                'مدين',
                NumberFormat(
                  '#,##0.00',
                ).format(transaction['debit_amount'] ?? 0.0),
                valueColor: Colors.red,
              ),
              _buildDetailRow(
                'دائن',
                NumberFormat(
                  '#,##0.00',
                ).format(transaction['credit_amount'] ?? 0.0),
                valueColor: Colors.green,
              ),
              _buildDetailRow(
                'الرصيد',
                NumberFormat('#,##0.00').format(transaction['balance'] ?? 0.0),
                valueColor: Colors.blue,
              ),
              if (transaction['notes'] != null &&
                  transaction['notes'].toString().isNotEmpty)
                _buildDetailRow('ملاحظات', transaction['notes']),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
