import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class SalesByCustomerReportPage extends StatefulWidget {
  const SalesByCustomerReportPage({super.key});
  @override
  State<SalesByCustomerReportPage> createState() =>
      _SalesByCustomerReportPageState();
}

class _SalesByCustomerReportPageState extends State<SalesByCustomerReportPage> {
  List<_PartyRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مبيعات حسب العميل',
      icon: Icons.people,
      color: AppColors.materialGreen700,
      onPrint: _lastRows == null
          ? null
          : () => _exportPdf('تقرير مبيعات العملاء', [
              'العميل',
              'العدد',
              'الإجمالي',
            ]),
      onExportExcel: _lastRows == null
          ? null
          : () => _exportExcel('customers_sales', [
              'اسم العميل',
              'عدد الفواتير',
              'إجمالي المبيعات',
            ]),
      reportBuilder: (filter) => _AggregateByPartyContent(
        filter: filter,
        invoiceType: 1,
        titleLabel: 'العميل',
        onLoad: (rows) => setState(() => _lastRows = rows),
      ),
    );
  }

  void _exportPdf(String title, List<String> headers) =>
      ExportService.printData(
        title: title,
        headers: headers,
        data: _lastRows!
            .map(
              (r) => [r.name, r.count.toString(), r.total.toStringAsFixed(2)],
            )
            .toList(),
      );
  void _exportExcel(String fileName, List<String> headers) =>
      ExportService.exportToExcel(
        fileName: fileName,
        headers: headers,
        data: _lastRows!
            .map(
              (r) => [r.name, r.count.toString(), r.total.toStringAsFixed(2)],
            )
            .toList(),
      );
}

class PurchaseBySupplierReportPage extends StatefulWidget {
  const PurchaseBySupplierReportPage({super.key});
  @override
  State<PurchaseBySupplierReportPage> createState() =>
      _PurchaseBySupplierReportPageState();
}

class _PurchaseBySupplierReportPageState
    extends State<PurchaseBySupplierReportPage> {
  List<_PartyRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مشتريات حسب المورد',
      icon: Icons.local_shipping,
      color: AppColors.materialOrange700,
      onPrint: _lastRows == null
          ? null
          : () => _exportPdf('تقرير مشتريات الموردين', [
              'المورد',
              'العدد',
              'الإجمالي',
            ]),
      onExportExcel: _lastRows == null
          ? null
          : () => _exportExcel('suppliers_purchases', [
              'اسم المورد',
              'عدد الفواتير',
              'إجمالي المشتريات',
            ]),
      reportBuilder: (filter) => _AggregateByPartyContent(
        filter: filter,
        invoiceType: 2,
        titleLabel: 'المورد',
        onLoad: (rows) => setState(() => _lastRows = rows),
      ),
    );
  }

  void _exportPdf(String title, List<String> headers) =>
      ExportService.printData(
        title: title,
        headers: headers,
        data: _lastRows!
            .map(
              (r) => [r.name, r.count.toString(), r.total.toStringAsFixed(2)],
            )
            .toList(),
      );
  void _exportExcel(String fileName, List<String> headers) =>
      ExportService.exportToExcel(
        fileName: fileName,
        headers: headers,
        data: _lastRows!
            .map(
              (r) => [r.name, r.count.toString(), r.total.toStringAsFixed(2)],
            )
            .toList(),
      );
}

class DailySalesReportPage extends StatefulWidget {
  const DailySalesReportPage({super.key});
  @override
  State<DailySalesReportPage> createState() => _DailySalesReportPageState();
}

class _DailySalesReportPageState extends State<DailySalesReportPage> {
  List<_DailyRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'المبيعات اليومية',
      icon: Icons.today,
      color: AppColors.materialCyan700,
      onPrint: _lastRows == null ? null : () => _exportPdf(),
      onExportExcel: _lastRows == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _DailyTotalsContent(
        filter: filter,
        invoiceType: 1,
        onLoad: (rows) => setState(() => _lastRows = rows),
      ),
    );
  }

  void _exportPdf() => ExportService.printData(
    title: 'تقرير المبيعات اليومية',
    headers: ['اليوم', 'العدد', 'الإجمالي'],
    data: _lastRows!
        .map((r) => [r.day, r.count.toString(), r.total.toStringAsFixed(2)])
        .toList(),
  );
  void _exportExcel() => ExportService.exportToExcel(
    fileName: 'daily_sales',
    headers: ['التاريخ', 'عدد المستندات', 'الإجمالي'],
    data: _lastRows!
        .map((r) => [r.day, r.count.toString(), r.total.toStringAsFixed(2)])
        .toList(),
  );
}

