import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

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
      create: (context) => getIt<SalesSummaryCubit>()..loadSalesSummary(),
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
    await ExportService.printData(title: 'ملخص المبيعات', headers: ['البيان', 'المبلغ'], data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastState == null) return;
    final s = _lastState!.summary;
    final path = await ExportService.exportToExcel(fileName: 'sales_summary', headers: ['البيان', 'المبلغ'], data: [['إجمالي المبيعات', s.totalSales.toStringAsFixed(2)], ['المرتجعات', s.totalReturns.toStringAsFixed(2)], ['صافي المبيعات', s.netSales.toStringAsFixed(2)], ['عدد الفواتير', s.invoiceCount.toString()]]);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تصدير Excel: $path')));
  }
}

class _SalesSummaryContent extends StatefulWidget {
  final ReportFilter filter;
  const _SalesSummaryContent({required this.filter});
  @override
  State<_SalesSummaryContent> createState() => _SalesSummaryContentState();
}

class _SalesSummaryContentState extends State<_SalesSummaryContent> {
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

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
    if (oldWidget.filter != widget.filter) context.read<SalesSummaryCubit>().updateDateRange(widget.filter);
  }

  String _format(double v) => '${_numberFormat.format(v)} ر.س';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesSummaryCubit, SalesSummaryState>(
      builder: (context, state) {
        if (state is SalesSummaryLoading) return const Center(child: CircularProgressIndicator());
        if (state is SalesSummaryError) return Center(child: Text('خطأ: ${state.message}'));
        if (state is SalesSummaryLoaded) {
          final s = state.summary;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMainTile(s),
                const SizedBox(height: 16),
                _buildDetailRow(s),
                const SizedBox(height: 16),
                _buildProductExpansion(s),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMainTile(dynamic s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.materialBlue900, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
        const Text('صافي مبيعات الفترة', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(_format(s.netSales), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24, height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _miniStat('الإجمالي', _format(s.totalSales)),
          _miniStat('المرتجعات', _format(s.totalReturns)),
          _miniStat('الفواتير', '${s.invoiceCount}'),
        ]),
      ]),
    );
  }

  Widget _miniStat(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)), const SizedBox(height: 4), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]);

  Widget _buildDetailRow(dynamic s) {
    return Row(children: [
      Expanded(child: _infoCard('الخصومات', s.totalDiscounts, Colors.orange, Icons.sell)),
      const SizedBox(width: 12),
      Expanded(child: _infoCard('الضرائب', s.totalTaxes, Colors.purple, Icons.account_balance)),
    ]);
  }

  Widget _infoCard(String l, double v, Color c, IconData i) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg20), border: Border.all(color: c.withOpacity(0.1))), child: Row(children: [Icon(i, color: c, size: 20), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), Text(_format(v), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c))])]));

  Widget _buildProductExpansion(dynamic s) {
    if (s.topProducts.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg20), side: BorderSide(color: Colors.grey[200]!)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.star, color: Colors.amber),
        title: const Text('أهم المنتجات مبيعًا', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: s.topProducts.take(5).map<Widget>((p) => ListTile(dense: true, title: Text(p.productName, style: const TextStyle(fontSize: 13)), subtitle: Text('الكمية: ${p.quantity.toInt()}', style: const TextStyle(fontSize: 11)), trailing: Text(_format(p.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
      ),
    );
  }
}
