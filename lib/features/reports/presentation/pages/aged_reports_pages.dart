import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class AgedReceivablesReportPage extends StatefulWidget {
  const AgedReceivablesReportPage({super.key});
  @override
  State<AgedReceivablesReportPage> createState() =>
      _AgedReceivablesReportPageState();
}

class _AgedReceivablesReportPageState extends State<AgedReceivablesReportPage> {
  _AgedResult? _lastResult;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أعمار ديون العملاء',
      icon: Icons.hourglass_top,
      color: AppColors.materialRed500,
      onPrint: _lastResult == null
          ? null
          : () => _exportPdf('تقرير أعمار ديون العملاء'),
      onExportExcel: _lastResult == null
          ? null
          : () => _exportExcel('aged_receivables'),
      reportBuilder: (filter) => _AgedInvoicesContent(
        filter: filter,
        titleLabel: 'العملاء',
        customerType: 1,
        invoiceTypes: const [1],
        onLoad: (r) => setState(() => _lastResult = r),
      ),
    );
  }

  void _exportPdf(String title) => ExportService.printData(
    title: title,
    headers: ['الفترة', 'العدد', 'المبلغ المستحق'],
    data: _lastResult!.buckets
        .map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)])
        .toList(),
  );
  void _exportExcel(String fileName) => ExportService.exportToExcel(
    fileName: fileName,
    headers: ['فترة التأخير', 'عدد الفواتير', 'إجمالي المبلغ المتأخر'],
    data: _lastResult!.buckets
        .map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)])
        .toList(),
  );
}

class AgedPayablesReportPage extends StatefulWidget {
  const AgedPayablesReportPage({super.key});
  @override
  State<AgedPayablesReportPage> createState() => _AgedPayablesReportPageState();
}

class _AgedPayablesReportPageState extends State<AgedPayablesReportPage> {
  _AgedResult? _lastResult;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أعمار مستحقات الموردين',
      icon: Icons.hourglass_bottom,
      color: AppColors.materialDeepOrange700,
      onPrint: _lastResult == null
          ? null
          : () => _exportPdf('تقرير أعمار مستحقات الموردين'),
      onExportExcel: _lastResult == null
          ? null
          : () => _exportExcel('aged_payables'),
      reportBuilder: (filter) => _AgedInvoicesContent(
        filter: filter,
        titleLabel: 'الموردين',
        customerType: 2,
        invoiceTypes: const [2],
        onLoad: (r) => setState(() => _lastResult = r),
      ),
    );
  }

  void _exportPdf(String title) => ExportService.printData(
    title: title,
    headers: ['الفترة', 'العدد', 'المبلغ المستحق'],
    data: _lastResult!.buckets
        .map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)])
        .toList(),
  );
  void _exportExcel(String fileName) => ExportService.exportToExcel(
    fileName: fileName,
    headers: ['فترة التأخير', 'عدد الفواتير', 'إجمالي المبلغ المتأخر'],
    data: _lastResult!.buckets
        .map((b) => [b.label, b.count.toString(), b.amount.toStringAsFixed(2)])
        .toList(),
  );
}

class _AgedInvoicesContent extends StatefulWidget {
  final ReportFilter filter;
  final String titleLabel;
  final int customerType;
  final List<int> invoiceTypes;
  final Function(_AgedResult) onLoad;
  const _AgedInvoicesContent({
    required this.filter,
    required this.titleLabel,
    required this.customerType,
    required this.invoiceTypes,
    required this.onLoad,
  });

  @override
  State<_AgedInvoicesContent> createState() => _AgedInvoicesContentState();
}

class _AgedInvoicesContentState extends State<_AgedInvoicesContent> {
  late Future<_AgedResult> _future;
  _AgedResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _AgedInvoicesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.customerType != widget.customerType) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AgedResult>(
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(data),
          );
        }
        if (data == null || data.buckets.isEmpty) {
          return const Center(child: Text('لا توجد ديون متأخرة حالياً'));
        }

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي متأخر',
                  value: data.total.toStringAsFixed(2),
                  icon: Icons.warning,
                  color: Colors.red,
                ),
                ReportSummaryCard(
                  title: 'عدد المستندات',
                  value: data.count.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                ReportSummaryCard(
                  title: 'عدد ${widget.titleLabel}',
                  value: data.parties.toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: AppConstant.defaultPadding,
                children: data.buckets
                    .map(
                      (b) => CustomCardContainer(
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            b.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'عدد الفواتير: ${b.count}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${b.amount.toStringAsFixed(2)} ر.س',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_AgedResult> _load() async {
    final ds = getIt<ReportsLocalDataSource>();
    final now = DateTime.now();
    final rows = await ds.getAgedReceivables(
      filter: widget.filter,
      customerType: widget.customerType,
      invoiceTypes: widget.invoiceTypes,
    );

    final buckets = {
      '0-30': _AgedBucket(label: '0 - 30 يوم', amount: 0, count: 0),
      '31-60': _AgedBucket(label: '31 - 60 يوم', amount: 0, count: 0),
      '61-90': _AgedBucket(label: '61 - 90 يوم', amount: 0, count: 0),
      '90+': _AgedBucket(label: 'أكثر من 90 يوم', amount: 0, count: 0),
    };
    final partyIds = <int>{};
    for (final r in rows) {
      final amt =
          ((r['amount'] as num).toDouble() -
                  (r['paid_amount'] as num).toDouble() -
                  (r['bank_paid_amount'] as num).toDouble())
              .clamp(0, double.infinity)
              .toDouble();
      if (amt == 0) continue;
      partyIds.add(r['customer_id'] as int);
      final dueDate = dateTimeFromReportTimestamp(
        (r['due_date'] ?? r['date']) as num,
      );
      final days = (widget.filter.endDate ?? now).difference(dueDate).inDays;
      final key = days <= 30
          ? '0-30'
          : days <= 60
          ? '31-60'
          : days <= 90
          ? '61-90'
          : '90+';
      buckets[key] = buckets[key]!.copyWith(
        amount: buckets[key]!.amount + amt,
        count: buckets[key]!.count + 1,
      );
    }
    final list = buckets.values.where((b) => b.count > 0).toList();
    return _AgedResult(
      buckets: list,
      total: list.fold(0, (s, b) => s + b.amount),
      count: list.fold(0, (sum, bucket) => sum + bucket.count),
      parties: partyIds.length,
    );
  }
}

class _AgedResult {
  final List<_AgedBucket> buckets;
  final double total;
  final int count, parties;
  _AgedResult({
    required this.buckets,
    required this.total,
    required this.count,
    required this.parties,
  });
}

class _AgedBucket {
  final String label;
  final double amount;
  final int count;
  _AgedBucket({required this.label, required this.amount, required this.count});
  _AgedBucket copyWith({double? amount, int? count}) => _AgedBucket(
    label: label,
    amount: amount ?? this.amount,
    count: count ?? this.count,
  );
}