class SalesByProductReportPage extends StatefulWidget {
  const SalesByProductReportPage({super.key});
  @override
  State<SalesByProductReportPage> createState() =>
      _SalesByProductReportPageState();
}

class _SalesByProductReportPageState extends State<SalesByProductReportPage> {
  List<_ProductRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مبيعات حسب المنتج',
      icon: Icons.inventory_2,
      color: AppColors.materialPurple700,
      onPrint: _lastRows == null ? null : () => _exportPdf(),
      onExportExcel: _lastRows == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _AggregateByProductContent(
        filter: filter,
        invoiceType: 1,
        onLoad: (rows) => setState(() => _lastRows = rows),
      ),
    );
  }

  void _exportPdf() => ExportService.printData(
    title: 'مبيعات حسب المنتج',
    headers: ['المنتج', 'الكمية', 'الإجمالي'],
    data: _lastRows!
        .map(
          (r) => [r.name, r.qty.toStringAsFixed(2), r.total.toStringAsFixed(2)],
        )
        .toList(),
  );
  void _exportExcel() => ExportService.exportToExcel(
    fileName: 'sales_by_product',
    headers: ['اسم الصنف', 'الكمية المباعة', 'إجمالي القيمة'],
    data: _lastRows!
        .map(
          (r) => [r.name, r.qty.toStringAsFixed(2), r.total.toStringAsFixed(2)],
        )
        .toList(),
  );
}

class PurchaseByProductReportPage extends StatefulWidget {
  const PurchaseByProductReportPage({super.key});
  @override
  State<PurchaseByProductReportPage> createState() =>
      _PurchaseByProductReportPageState();
}

class _PurchaseByProductReportPageState
    extends State<PurchaseByProductReportPage> {
  List<_ProductRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'مشتريات حسب المنتج',
      icon: Icons.category,
      color: AppColors.materialPink500,
      onPrint: _lastRows == null ? null : () => _exportPdf(),
      onExportExcel: _lastRows == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _AggregateByProductContent(
        filter: filter,
        invoiceType: 2,
        onLoad: (rows) => setState(() => _lastRows = rows),
      ),
    );
  }

  void _exportPdf() => ExportService.printData(
    title: 'مشتريات حسب المنتج',
    headers: ['المنتج', 'الكمية', 'الإجمالي'],
    data: _lastRows!
        .map(
          (r) => [r.name, r.qty.toStringAsFixed(2), r.total.toStringAsFixed(2)],
        )
        .toList(),
  );
  void _exportExcel() => ExportService.exportToExcel(
    fileName: 'purchases_by_product',
    headers: ['اسم الصنف', 'الكمية المشتراة', 'إجمالي القيمة'],
    data: _lastRows!
        .map(
          (r) => [r.name, r.qty.toStringAsFixed(2), r.total.toStringAsFixed(2)],
        )
        .toList(),
  );
}

class _AggregateByPartyContent extends StatefulWidget {
  final ReportFilter filter;
  final int invoiceType;
  final String titleLabel;
  final Function(List<_PartyRow>) onLoad;
  const _AggregateByPartyContent({
    required this.filter,
    required this.invoiceType,
    required this.titleLabel,
    required this.onLoad,
  });

  @override
  State<_AggregateByPartyContent> createState() =>
      _AggregateByPartyContentState();
}

class _AggregateByPartyContentState extends State<_AggregateByPartyContent> {
  late Future<List<_PartyRow>> _future;
  List<_PartyRow>? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _AggregateByPartyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.invoiceType != widget.invoiceType) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_PartyRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows != _notifiedResult) {
          _notifiedResult = rows;
          if (rows.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onLoad(rows),
            );
          }
        }
        if (rows.isEmpty) return const Center(child: Text('لا توجد بيانات'));

        final total = rows.fold<double>(0, (s, r) => s + r.total);
        final count = rows.fold<int>(0, (s, r) => s + r.count);

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'عدد المستندات',
                  value: count.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'الإجمالي',
                  value: total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'عدد ${widget.titleLabel}',
                  value: rows.length.toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: AppConstant.defaultPadding,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return CustomCardContainer(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        r.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'عدد: ${r.count}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${r.total.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<_PartyRow>> _load() async {
    final ds = getIt<ReportsLocalDataSource>();
    final rows = await ds.getSalesAggregatesByParty(
      invoiceType: widget.invoiceType,
      filter: widget.filter,
    );

    return rows
        .map(
          (m) => _PartyRow(
            id: m['party_id'] as int,
            name: m['party_name'] as String,
            count: m['doc_count'] as int,
            total: (m['total'] as num).toDouble(),
          ),
        )
        .toList();
  }
}

