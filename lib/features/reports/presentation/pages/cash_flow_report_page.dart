import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/reports/presentation/widgets/cash_flow_components.dart';

import 'package:muhasib/core/constant/app_constant.dart';

class CashFlowReportPage extends StatefulWidget {
  const CashFlowReportPage({super.key});
  @override
  State<CashFlowReportPage> createState() => _CashFlowReportPageState();
}

class _CashFlowReportPageState extends State<CashFlowReportPage> {
  _CashFlowResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير التدفقات النقدية',
      icon: Icons.water_drop,
      color: AppColors.materialCyan700,
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _CashFlowContent(
        filter: filter,
        onLoad: (r) => setState(() => _lastResult = r),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final headers = ['الأنشطة', 'المبلغ'];
    final data = [
      ['الرصيد الافتتاحي', _lastResult!.openingBalance.toStringAsFixed(2)],
      ['صافي التدفق التشغيلي', _lastResult!.totalOperating.toStringAsFixed(2)],
      [
        'صافي التدفق الاستثماري',
        _lastResult!.totalInvesting.toStringAsFixed(2),
      ],
      ['صافي التدفق التمويلي', _lastResult!.totalFinancing.toStringAsFixed(2)],
      ['صافي التدفق النقدي', _lastResult!.netCashFlow.toStringAsFixed(2)],
      ['الرصيد الختامي', _lastResult!.closingBalance.toStringAsFixed(2)],
    ];
    await ExportService.printData(
      title: 'تقرير التدفقات النقدية',
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    final path = await ExportService.exportToExcel(
      fileName: 'cash_flow',
      headers: ['النشاط', 'صافي القيمة'],
      data: [
        ['التشغيلية', _lastResult!.totalOperating.toStringAsFixed(2)],
        ['الاستثمارية', _lastResult!.totalInvesting.toStringAsFixed(2)],
        ['التمويلية', _lastResult!.totalFinancing.toStringAsFixed(2)],
        ['الصافي العام', _lastResult!.netCashFlow.toStringAsFixed(2)],
      ],
    );
    AppToast.showSuccess(context, 'تم تصدير Excel: $path');
  }
}

class _CashFlowContent extends StatefulWidget {
  final ReportFilter filter;
  final Function(_CashFlowResult) onLoad;

  const _CashFlowContent({required this.filter, required this.onLoad});

