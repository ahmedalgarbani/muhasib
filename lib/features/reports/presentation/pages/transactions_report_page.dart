import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/data/models/transaction_model.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/transaction_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/transactions_report_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/transactions_report_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class TransactionsReportPage extends StatelessWidget {
  const TransactionsReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TransactionsReportCubit>()..loadTransactions(),
      child: ReportBasePage(
        title: 'تقرير الحركات',
        icon: Icons.sync_alt,
        color: const Color(0xFF2196F3),
        reportBuilder: (filter) => _TransactionsReportContent(filter: filter),
      ),
    );
  }
}

class _TransactionsReportContent extends StatefulWidget {
  final ReportFilter filter;

  const _TransactionsReportContent({required this.filter});

  @override
  State<_TransactionsReportContent> createState() =>
      _TransactionsReportContentState();
}

class _TransactionsReportContentState
    extends State<_TransactionsReportContent> {
  @override
  void initState() {
    super.initState();
    // Update filter when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsReportCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_TransactionsReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      context.read<TransactionsReportCubit>().updateDateRange(widget.filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsReportCubit, TransactionsReportState>(
      builder: (context, state) {
        if (state is TransactionsReportLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TransactionsReportError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'خطأ: ${state.message}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<TransactionsReportCubit>().loadTransactions();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is TransactionsReportLoaded) {
          return _buildLoadedContent(context, state);
        }

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    TransactionsReportLoaded state,
  ) {
    final cubit = context.read<TransactionsReportCubit>();
    final totalDebit = state.summary['totalDebit'] ?? 0.0;
    final totalCredit = state.summary['totalCredit'] ?? 0.0;
    final transactionCount = state.summary['count'] ?? 0;

    return Column(
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: ReportSummaryCard(
                title: 'إجمالي المدين',
                value: '${totalDebit.toStringAsFixed(2)} ر.س',
                icon: Icons.arrow_upward,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReportSummaryCard(
                title: 'إجمالي الدائن',
                value: '${totalCredit.toStringAsFixed(2)} ر.س',
                icon: Icons.arrow_downward,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReportSummaryCard(
                title: 'عدد الحركات',
                value: transactionCount.toString(),
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Filter and Sort Controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Type Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: state.selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع الحركة',
                      prefixIcon: Icon(Icons.filter_list),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'sales', child: Text('مبيعات')),
                      DropdownMenuItem(
                        value: 'purchase',
                        child: Text('مشتريات'),
                      ),
                      DropdownMenuItem(
                        value: 'journal',
                        child: Text('قيد يومية'),
                      ),
                      DropdownMenuItem(value: 'receipt', child: Text('قبض')),
                      DropdownMenuItem(value: 'payment', child: Text('صرف')),
                      DropdownMenuItem(
                        value: 'opening',
                        child: Text('افتتاحي'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        cubit.changeFilter(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Sort By
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: state.sortBy,
                    decoration: const InputDecoration(
                      labelText: 'ترتيب حسب',
                      prefixIcon: Icon(Icons.sort),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'date', child: Text('التاريخ')),
                      DropdownMenuItem(value: 'amount', child: Text('المبلغ')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        cubit.changeSort(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Sort Direction
                IconButton(
                  onPressed: () {
                    cubit.toggleSortDirection();
                  },
                  icon: Icon(
                    state.isAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  tooltip: state.isAscending ? 'تصاعدي' : 'تنازلي',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Transactions Table
        Expanded(
          child: Card(
            child: state.transactions.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد حركات مسجلة',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 40,
                        columns: const [
                          DataColumn(label: Text('الرقم المرجعي')),
                          DataColumn(label: Text('التاريخ')),
                          DataColumn(label: Text('الوصف')),
                          DataColumn(label: Text('الحساب المدين')),
                          DataColumn(label: Text('الحساب الدائن')),
                          DataColumn(label: Text('المبلغ'), numeric: true),
                          DataColumn(label: Text('النوع')),
                        ],
                        rows: state.transactions.map((transaction) {
                          // Get first debit and credit entries
                          final debitEntry = transaction.details.firstWhere(
                            (d) => d.debitAmount > 0,
                            orElse: () => transaction.details.isNotEmpty
                                ? transaction.details.first
                                : const TransactionDetailModel(
                                    id: 0,
                                    accountId: 0,
                                    accountName: '',
                                    accountCode: '',
                                    debitAmount: 0,
                                    creditAmount: 0,
                                  ),
                          );
                          final creditEntry = transaction.details.firstWhere(
                            (d) => d.creditAmount > 0,
                            orElse: () => transaction.details.isNotEmpty
                                ? transaction.details.first
                                : const TransactionDetailModel(
                                    id: 0,
                                    accountId: 0,
                                    accountName: '',
                                    accountCode: '',
                                    debitAmount: 0,
                                    creditAmount: 0,
                                  ),
                          );

                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(
                                      transaction.transactionType,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    transaction.reference,
                                    style: TextStyle(
                                      color: _getTypeColor(
                                        transaction.transactionType,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatDate(transaction.date),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  transaction.description,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      debitEntry.accountName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Icon(
                                      Icons.remove_circle_outline,
                                      size: 16,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      creditEntry.accountName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${transaction.totalAmount.toStringAsFixed(2)} ر.س',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(
                                    _getTypeLabel(transaction.transactionType),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: _getTypeColor(
                                    transaction.transactionType,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ),

        // Export Buttons
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                cubit.exportToPdf();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري التصدير إلى PDF...')),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('تصدير PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                cubit.exportToExcel();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري التصدير إلى Excel...')),
                );
              },
              icon: const Icon(Icons.table_chart),
              label: const Text('تصدير Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                cubit.printReport();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري الطباعة...')),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'sales':
        return Colors.green;
      case 'purchase':
        return Colors.purple;
      case 'journal':
        return Colors.blue;
      case 'receipt':
        return Colors.teal;
      case 'payment':
        return Colors.orange;
      case 'opening':
        return Colors.indigo;
      case 'salesReturn':
        return Colors.redAccent;
      case 'purchaseReturn':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sales':
        return 'مبيعات';
      case 'purchase':
        return 'مشتريات';
      case 'journal':
        return 'قيد يومية';
      case 'receipt':
        return 'قبض';
      case 'payment':
        return 'صرف';
      case 'opening':
        return 'افتتاحي';
      case 'salesReturn':
        return 'مردود مبيعات';
      case 'purchaseReturn':
        return 'مردود مشتريات';
      default:
        return 'أخرى';
    }
  }
}