class _AggregateByProductContent extends StatefulWidget {
  final ReportFilter filter;
  final int invoiceType;
  final Function(List<_ProductRow>) onLoad;
  const _AggregateByProductContent({
    required this.filter,
    required this.invoiceType,
    required this.onLoad,
  });

  @override
  State<_AggregateByProductContent> createState() =>
      _AggregateByProductContentState();
}

class _AggregateByProductContentState
    extends State<_AggregateByProductContent> {
  late Future<List<_ProductRow>> _future;
  List<_ProductRow>? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _AggregateByProductContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.invoiceType != widget.invoiceType) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ProductRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows != _notifiedResult) {
          _notifiedResult = rows;
          if (rows.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onLoad(rows),
            );
          }
        }
        if (rows.isEmpty) return const Center(child: Text('لا توجد بيانات'));

        final total = rows.fold<double>(0, (s, r) => s + r.total);
        final qty = rows.fold<double>(0, (s, r) => s + r.qty);

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'عدد الأصناف',
                  value: rows.length.toString(),
                  icon: Icons.category,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الكمية',
                  value: qty.toStringAsFixed(2),
                  icon: Icons.inventory,
                  color: Colors.purple,
                ),
                ReportSummaryCard(
                  title: 'الإجمالي',
                  value: total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: AppConstant.defaultPadding,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return CustomCardContainer(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        r.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'كمية: ${r.qty.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${r.total.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<_ProductRow>> _load() async {
    final ds = getIt<ReportsLocalDataSource>();
    final rows = await ds.getSalesAggregatesByProduct(
      invoiceType: widget.invoiceType,
      filter: widget.filter,
    );
    return rows
        .map(
          (m) => _ProductRow(
            id: m['pid'] as int? ?? 0,
            name: m['pname'] as String? ?? 'بدون صنف',
            qty: (m['qty'] as num).toDouble(),
            total: (m['total'] as num).toDouble(),
          ),
        )
        .toList();
  }
}

class _DailyTotalsContent extends StatefulWidget {
  final ReportFilter filter;
  final int invoiceType;
  final Function(List<_DailyRow>) onLoad;
  const _DailyTotalsContent({
    required this.filter,
    required this.invoiceType,
    required this.onLoad,
  });

  @override
  State<_DailyTotalsContent> createState() => _DailyTotalsContentState();
}

class _DailyTotalsContentState extends State<_DailyTotalsContent> {
  late Future<List<_DailyRow>> _future;
  List<_DailyRow>? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _DailyTotalsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.invoiceType != widget.invoiceType) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_DailyRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows != _notifiedResult) {
          _notifiedResult = rows;
          if (rows.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onLoad(rows),
            );
          }
        }
        if (rows.isEmpty) return const Center(child: Text('لا توجد بيانات'));

        final total = rows.fold<double>(0, (s, r) => s + r.total);
        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'الإجمالي العام',
                  value: total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'عدد الأيام',
                  value: rows.length.toString(),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'المتوسط اليومي',
                  value: (total / rows.length).toStringAsFixed(2),
                  icon: Icons.analytics,
                  color: Colors.purple,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: AppConstant.defaultPadding,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return CustomCardContainer(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        r.day,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'عدد المستندات: ${r.count}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${r.total.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<_DailyRow>> _load() async {
    final ds = getIt<ReportsLocalDataSource>();
    final rows = await ds.getSalesAggregatesDaily(
      invoiceType: widget.invoiceType,
      filter: widget.filter,
    );
    return rows
        .map(
          (m) => _DailyRow(
            day: m['day'] as String,
            count: m['cnt'] as int,
            total: (m['total'] as num).toDouble(),
          ),
        )
        .toList();
  }
}

class _PartyRow {
  final int id;
  final String name;
  final int count;
  final double total;
  _PartyRow({
    required this.id,
    required this.name,
    required this.count,
    required this.total,
  });
}

class _ProductRow {
  final int id;
  final String name;
  final double qty, total;
  _ProductRow({
    required this.id,
    required this.name,
    required this.qty,
    required this.total,
  });
}

class _DailyRow {
  final String day;
  final int count;
  final double total;
  _DailyRow({required this.day, required this.count, required this.total});
}
