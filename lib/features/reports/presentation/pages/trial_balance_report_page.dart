import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

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
    final headers = ['الحساب', 'افتاحي م', 'افتتاحي د', 'حركة م', 'حركة د', 'ختامي م', 'ختامي د'];
    final data = _lastState!.accounts.map((a) => [
      '${a.accountCode} - ${a.accountName}',
      a.openingDebit.toStringAsFixed(2),
      a.openingCredit.toStringAsFixed(2),
      a.periodDebit.toStringAsFixed(2),
      a.periodCredit.toStringAsFixed(2),
      a.closingDebit.toStringAsFixed(2),
      a.closingCredit.toStringAsFixed(2),
    ]).toList();

    await ExportService.printData(title: 'ميزان المراجعة', headers: headers, data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastState == null) return;
    final headers = ['كود الحساب', 'اسم الحساب', 'افتتاحي مدين', 'افتتاحي دائن', 'حركات مدين', 'حركات دائن', 'ختامي مدين', 'ختامي دائن'];
    final data = _lastState!.accounts.map((a) => [
      a.accountCode, a.accountName, a.openingDebit.toStringAsFixed(2), a.openingCredit.toStringAsFixed(2), a.periodDebit.toStringAsFixed(2), a.periodCredit.toStringAsFixed(2), a.closingDebit.toStringAsFixed(2), a.closingCredit.toStringAsFixed(2),
    ]).toList();

    final path = await ExportService.exportToExcel(fileName: 'trial_balance', headers: headers, data: data);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تصدير Excel بنجاح: $path')));
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
    if (oldWidget.filter != widget.filter) context.read<TrialBalanceCubit>().updateDateRange(widget.filter);
  }

  String _format(double v) => v == 0 ? '-' : _numberFormat.format(v);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
      builder: (context, state) {
        if (state is TrialBalanceLoading) return const Center(child: CircularProgressIndicator());
        if (state is TrialBalanceError) return Center(child: Text('خطأ: ${state.message}', style: const TextStyle(color: Colors.red)));
        if (state is TrialBalanceLoaded) {
          final accounts = state.accounts;
          if (accounts.isEmpty) return const Center(child: Text('لا توجد بيانات للفترة المحددة'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummary(state.summary),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: Colors.grey[200]!)),
                  child: Column(
                    children: [
                      _buildHeader(),
                      ...accounts.map((a) => _buildRow(a)),
                      _buildFooter(state.summary),
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

  Widget _buildSummary(TrialBalanceSummary s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Colors.blue.withOpacity(0.1))),
      child: Row(children: [
        _miniItem('الافتتاحي', s.openingDifference, s.openingDifference.abs() < 0.01),
        const Spacer(),
        _miniItem('الفترة', s.periodDifference, s.periodDifference.abs() < 0.01),
        const Spacer(),
        _miniItem('الختامي', s.closingDifference, s.closingDifference.abs() < 0.01),
      ]),
    );
  }

  Widget _miniItem(String l, double v, bool balanced) {
    return Column(children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)), Text(balanced ? 'متوازن ✓' : 'فرق: ${v.abs().toStringAsFixed(1)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: balanced ? Colors.green : Colors.red))]);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      child: const Row(children: [
        Expanded(flex: 3, child: Text('الحساب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text('بداية الفترة', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text('الحركات', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text('الرصيد النهائي', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildRow(TrialBalanceEntity a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(children: [
            Expanded(flex: 3, child: Text('${a.accountCode} - ${a.accountName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            Expanded(flex: 2, child: _dualValue(a.openingDebit, a.openingCredit)),
            Expanded(flex: 2, child: _dualValue(a.periodDebit, a.periodCredit)),
            Expanded(flex: 2, child: _dualValue(a.closingDebit, a.closingCredit)),
          ]),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _dualValue(double d, double c) {
    return Column(children: [
      Text(_format(d), style: TextStyle(fontSize: 11, color: d > 0 ? Colors.blue : Colors.grey)),
      Text(_format(c), style: TextStyle(fontSize: 11, color: c > 0 ? Colors.green : Colors.grey)),
    ]);
  }

  Widget _buildFooter(TrialBalanceSummary s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg))),
      child: Row(children: [
        const Expanded(flex: 3, child: Text('الإجمالي العام', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: _dualValue(s.openingDebit, s.openingCredit)),
        Expanded(flex: 2, child: _dualValue(s.periodDebit, s.periodCredit)),
        Expanded(flex: 2, child: _dualValue(s.closingDebit, s.closingCredit)),
      ]),
    );
  }
}
