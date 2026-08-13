import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_data_table.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class TrialBalanceReportPage extends StatefulWidget {
  const TrialBalanceReportPage({super.key});
  @override
  State<TrialBalanceReportPage> createState() => _TrialBalanceReportPageState();
}

class _TrialBalanceReportPageState extends State<TrialBalanceReportPage> {
  TrialBalanceLoaded? _lastState;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrialBalanceCubit>()..loadTrialBalance(),
      child: BlocConsumer<TrialBalanceCubit, TrialBalanceState>(
        listener: (context, state) {
          if (state is TrialBalanceLoaded) setState(() => _lastState = state);
        },
        builder: (context, state) {
          return ReportBasePage(
            title: 'ميزان المراجعة بالمجاميع والأرصدة',
            icon: Icons.balance,
            color: AppColors.materialBlue800,
            onPrint: _lastState == null ? null : () => _exportPdf(),
            onExportExcel: _lastState == null ? null : () => _exportExcel(),
            reportBuilder: (filter) => _TrialBalanceContent(filter: filter),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastState == null) return;
    final headers = [
      'الحساب',
      'افتاحي م',
      'افتتاحي د',
      'حركة م',
      'حركة د',
      'ختامي م',
      'ختامي د',
    ];
    final data = _lastState!.accounts
        .map(
          (a) => [
            '${a.accountCode} - ${a.accountName}',
            a.openingDebit.toStringAsFixed(2),
            a.openingCredit.toStringAsFixed(2),
            a.periodDebit.toStringAsFixed(2),
            a.periodCredit.toStringAsFixed(2),
            a.closingDebit.toStringAsFixed(2),
            a.closingCredit.toStringAsFixed(2),
          ],
        )
        .toList();

    await ExportService.printData(
      title: 'ميزان المراجعة',
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel() async {
    if (_lastState == null) return;
    final headers = [
      'كود الحساب',
      'اسم الحساب',
      'افتتاحي مدين',
      'افتتاحي دائن',
      'حركات مدين',
      'حركات دائن',
      'ختامي مدين',
      'ختامي دائن',
    ];
    final data = _lastState!.accounts
        .map(
          (a) => [
            a.accountCode,
            a.accountName,
            a.openingDebit.toStringAsFixed(2),
            a.openingCredit.toStringAsFixed(2),
            a.periodDebit.toStringAsFixed(2),
            a.periodCredit.toStringAsFixed(2),
            a.closingDebit.toStringAsFixed(2),
            a.closingCredit.toStringAsFixed(2),
          ],
        )
        .toList();

    final path = await ExportService.exportToExcel(
      fileName: 'trial_balance',
      headers: headers,
      data: data,
    );
    AppToast.showSuccess(context, 'تم تصدير Excel بنجاح: $path');
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

  String _format(double v) => v == 0 ? '-' : _numberFormat.format(v);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
      builder: (context, state) {
        if (state is TrialBalanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TrialBalanceError) {
          return Center(
            child: Text(
              'خطأ: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (state is TrialBalanceLoaded) {
          var accounts = state.accounts;
          if (widget.filter.searchQuery != null &&
              widget.filter.searchQuery!.isNotEmpty) {
            final query = widget.filter.searchQuery!.toLowerCase();
            accounts = accounts.where((a) {
              return a.accountCode.toLowerCase().contains(query) ||
                  a.accountName.toLowerCase().contains(query);
            }).toList();
          }

          final isClosingBalanced =
              state.summary.closingDifference.abs() < 0.01;

          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ReportKpiCard(
                        title: 'الرصيد الافتتاحي',
                        value:
                            '${state.summary.openingDebit.toStringAsFixed(0)} ر.س',
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue[700]!,
                        subtitle: state.summary.openingDifference.abs() < 0.01
                            ? 'متوازن ✓'
                            : 'فرق: ${state.summary.openingDifference.abs().toStringAsFixed(1)}',
                        isPositiveTrend:
                            state.summary.openingDifference.abs() < 0.01,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportKpiCard(
                        title: 'حركات الفترة',
                        value:
                            '${state.summary.periodDebit.toStringAsFixed(0)} ر.س',
                        icon: Icons.swap_vert,
                        color: Colors.purple[700]!,
                        subtitle: 'إجمالي مدين/دائن',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportKpiCard(
                        title: 'الرصيد الختامي',
                        value:
                            '${state.summary.closingDebit.toStringAsFixed(0)} ر.س',
                        icon: isClosingBalanced
                            ? Icons.check_circle
                            : Icons.warning,
                        color: isClosingBalanced
                            ? Colors.green[700]!
                            : Colors.red[700]!,
                        subtitle: isClosingBalanced
                            ? 'ميزان متوازن ✓'
                            : 'فرق: ${state.summary.closingDifference.abs().toStringAsFixed(1)} ⚠',
                        isPositiveTrend: isClosingBalanced,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ReportDataTable<TrialBalanceEntity>(
                  columns: const [
                    ReportTableColumn(title: 'رمز الحساب / الاسم', flex: 3),
                    ReportTableColumn(
                      title: 'بداية الفترة (مدين/دائن)',
                      flex: 2,
                      alignment: TextAlign.center,
                    ),
                    ReportTableColumn(
                      title: 'حركات الفترة (مدين/دائن)',
                      flex: 2,
                      alignment: TextAlign.center,
                    ),
                    ReportTableColumn(
                      title: 'الرصيد الختامي (مدين/دائن)',
                      flex: 2,
                      alignment: TextAlign.center,
                    ),
                  ],
                  items: accounts,
                  rowBuilder: (context, a, index) => Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.accountName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              a.accountCode,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DualValueDisplayWidget(
                          debit: a.openingDebit,
                          credit: a.openingCredit,
                          formatter: _format,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DualValueDisplayWidget(
                          debit: a.periodDebit,
                          credit: a.periodCredit,
                          formatter: _format,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DualValueDisplayWidget(
                          debit: a.closingDebit,
                          credit: a.closingCredit,
                          formatter: _format,
                        ),
                      ),
                    ],
                  ),
                  footerRow: Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'الإجمالي العام للميزان',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DualValueDisplayWidget(
                          debit: state.summary.openingDebit,
                          credit: state.summary.openingCredit,
                          formatter: _format,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DualValueDisplayWidget(
                          debit: state.summary.periodDebit,
                          credit: state.summary.periodCredit,
                          formatter: _format,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DualValueDisplayWidget(
                          debit: state.summary.closingDebit,
                          credit: state.summary.closingCredit,
                          formatter: _format,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class DualValueDisplayWidget extends StatelessWidget {
  final double debit;
  final double credit;
  final String Function(double) formatter;

  const DualValueDisplayWidget({
    super.key,
    required this.debit,
    required this.credit,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          formatter(debit),
          style: TextStyle(
            fontSize: 11,
            color: debit > 0 ? Colors.blue : Colors.grey,
          ),
        ),
        Text(
          formatter(credit),
          style: TextStyle(
            fontSize: 11,
            color: credit > 0 ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
