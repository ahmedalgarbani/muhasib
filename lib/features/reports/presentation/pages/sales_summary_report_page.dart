import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_data_table.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class SalesSummaryReportPage extends StatefulWidget {
  const SalesSummaryReportPage({super.key});
  @override
  State<SalesSummaryReportPage> createState() => _SalesSummaryReportPageState();
}

class _SalesSummaryReportPageState extends State<SalesSummaryReportPage> {
  SalesSummaryLoaded? _lastState;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SalesSummaryCubit>()..loadSalesSummary(ReportFilter.currentMonth()),
      child: BlocConsumer<SalesSummaryCubit, SalesSummaryState>(
        listener: (context, state) {
          if (state is SalesSummaryLoaded) setState(() => _lastState = state);
        },
        builder: (context, state) {
          return ReportBasePage(
            title: 'ملخص مبيعات شامل',
            icon: Icons.analytics,
            color: AppColors.materialBlue900,
            onPrint: _lastState == null ? null : () => _exportPdf(),
            onExportExcel: _lastState == null ? null : () => _exportExcel(),
            reportBuilder: (filter) => _SalesSummaryContent(filter: filter),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastState == null) return;
    final s = _lastState!.summary;
    final data = [
      ['إجمالي المبيعات', s.totalSales.toStringAsFixed(2)],
      ['المرتجعات', s.totalReturns.toStringAsFixed(2)],
      ['الخصومات', s.totalDiscounts.toStringAsFixed(2)],
      ['الضرائب', s.totalTaxes.toStringAsFixed(2)],
      ['صافي المبيعات', s.netSales.toStringAsFixed(2)],
      ['عدد الفواتير', s.invoiceCount.toString()],
    ];
    await ExportService.printData(
      title: 'ملخص المبيعات',
      headers: ['البيان', 'المبلغ'],
      data: data,
    );
  }

  Future<void> _exportExcel() async {
    if (_lastState == null) return;
    final s = _lastState!.summary;
    final path = await ExportService.exportToExcel(
      fileName: 'sales_summary',
      headers: ['البيان', 'المبلغ'],
      data: [
        ['إجمالي المبيعات', s.totalSales.toStringAsFixed(2)],
        ['المرتجعات', s.totalReturns.toStringAsFixed(2)],
        ['صافي المبيعات', s.netSales.toStringAsFixed(2)],
        ['عدد الفواتير', s.invoiceCount.toString()],
      ],
    );
    AppToast.showSuccess(context, 'تم تصدير Excel: $path');
  }
}

class _SalesSummaryContent extends StatefulWidget {
  final ReportFilter filter;
  const _SalesSummaryContent({required this.filter});
  @override
  State<_SalesSummaryContent> createState() => _SalesSummaryContentState();
}

class _SalesSummaryContentState extends State<_SalesSummaryContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesSummaryCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_SalesSummaryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter)
      context.read<SalesSummaryCubit>().updateDateRange(widget.filter);
  }

  String _format(double v) => NumberFormatter.formatCurrency(v, symbol: 'ر.س');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesSummaryCubit, SalesSummaryState>(
      builder: (context, state) {
        if (state is SalesSummaryLoading)
          return const Center(child: CircularProgressIndicator());
        if (state is SalesSummaryError)
          return Center(child: Text('خطأ: ${state.message}'));
        if (state is SalesSummaryLoaded) {
          final s = state.summary;

          var topProducts = s.topProducts;
          if (widget.filter.searchQuery != null &&
              widget.filter.searchQuery!.isNotEmpty) {
            final q = widget.filter.searchQuery!.toLowerCase();
            topProducts = topProducts
                .where((p) => p.productName.toLowerCase().contains(q))
                .toList();
          }

          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 170,
                        child: ReportKpiCard(
                          title: 'صافي المبيعات',
                          value: _format(s.netSales),
                          icon: Icons.trending_up,
                          color: Colors.green[700]!,
                          subtitle: 'عدد الفواتير: ${s.invoiceCount}',
                          isPositiveTrend: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 170,
                        child: ReportKpiCard(
                          title: 'إجمالي المبيعات قبل الخصم',
                          value: _format(s.totalSales),
                          icon: Icons.point_of_sale,
                          color: Colors.blue[700]!,
                          subtitle: 'المرتجعات: ${_format(s.totalReturns)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 170,
                        child: ReportKpiCard(
                          title: 'إجمالي الخصومات والضرائب',
                        value: _format(s.totalDiscounts + s.totalTaxes),
                        icon: Icons.discount,
                        color: Colors.orange[700]!,
                        subtitle:
                            'خصم: ${_format(s.totalDiscounts)} | ضريبة: ${_format(s.totalTaxes)}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ترتيب المنتجات الأكثر مبيعاً',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ReportDataTable<dynamic>(
                  columns: const [
                    ReportTableColumn(title: 'اسم المنتج', flex: 3),
                    ReportTableColumn(
                      title: 'الكمية المباعة',
                      flex: 2,
                      alignment: TextAlign.center,
                    ),
                    ReportTableColumn(
                      title: 'إجمالي قيمة المبيعات',
                      flex: 2,
                      alignment: TextAlign.end,
                    ),
                  ],
                  items: topProducts,
                  rowBuilder: (context, p, index) => Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: index < 3
                                  ? Colors.amber[100]
                                  : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: index < 3
                                      ? Colors.amber[900]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${p.quantity.toInt()} قطعة',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _format(p.totalAmount),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
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
