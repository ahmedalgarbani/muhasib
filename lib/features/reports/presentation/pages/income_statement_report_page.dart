import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/income_statement_components.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class IncomeStatementReportPage extends StatefulWidget {
  const IncomeStatementReportPage({super.key});
  @override
  State<IncomeStatementReportPage> createState() =>
      _IncomeStatementReportPageState();
}

class _IncomeStatementReportPageState extends State<IncomeStatementReportPage> {
  IncomeStatementLoaded? _lastState;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<IncomeStatementCubit>()..loadIncomeStatement(ReportFilter.currentMonth()),
      child: BlocConsumer<IncomeStatementCubit, IncomeStatementState>(
        listener: (context, state) {
          if (state is IncomeStatementLoaded)
            setState(() => _lastState = state);
        },
        builder: (context, state) {
          return ReportBasePage(
            title: 'قائمة الدخل الشامل',
            icon: Icons.trending_up,
            color: AppColors.materialGreen800,
            onPrint: _lastState == null ? null : () => _exportPdf(context),
            onExportExcel: _lastState == null
                ? null
                : () => _exportExcel(context),
            reportBuilder: (filter) => _IncomeStatementContent(filter: filter),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (_lastState == null) return;
    final headers = ['البند', 'المبلغ'];
    final List<List<String>> data = [];
    for (var cat in _lastState!.categories) {
      data.add([cat.categoryName, '']);
      for (var item in cat.items) {
        data.add(['  ${item.accountName}', item.amount.toStringAsFixed(2)]);
      }
      data.add([
        'إجمالي ${cat.categoryName}',
        cat.totalAmount.toStringAsFixed(2),
      ]);
    }
    data.add([
      'صافي الربح/الخسارة',
      _lastState!.summary.netIncome.toStringAsFixed(2),
    ]);

    await ExportService.printData(
      title: 'قائمة الدخل',
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    if (_lastState == null) return;
    final headers = ['الفئة', 'الحساب', 'المبلغ'];
    final List<List<String>> data = [];
    for (var cat in _lastState!.categories) {
      for (var item in cat.items) {
        data.add([
          cat.categoryName,
          item.accountName,
          item.amount.toStringAsFixed(2),
        ]);
      }
    }
    final path = await ExportService.exportToExcel(
      fileName: 'income_statement',
      headers: headers,
      data: data,
    );
    AppToast.showSuccess(context, 'تم التصدير بنجاح: $path');
  }
}

class _IncomeStatementContent extends StatefulWidget {
  final ReportFilter filter;
  const _IncomeStatementContent({required this.filter});
  @override
  State<_IncomeStatementContent> createState() =>
      _IncomeStatementContentState();
}

class _IncomeStatementContentState extends State<_IncomeStatementContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeStatementCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_IncomeStatementContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter)
      context.read<IncomeStatementCubit>().updateDateRange(widget.filter);
  }

  String _formatCurrency(double v) =>
      NumberFormatter.formatCurrency(v, symbol: 'ر.س');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomeStatementCubit, IncomeStatementState>(
      builder: (context, state) {
        if (state is IncomeStatementLoading)
          return const Center(child: CircularProgressIndicator());
        if (state is IncomeStatementError)
          return Center(child: Text('خطأ: ${state.message}'));
        if (state is IncomeStatementLoaded) {
          final summary = state.summary;
          final categories = state.categories;
          if (categories.isEmpty)
            return const Center(child: Text('لا توجد بيانات للفترة المحددة'));

          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              children: [
                IncomeStatementSummaryRowWidget(
                  summary: summary,
                  formatCurrency: _formatCurrency,
                ),
                const SizedBox(height: 10),
                CustomCardContainer(
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg20),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      ...categories.map(
                        (cat) => IncomeStatementCategoryWidget(
                          category: cat,
                          formatCurrency: _formatCurrency,
                        ),
                      ),
                      IncomeStatementFinalResultWidget(
                        summary: summary,
                        formatCurrency: _formatCurrency,
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
