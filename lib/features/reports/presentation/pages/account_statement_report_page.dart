import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class AccountStatementReportPage extends StatefulWidget {
  const AccountStatementReportPage({super.key});

  @override
  State<AccountStatementReportPage> createState() =>
      _AccountStatementReportPageState();
}

class _AccountStatementReportPageState
    extends State<AccountStatementReportPage> {
  AccountStatementLoaded? _lastState;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AccountStatementCubit>()..loadAccounts(),
      child: BlocConsumer<AccountStatementCubit, AccountStatementState>(
        listener: (context, state) {
          if (state is AccountStatementLoaded) {
            setState(() => _lastState = state);
          }
        },
        builder: (context, state) {
          return ReportBasePage(
            title: 'كشف حساب تفصيلي',
            icon: Icons.account_balance_wallet,
            color: AppColors.materialDeepOrange900,
            onPrint: _lastState == null || _lastState!.transactions.isEmpty
                ? null
                : () => _exportPdf(context),
            onExportExcel:
                _lastState == null || _lastState!.transactions.isEmpty
                ? null
                : () => _exportExcel(context),
            additionalFilters: [_buildAccountSelector(context, state)],
            reportBuilder: (filter) => _AccountStatementContent(filter: filter),
          );
        },
      ),
    );
  }

  Widget _buildAccountSelector(
    BuildContext context,
    AccountStatementState state,
  ) {
    if (state is AccountStatementLoaded) {
      return Container(
        padding: const EdgeInsets.only(bottom: 16),
        child: CustomDropdownField<int>(
          label: 'اختر الحساب المطلوب',
          value: state.selectedAccountId,
          prefixIcon: const Icon(Icons.account_tree),
          items: state.accounts
              .map(
                (a) => DropdownMenuItem<int>(
                  value: a['id'] as int,
                  child: Text(
                    '${a['code']} - ${a['name']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => v != null
              ? context.read<AccountStatementCubit>().selectAccount(v)
              : null,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (_lastState == null) return;

    final headers = ['التاريخ', 'البيان', 'المرجع', 'مدين', 'دائن', 'الرصيد'];
    final data = _lastState!.transactions
        .map(
          (t) => [
            '${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
            t.description,
            t.reference,
            t.debitAmount.toStringAsFixed(2),
            t.creditAmount.toStringAsFixed(2),
            t.balance.toStringAsFixed(2),
          ],
        )
        .toList();

    final summary = _lastState!.summary;
    final settings = {
      'رصيد أول الفترة': summary.openingBalance.toStringAsFixed(2),
      'إجمالي المدين': summary.totalDebits.toStringAsFixed(2),
      'إجمالي الدائن': summary.totalCredits.toStringAsFixed(2),
      'رصيد آخر الفترة': summary.closingBalance.toStringAsFixed(2),
    };

    await ExportService.printData(
      title:
          'كشف حساب: ${_lastState!.accounts.firstWhere((a) => a['id'] == _lastState!.selectedAccountId)['name']}',
      headers: headers,
      data: data,
      settings: settings,
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    if (_lastState == null) return;

    final headers = ['التاريخ', 'البيان', 'المرجع', 'مدين', 'دائن', 'الرصيد'];
    final data = _lastState!.transactions
        .map(
          (t) => [
            '${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
            t.description,
            t.reference,
            t.debitAmount.toStringAsFixed(2),
            t.creditAmount.toStringAsFixed(2),
            t.balance.toStringAsFixed(2),
          ],
        )
        .toList();

    final path = await ExportService.exportToExcel(
      fileName: 'account_statement_${_lastState!.selectedAccountId}',
      headers: headers,
      data: data,
    );

    AppToast.showSuccess(context, 'تم تصدير ملف Excel بنجاح: $path');
  }
}

class _AccountStatementContent extends StatefulWidget {
  final ReportFilter filter;
  const _AccountStatementContent({required this.filter});
  @override
  State<_AccountStatementContent> createState() =>
      _AccountStatementContentState();
}

class _AccountStatementContentState extends State<_AccountStatementContent> {
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountStatementCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_AccountStatementContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      context.read<AccountStatementCubit>().updateDateRange(widget.filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountStatementCubit, AccountStatementState>(
      builder: (context, state) {
        if (state is AccountStatementLoading)
          return const Center(child: CircularProgressIndicator());
        if (state is AccountStatementError)
          return Center(
            child: Text(
              'خطأ: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        if (state is AccountStatementLoaded) {
          var transactions = state.transactions;
          if (widget.filter.searchQuery != null &&
              widget.filter.searchQuery!.isNotEmpty) {
            final q = widget.filter.searchQuery!.toLowerCase();
            transactions = transactions.where((t) {
              return t.description.toLowerCase().contains(q) ||
                  t.reference.toLowerCase().contains(q);
            }).toList();
          }

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد حركات مسجلة للحساب أو البحث المختار',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final summary = state.summary;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ReportKpiCard(
                        title: 'رصيد أول الفترة',
                        value:
                            '${_numberFormat.format(summary.openingBalance)} ر.س',
                        icon: Icons.history,
                        color: Colors.blue[700]!,
                        subtitle: 'الافتتاحي المنقول',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportKpiCard(
                        title: 'إجمالي الحركات المدينة',
                        value:
                            '${_numberFormat.format(summary.totalDebits)} ر.س',
                        icon: Icons.arrow_upward,
                        color: Colors.green[700]!,
                        subtitle: 'مقبوضات / مدين',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportKpiCard(
                        title: 'إجمالي الحركات الدائنة',
                        value:
                            '${_numberFormat.format(summary.totalCredits)} ر.س',
                        icon: Icons.arrow_downward,
                        color: Colors.red[700]!,
                        subtitle: 'مدفوعات / دائن',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportKpiCard(
                        title: 'الرصيد الختامي الصافي',
                        value:
                            '${_numberFormat.format(summary.closingBalance)} ر.س',
                        icon: Icons.account_balance_wallet,
                        color: Colors.purple[700]!,
                        subtitle: 'الرصيد المستحق الحالي',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) =>
                      _buildTransactionCard(transactions[index]),
                ),
              ),
            ],
          );
        }
        return const Center(child: Text('يرجى اختيار حساب لعرض الكشف'));
      },
    );
  }

  Widget _buildSummaryArea(dynamic summary) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSummaryItem(
            'رصيد افتتاحي',
            summary.openingBalance,
            Colors.blue,
          ),
          _buildSummaryItem(
            'إجمالي مديونية',
            summary.totalDebits,
            Colors.green,
          ),
          _buildSummaryItem('إجمالي دائنية', summary.totalCredits, Colors.red),
          _buildSummaryItem(
            'الرصيد النهائي',
            summary.closingBalance,
            Colors.deepPurple,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color, {
    bool isBold = false,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              '${_numberFormat.format(value)} ر.س',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_numberFormat.format(t.balance)} ر.س',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.tag, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      t.reference,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAmountBadge(
                  'مدين: ${_numberFormat.format(t.debitAmount)}',
                  Colors.green,
                ),
                const SizedBox(width: 10),
                _buildAmountBadge(
                  'دائن: ${_numberFormat.format(t.creditAmount)}',
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