  @override
  State<_CashFlowContent> createState() => _CashFlowContentState();
}

class _CashFlowContentState extends State<_CashFlowContent> {
  late Future<_CashFlowResult> _future;
  _CashFlowResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _CashFlowContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load(widget.filter);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CashFlowResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('خطأ: ${snapshot.error}'));
        final data = snapshot.data;
        if (data != null && data != _notifiedResult) {
          _notifiedResult = data;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(data),
          );
        }
        if (data == null) return const Center(child: Text('لا توجد بيانات'));

        return SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 170,
                      child: ReportKpiCard(
                        title: 'التدفق التشغيلي',
                        value:
                            NumberFormatter.formatCurrency(data.totalOperating, symbol: 'ر.س'),
                        icon: Icons.business,
                        color: Colors.blue[700]!,
                        subtitle: 'حركة المبيعات والمشتريات',
                        isPositiveTrend: data.totalOperating >= 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 170,
                      child: ReportKpiCard(
                        title: 'التدفق الاستثماري والتمويلي',
                        value:
                            NumberFormatter.formatCurrency(data.totalInvesting + data.totalFinancing, symbol: 'ر.س'),
                        icon: Icons.account_balance,
                        color: Colors.purple[700]!,
                        subtitle: 'الأصول الثابتة والتمويل',
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 170,
                      child: ReportKpiCard(
                        title: 'صافي التغير النقدي',
                        value:
                            NumberFormatter.formatCurrency(data.netCashFlow, symbol: 'ر.س'),
                        icon: data.netCashFlow >= 0
                            ? Icons.water_drop
                            : Icons.warning,
                        color: data.netCashFlow >= 0
                            ? Colors.teal[700]!
                            : Colors.deepOrange[700]!,
                        subtitle:
                            'بداية: ${NumberFormatter.formatNumber(data.openingBalance)} | نهاية: ${NumberFormatter.formatNumber(data.closingBalance)}',
                        isPositiveTrend: data.netCashFlow >= 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              CashFlowSectionCardWidget(
                title: 'الأنشطة التشغيلية (المبيعات، المشتريات، المصروفات)',
                value: data.totalOperating,
                color: Colors.blue[800]!,
                icon: Icons.business,
                formatCurrency: NumberFormatter.formatNumber,
              ),
              const SizedBox(height: 12),
              CashFlowSectionCardWidget(
                title: 'الأنشطة الاستثمارية (الأصول الثابتة والاستثمارات)',
                value: data.totalInvesting,
                color: Colors.orange[800]!,
                icon: Icons.trending_up,
                formatCurrency: NumberFormatter.formatNumber,
              ),
              const SizedBox(height: 12),
              CashFlowSectionCardWidget(
                title: 'الأنشطة التمويلية (القروض، رأس المال، وسحوبات الشركاء)',
                value: data.totalFinancing,
                color: Colors.purple[800]!,
                icon: Icons.account_balance,
                formatCurrency: NumberFormatter.formatNumber,
              ),
              const SizedBox(height: 10),
              CashFlowFinalSummaryWidget(result: data),
            ],
          ),
        );
      },
    );
  }


  Future<_CashFlowResult> _load(ReportFilter filter) async {
    final ds = getIt<ReportsLocalDataSource>();
    final connects = await ds.getCashAccountIds();
    final ids = connects.map((m) => m['id'] as int).toList();
    if (ids.isEmpty) return _CashFlowResult.empty();

    final start = filter.startDate != null
        ? reportTimestampSeconds(filter.startDate!)
        : reportTimestampSeconds(DateTime(2020));
    final end = filter.endDate != null
        ? reportTimestampSeconds(filter.endDate!)
        : reportTimestampSeconds(DateTime.now());

    final openRes = await ds.getCashFlowOpeningBalance(
      startSeconds: start,
      accountIds: ids,
    );
    final open = (openRes.first['b'] as num).toDouble();

    final actualRes = await ds.getCashFlowActualBalance(
      endSeconds: end,
      accountIds: ids,
    );
    final actual = (actualRes.first['b'] as num).toDouble();

    final rows = await ds.getCashFlowGrouped(
      startSeconds: start,
      endSeconds: end,
      accountIds: ids,
    );

    double op = 0, inv = 0, fin = 0;
    for (final r in rows) {
      final n = (r['net'] as num).toDouble();
      final type = (r['reference_type'] as String? ?? '').toLowerCase();
      // Exclude already filtered opening/closing (defence in depth), and reversals are operating.
      if (type.contains('opening') || type.contains('closing')) continue;
      if (type.contains('asset') || type.contains('investment')) {
        inv += n;
      } else if (type.contains('loan') || type.contains('capital') || type.contains('financing')) {
        fin += n;
      } else {
        // Default bucket is operating (sales, purchase, receipt, payment, voucher, etc.)
        op += n;
      }
    }

    return _CashFlowResult(
      openingBalance: open,
      actualCashBalance: actual,
      totalOperating: op,
      totalInvesting: inv,
      totalFinancing: fin,
    );
  }
}

class _CashFlowResult {
  final double openingBalance,
      actualCashBalance,
      totalOperating,
      totalInvesting,
      totalFinancing;
  _CashFlowResult({
    required this.openingBalance,
    required this.actualCashBalance,
    required this.totalOperating,
    required this.totalInvesting,
    required this.totalFinancing,
  });
  double get netCashFlow => totalOperating + totalInvesting + totalFinancing;
  double get closingBalance => openingBalance + netCashFlow;
  factory _CashFlowResult.empty() => _CashFlowResult(
    openingBalance: 0,
    actualCashBalance: 0,
    totalOperating: 0,
    totalInvesting: 0,
    totalFinancing: 0,
  );
}
