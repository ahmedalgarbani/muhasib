import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_transactions_widgets.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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

      List<dynamic> whereArgs = [widget.account.id];

      if (selectedPeriod != 'الكل') {
        whereArgs.add(startDate.millisecondsSinceEpoch ~/ 1000);
        whereArgs.add(endDate.millisecondsSinceEpoch ~/ 1000);
      }

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

      final allTransactions = journalEntries
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();

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

  void _handlePeriodSelect(String label) {
    setState(() {
      selectedPeriod = label;

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
              AccountDetailRowWidget(
                label: 'النوع',
                value: transaction['description'] ?? '',
              ),
              AccountDetailRowWidget(
                label: 'الرقم',
                value: transaction['entry_number']?.toString() ?? '-',
              ),
              AccountDetailRowWidget(
                label: 'التاريخ',
                value: DateFormatter.formatDate(date),
              ),
              AccountDetailRowWidget(
                label: 'مدين',
                value: NumberFormatter.formatNumber(
                  transaction['debit_amount'] ?? 0.0,
                ),
                valueColor: Colors.red,
              ),
              AccountDetailRowWidget(
                label: 'دائن',
                value: NumberFormatter.formatNumber(
                  transaction['credit_amount'] ?? 0.0,
                ),
                valueColor: Colors.green,
              ),
              AccountDetailRowWidget(
                label: 'الرصيد',
                value: NumberFormatter.formatNumber(
                  transaction['balance'] ?? 0.0,
                ),
                valueColor: Colors.blue,
              ),
              if (transaction['notes'] != null &&
                  transaction['notes'].toString().isNotEmpty)
                AccountDetailRowWidget(
                  label: 'ملاحظات',
                  value: transaction['notes'],
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: '${widget.account.name} - كود: ${widget.account.code}',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: AppConstant.defaultPadding,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AccountPeriodOptionWidget(
                      label: 'الكل',
                      isSelected: selectedPeriod == 'الكل',
                      onTap: () => _handlePeriodSelect('الكل'),
                    ),
                    AccountPeriodOptionWidget(
                      label: 'يومي',
                      isSelected: selectedPeriod == 'يومي',
                      onTap: () => _handlePeriodSelect('يومي'),
                    ),
                    AccountPeriodOptionWidget(
                      label: 'شهري',
                      isSelected: selectedPeriod == 'شهري',
                      onTap: () => _handlePeriodSelect('شهري'),
                    ),
                    AccountPeriodOptionWidget(
                      label: 'سنوي',
                      isSelected: selectedPeriod == 'سنوي',
                      onTap: () => _handlePeriodSelect('سنوي'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
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
                              'من: ${DateFormatter.formatDate(startDate)}',
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
                              'إلى: ${DateFormatter.formatDate(endDate)}',
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
            color: Theme.of(context).colorScheme.surface,
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
                      return AccountTransactionItemWidget(
                        transaction: transaction,
                        onTap: _showTransactionDetails,
                      );
                    },
                  ),
          ),
        ],
      ),

      // Bottom Summary
      bottomSheet: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: AppConstant.defaultPadding,
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
                          NumberFormatter.formatNumber(totalDebit),
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
                          NumberFormatter.formatNumber(totalCredit),
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
                  NumberFormatter.formatNumber(currentBalance),
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
}
