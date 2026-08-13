import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

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
      create: (context) => getIt<IncomeStatementCubit>()..loadIncomeStatement(),
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
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

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

  String _formatCurrency(double v) => '${_numberFormat.format(v)} ر.س';

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCards(summary),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg20),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      ...categories.map((cat) => _buildCategorySection(cat)),
                      _buildFinalNetIncome(summary),
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

  Widget _buildSummaryCards(IncomeStatementSummary s) {
    final totalExpenses = s.totalOperatingExpenses + s.totalCostOfSales;
    final isProfit = s.netIncome >= 0;
    final marginPercent = s.totalRevenue > 0
        ? (s.netIncome / s.totalRevenue * 100)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: ReportKpiCard(
            title: 'إجمالي الإيرادات',
            value: _formatCurrency(s.totalRevenue),
            icon: Icons.trending_up,
            color: Colors.green[700]!,
            subtitle: 'جميع دخل الفعالية',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ReportKpiCard(
            title: 'إجمالي التكاليف والمصروفات',
            value: _formatCurrency(totalExpenses),
            icon: Icons.trending_down,
            color: Colors.red[700]!,
            subtitle: 'مبيعات + تشغيل',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ReportKpiCard(
            title: isProfit ? 'صافي الربح' : 'صافي الخسارة',
            value: _formatCurrency(s.netIncome),
            icon: isProfit ? Icons.account_balance : Icons.warning,
            color: isProfit ? Colors.teal[700]! : Colors.deepOrange[700]!,
            trendText: '${marginPercent.toStringAsFixed(1)}%',
            isPositiveTrend: isProfit,
            subtitle: 'هامش الربحية',
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(IncomeStatementEntity cat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            cat.categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blueGrey,
            ),
          ),
        ),
        ...cat.items.map(
          (i) => ListTile(
            dense: true,
            title: Text(i.accountName, style: const TextStyle(fontSize: 13)),
            trailing: Text(
              _formatCurrency(i.amount),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي ${cat.categoryName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                _formatCurrency(cat.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFinalNetIncome(IncomeStatementSummary s) {
    final isProfit = s.netIncome >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isProfit ? Colors.green[50] : Colors.red[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isProfit ? 'صافي الربح' : 'صافي الخسارة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green[800] : Colors.red[800],
            ),
          ),
          Text(
            _formatCurrency(s.netIncome),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }
}
