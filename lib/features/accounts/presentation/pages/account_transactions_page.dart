import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/helpers/get_it.dart';

class AccountTransactionsPage extends StatefulWidget {
  final AccountEntity account;
  
  const AccountTransactionsPage({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  State<AccountTransactionsPage> createState() => _AccountTransactionsPageState();
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
      
      // First, try to get transactions from journal_entries
      final journalEntries = await db.rawQuery('''
        SELECT 
          je.id,
          je.number as entry_number,
          je.date,
          je.description,
          jel.debit_amount,
          jel.credit_amount,
          jel.notes,
          'journal' as source_type
        FROM journal_entry_lines jel
        JOIN journal_entries je ON je.id = jel.journal_entry_id
        WHERE jel.account_id = ?
        ${selectedPeriod != 'الكل' ? 'AND je.date >= ? AND je.date <= ?' : ''}
        ORDER BY je.date DESC, je.id DESC
      ''', whereArgs);
      
      // Get transactions from invoices (sales/purchases)
      final invoiceTransactions = await db.rawQuery('''
        SELECT 
          i.id,
          i.number as entry_number,
          i.date,
          CASE 
            WHEN i.invoice_type = 1 THEN 'فاتورة مبيعات'
            WHEN i.invoice_type = 2 THEN 'فاتورة مشتريات'
            WHEN i.invoice_type = 3 THEN 'عرض سعر'
            WHEN i.invoice_type = 4 THEN 'مرتجع مبيعات'
            WHEN i.invoice_type = 5 THEN 'مرتجع مشتريات'
            ELSE 'فاتورة'
          END as description,
          CASE 
            WHEN i.invoice_type IN (1, 4) THEN 0.0
            ELSE i.final_amt
          END as debit_amount,
          CASE 
            WHEN i.invoice_type IN (1, 4) THEN i.final_amt
            ELSE 0.0
          END as credit_amount,
          i.statement as notes,
          'invoice' as source_type
        FROM invoices i
        WHERE i.customer_id IN (
          SELECT id FROM customers WHERE account_id = ?
        )
        ${selectedPeriod != 'الكل' ? 'AND i.date >= ? AND i.date <= ?' : ''}
        ORDER BY i.date DESC, i.id DESC
      ''', whereArgs);
      
      // Get voucher transactions
      final voucherTransactions = await db.rawQuery('''
        SELECT 
          v.id,
          v.number as entry_number,
          v.date,
          CASE 
            WHEN v.voucher_type = 1 THEN 'سند قبض'
            WHEN v.voucher_type = 2 THEN 'سند صرف'
            WHEN v.voucher_type = 3 THEN 'سند يومية'
            ELSE 'سند'
          END as description,
          CASE 
            WHEN v.voucher_type = 2 THEN v.amount
            ELSE 0.0
          END as debit_amount,
          CASE 
            WHEN v.voucher_type = 1 THEN v.amount
            ELSE 0.0
          END as credit_amount,
          v.statement as notes,
          'voucher' as source_type
        FROM vouchers v
        WHERE (v.from_account_id = ? OR v.to_account_id = ?)
        ${selectedPeriod != 'الكل' ? 'AND v.date >= ? AND v.date <= ?' : ''}
        ORDER BY v.date DESC, v.id DESC
      ''', [...whereArgs, widget.account.id]);
      
      // Combine all transactions
      final allTransactions = [
        ...journalEntries,
        ...invoiceTransactions,
        ...voucherTransactions,
      ];
      
      // Sort by date
      allTransactions.sort((a, b) {
        final dateA = a['date'] as int;
        final dateB = b['date'] as int;
        return dateB.compareTo(dateA);
      });
      
      // Calculate totals and running balance
      double runningBalance = widget.account.balance;
      totalDebit = 0.0;
      totalCredit = 0.0;
      
      for (var transaction in allTransactions) {
        final debit = (transaction['debit_amount'] ?? 0.0) as double;
        final credit = (transaction['credit_amount'] ?? 0.0) as double;
        
        totalDebit += debit;
        totalCredit += credit;
        runningBalance += debit - credit;
        
        transaction['balance'] = runningBalance;
      }
      
      currentBalance = runningBalance;
      
      setState(() {
        transactions = allTransactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الحركات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.account.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'كود: ${widget.account.code}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'من: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
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
    final date = DateTime.fromMillisecondsSinceEpoch((transaction['date'] as int) * 1000);
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
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
                      credit > 0 ? NumberFormat('#,##0.00').format(credit) : '-',
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              if (transaction['notes'] != null && transaction['notes'].toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final date = DateTime.fromMillisecondsSinceEpoch((transaction['date'] as int) * 1000);
        
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
              _buildDetailRow('الرقم', transaction['entry_number']?.toString() ?? '-'),
              _buildDetailRow('التاريخ', DateFormat('yyyy-MM-dd').format(date)),
              _buildDetailRow(
                'مدين',
                NumberFormat('#,##0.00').format(transaction['debit_amount'] ?? 0.0),
                valueColor: Colors.red,
              ),
              _buildDetailRow(
                'دائن',
                NumberFormat('#,##0.00').format(transaction['credit_amount'] ?? 0.0),
                valueColor: Colors.green,
              ),
              _buildDetailRow(
                'الرصيد',
                NumberFormat('#,##0.00').format(transaction['balance'] ?? 0.0),
                valueColor: Colors.blue,
              ),
              if (transaction['notes'] != null && transaction['notes'].toString().isNotEmpty)
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
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
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
