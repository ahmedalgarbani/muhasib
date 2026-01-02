import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:intl/intl.dart';

class TrialBalanceReportPage extends StatelessWidget {
  const TrialBalanceReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrialBalanceCubit>()..loadTrialBalance(),
      child: ReportBasePage(
        title: 'ميزان المراجعة',
        icon: Icons.balance,
        color: const Color(0xFF1976D2),
        reportBuilder: (filter) => _TrialBalanceContent(filter: filter),
      ),
    );
  }
}

class _TrialBalanceContent extends StatefulWidget {
  final ReportFilter filter;

  const _TrialBalanceContent({required this.filter});

  @override
  State<_TrialBalanceContent> createState() => _TrialBalanceContentState();
}

class _TrialBalanceContentState extends State<_TrialBalanceContent> {
  final _numberFormat = NumberFormat('#,##0.00', 'ar');
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrialBalanceCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_TrialBalanceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      context.read<TrialBalanceCubit>().updateDateRange(widget.filter);
    }
  }

  String _formatCurrency(double value) {
    if (value == 0) return '-';
    return _numberFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
      builder: (context, state) {
        if (state is TrialBalanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TrialBalanceError) {
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
                    context.read<TrialBalanceCubit>().refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is TrialBalanceLoaded) {
          final accounts = state.accounts;
          final summary = state.summary;

          if (accounts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد حركات في الفترة المحددة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary cards - Enhanced with 3 sections
              _buildSummarySection(summary),

              // Table with enhanced columns
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      // Header
                      _buildTableHeader(),

                      // Rows
                      Expanded(
                        child: ListView.builder(
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return _buildAccountRow(account, index);
                          },
                        ),
                      ),

                      // Totals
                      _buildTotalsRow(summary),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }

  Widget _buildSummarySection(TrialBalanceSummary summary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Opening Balance
          _buildSummaryCard(
            'الرصيد الافتتاحي',
            Icons.account_balance_wallet,
            Colors.orange,
            summary.openingDebit,
            summary.openingCredit,
            summary.openingDifference,
          ),
          // Period Movements
          _buildSummaryCard(
            'حركات الفترة',
            Icons.swap_horiz,
            Colors.blue,
            summary.periodDebit,
            summary.periodCredit,
            summary.periodDifference,
          ),
          // Closing Balance
          _buildSummaryCard(
            'الرصيد الختامي',
            Icons.account_balance,
            summary.isClosingBalanced ? Colors.green : Colors.red,
            summary.closingDebit,
            summary.closingCredit,
            summary.closingDifference,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title, 
    IconData icon, 
    Color color,
    double debit,
    double credit,
    double difference,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('مدين:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                _formatCurrency(debit),
                style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('دائن:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                _formatCurrency(credit),
                style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الفرق:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(
                _formatCurrency(difference.abs()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: difference.abs() < 0.01 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Main header row
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('')), // Account info placeholder
                _buildHeaderGroup('الرصيد الافتتاحي', Colors.orange[100]!),
                _buildHeaderGroup('حركات الفترة', Colors.blue[100]!),
                _buildHeaderGroup('الرصيد الختامي', Colors.green[100]!),
              ],
            ),
          ),
          // Sub-header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[800],
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 1, 
                  child: Text('الكود', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  flex: 2, 
                  child: Text('اسم الحساب', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                // Opening
                _buildSubHeaderCell('مدين', Colors.orange[200]!),
                _buildSubHeaderCell('دائن', Colors.orange[200]!),
                // Period
                _buildSubHeaderCell('مدين', Colors.blue[200]!),
                _buildSubHeaderCell('دائن', Colors.blue[200]!),
                // Closing
                _buildSubHeaderCell('مدين', Colors.green[200]!),
                _buildSubHeaderCell('دائن', Colors.green[200]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGroup(String title, Color color) {
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeaderCell(String title, Color color) {
    return Expanded(
      flex: 1,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAccountRow(TrialBalanceEntity account, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey[50] : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Account Code
          Expanded(
            flex: 1,
            child: Text(
              account.accountCode,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
          // Account Name
          Expanded(
            flex: 2,
            child: Text(
              account.accountName,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Opening Debit
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(account.openingDebit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: account.openingDebit > 0 ? Colors.orange[700] : Colors.grey,
              ),
            ),
          ),
          // Opening Credit
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(account.openingCredit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: account.openingCredit > 0 ? Colors.orange[700] : Colors.grey,
              ),
            ),
          ),
          // Period Debit
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(account.periodDebit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: account.periodDebit > 0 ? Colors.blue : Colors.grey,
              ),
            ),
          ),
          // Period Credit
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(account.periodCredit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: account.periodCredit > 0 ? Colors.blue : Colors.grey,
              ),
            ),
          ),
          // Closing Debit
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(account.closingDebit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: account.closingDebit > 0 ? Colors.green[700] : Colors.grey,
              ),
            ),
          ),
          // Closing Credit
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(account.closingCredit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: account.closingCredit > 0 ? Colors.green[700] : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(TrialBalanceSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'المجموع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          // Opening totals
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(summary.openingDebit),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange[800]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(summary.openingCredit),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange[800]),
            ),
          ),
          // Period totals
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(summary.periodDebit),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blue),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(summary.periodCredit),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blue),
            ),
          ),
          // Closing totals
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(summary.closingDebit),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green[700]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatCurrency(summary.closingCredit),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green[700]),
            ),
          ),
        ],
      ),
    );
  }
}
