import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_data_table.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseSummaryReportPage extends StatefulWidget {
  const PurchaseSummaryReportPage({super.key});
  @override
  State<PurchaseSummaryReportPage> createState() =>
      _PurchaseSummaryReportPageState();
}

class _PurchaseSummaryReportPageState extends State<PurchaseSummaryReportPage> {
  _PurchaseSummaryResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير ملخص المشتريات',
      icon: Icons.shopping_basket,
      color: AppColors.materialDeepOrange700,
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _PurchaseSummaryContent(
        filter: filter,
        onLoad: (r) => setState(() => _lastResult = r),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final data = [
      ['إجمالي المشتريات', _lastResult!.totalPurchases.toStringAsFixed(2)],
      ['المرتجعات', _lastResult!.totalReturns.toStringAsFixed(2)],
      ['صافي المشتريات', _lastResult!.netPurchases.toStringAsFixed(2)],
      ['الضرائب', _lastResult!.totalTaxes.toStringAsFixed(2)],
      ['الخصومات', _lastResult!.totalDiscounts.toStringAsFixed(2)],
    ];
    await ExportService.printData(
      title: 'ملخص المشتريات',
      headers: ['البيان', 'المبلغ'],
      data: data,
    );
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    await ExportService.exportToExcel(
      fileName: 'purchase_summary',
      headers: ['البيان', 'المبلغ'],
      data: [
        ['إجمالي المشتريات', _lastResult!.totalPurchases.toStringAsFixed(2)],
        ['المرتجعات', _lastResult!.totalReturns.toStringAsFixed(2)],
        ['صافي المشتريات', _lastResult!.netPurchases.toStringAsFixed(2)],
      ],
    );
  }
}

class _PurchaseSummaryContent extends StatefulWidget {
  final ReportFilter filter;
  final ValueChanged<_PurchaseSummaryResult> onLoad;

  const _PurchaseSummaryContent({required this.filter, required this.onLoad});

  @override
  State<_PurchaseSummaryContent> createState() =>
      _PurchaseSummaryContentState();
}

class _PurchaseSummaryContentState extends State<_PurchaseSummaryContent> {
  late Future<_PurchaseSummaryResult> _future;
  _PurchaseSummaryResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _PurchaseSummaryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load(widget.filter);
  }

  String _format(double v) => NumberFormatter.formatCurrency(v, symbol: 'ر.س');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PurchaseSummaryResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data != null && data != _notifiedResult) {
          _notifiedResult = data;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onLoad(data);
          });
        }
        if (data == null) return const Center(child: Text('لا توجد بيانات'));

        var topSuppliers = data.topSuppliers;
        if (widget.filter.searchQuery != null &&
            widget.filter.searchQuery!.isNotEmpty) {
          final q = widget.filter.searchQuery!.toLowerCase();
          topSuppliers = topSuppliers
              .where((s) => s.name.toLowerCase().contains(q))
              .toList();
        }

        return SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReportKpiCard(
                      title: 'صافي المشتريات',
                      value: _format(data.netPurchases),
                      icon: Icons.shopping_basket,
                      color: Colors.deepOrange[700]!,
                      subtitle: 'عدد الفواتير: ${data.invoiceCount}',
                      isPositiveTrend: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReportKpiCard(
                      title: 'إجمالي المشتريات قبل الخصم',
                      value: _format(data.totalPurchases),
                      icon: Icons.shopping_bag,
                      color: Colors.purple[700]!,
                      subtitle: 'المرتجعات: ${_format(data.totalReturns)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReportKpiCard(
                      title: 'الخصومات والضرائب المدفوعة',
                      value: _format(data.totalDiscounts + data.totalTaxes),
                      icon: Icons.receipt_long,
                      color: Colors.teal[700]!,
                      subtitle:
                          'خصم: ${_format(data.totalDiscounts)} | ضريبة: ${_format(data.totalTaxes)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'أكثر الموردين تعاملاً في المشتريات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ReportDataTable<_SupplierRow>(
                columns: const [
                  ReportTableColumn(title: 'اسم المورد', flex: 4),
                  ReportTableColumn(
                    title: 'إجمالي المشتريات منه',
                    flex: 3,
                    alignment: TextAlign.end,
                  ),
                ],
                items: topSuppliers,
                rowBuilder: (context, s, index) => Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: index < 3
                                ? Colors.deepOrange[100]
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: index < 3
                                    ? Colors.deepOrange[900]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.name,
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
                      flex: 3,
                      child: Text(
                        _format(s.total),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_PurchaseSummaryResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      df = 'AND i.date >= ? AND i.date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }
    final totals = await db.rawQuery(
      'SELECT COUNT(CASE WHEN i.invoice_type = 2 THEN 1 END) as ic, COUNT(CASE WHEN i.invoice_type = 5 THEN 1 END) as rc, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as tp, COALESCE(SUM(CASE WHEN i.invoice_type = 5 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as tr, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.tax_amt, 0) END), 0) as tx, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.discount_amt, 0) END), 0) as td FROM invoices i WHERE (i.invoice_type = 2 OR i.invoice_type = 5) AND COALESCE(i.approval_status, 1) != 3 $df',
      args,
    );
    final top = await db.rawQuery(
      'SELECT c.name, COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total FROM invoices i JOIN customers c ON c.id = i.customer_id WHERE i.invoice_type = 2 AND COALESCE(i.approval_status, 1) != 3 $df GROUP BY c.id ORDER BY total DESC',
      args,
    );
    return _PurchaseSummaryResult(
      totalPurchases: (totals.first['tp'] as num).toDouble(),
      totalReturns: (totals.first['tr'] as num).toDouble(),
      totalTaxes: (totals.first['tx'] as num).toDouble(),
      totalDiscounts: (totals.first['td'] as num).toDouble(),
      invoiceCount: totals.first['ic'] as int,
      topSuppliers: top
          .map(
            (m) => _SupplierRow(
              name: m['name'] as String,
              total: (m['total'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}

class _PurchaseSummaryResult {
  final double totalPurchases, totalReturns, totalTaxes, totalDiscounts;
  final int invoiceCount;
  final List<_SupplierRow> topSuppliers;
  _PurchaseSummaryResult({
    required this.totalPurchases,
    required this.totalReturns,
    required this.totalTaxes,
    required this.totalDiscounts,
    required this.invoiceCount,
    required this.topSuppliers,
  });
  double get netPurchases => totalPurchases - totalReturns;
}

class _SupplierRow {
  final String name;
  final double total;
  _SupplierRow({required this.name, required this.total});
}
