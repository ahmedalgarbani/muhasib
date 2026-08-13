import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/account_statement_widgets.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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
            additionalFilters: [
              if (state is AccountStatementLoaded)
                AccountStatementAccountSelectorWidget(
                  selectedAccountId: state.selectedAccountId,
                  accounts: state.accounts,
                  onAccountSelected: (id) {
                    context.read<AccountStatementCubit>().selectAccount(id);
                  },
                ),
            ],
            reportBuilder: (filter) => _AccountStatementContent(filter: filter),
          );
        },
      ),
    );
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
        if (state is AccountStatementLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AccountStatementError) {
          return Center(
            child: Text(
              'خطأ: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
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
                padding: AppConstant.defaultPadding,
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
                      AccountStatementTransactionCardWidget(
                    transaction: transactions[index],
                    numberFormat: _numberFormat,
                  ),
                ),
              ),
            ],
          );
        }
        return const Center(child: Text('يرجى اختيار حساب لعرض الكشف'));
      },
    );
  }
}
