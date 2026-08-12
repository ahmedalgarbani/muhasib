import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class StockReportPage extends StatefulWidget {
  const StockReportPage({super.key});
  @override
  State<StockReportPage> createState() => _StockReportPageState();
}

class _StockReportPageState extends State<StockReportPage> {
  StockLoaded? _lastState;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StockCubit>()..loadStock(),
      child: BlocConsumer<StockCubit, StockState>(
        listener: (context, state) {
          if (state is StockLoaded) setState(() => _lastState = state);
        },
        builder: (context, state) {
          return ReportBasePage(
            title: 'تقرير جرد المخزون',
            icon: Icons.warehouse,
            color: AppColors.blueGrey600,
            showDateFilter: false,
            onPrint: _lastState == null ? null : () => _exportPdf(),
            onExportExcel: _lastState == null ? null : () => _exportExcel(),
            reportBuilder: (filter) => const _StockReportContent(),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastState == null) return;
    final headers = ['الصنف', 'الكود', 'الكمية', 'التكلفة', 'القيمة'];
    final data = _lastState!.filteredStocks.map((s) => [
      s.productName, s.productCode, s.currentStock.toStringAsFixed(2),
      s.costPrice.toStringAsFixed(2), s.stockValue.toStringAsFixed(2),
    ]).toList();
    await ExportService.printData(title: 'تقرير جرد المخزون', headers: headers, data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastState == null) return;
    final headers = ['اسم الصنف', 'الكود', 'الكمية الحالية', 'سعر التكلفة', 'إجمالي القيمة'];
    final data = _lastState!.filteredStocks.map((s) => [
      s.productName, s.productCode, s.currentStock.toStringAsFixed(2),
      s.costPrice.toStringAsFixed(2), s.stockValue.toStringAsFixed(2),
    ]).toList();
    await ExportService.exportToExcel(fileName: 'stock_inventory', headers: headers, data: data);
  }
}

class _StockReportContent extends StatefulWidget {
  const _StockReportContent();
  @override
  State<_StockReportContent> createState() => _StockReportContentState();
}

class _StockReportContentState extends State<_StockReportContent> {
  final TextEditingController _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockCubit, StockState>(
      builder: (context, state) {
        if (state is StockLoading) return const Center(child: CircularProgressIndicator());
        if (state is StockError) return Center(child: Text('خطأ: ${state.message}'));
        if (state is StockLoaded) {
          final stocks = state.filteredStocks;
          final s = state.summary;

          return Column(
            children: [
              ReportSummaryRow(cards: [
                ReportSummaryCard(title: 'قيمة المخزون', value: '${_numberFormat.format(s.totalStockValue)} ر.س', icon: Icons.monetization_on, color: Colors.green),
                ReportSummaryCard(title: 'إجمالي الوحدات', value: s.totalQuantity.toInt().toString(), icon: Icons.inventory, color: Colors.blue),
                ReportSummaryCard(title: 'نقص المخزون', value: s.lowStockCount.toString(), icon: Icons.warning, color: Colors.orange),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(hintText: 'بحث في الأصناف...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none)),
                  onChanged: (v) => context.read<StockCubit>().updateSearch(v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final item = stocks[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: item.currentStock <= item.minStock ? Colors.orange.withOpacity(0.3) : Colors.grey[100]!)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(AppRadius.sm)), child: const Icon(Icons.inventory_2, color: Colors.blueGrey)),
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('كود: ${item.productCode}', style: const TextStyle(fontSize: 10)),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${item.currentStock.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: item.currentStock <= item.minStock ? Colors.orange : Colors.blueGrey)), Text('${_numberFormat.format(item.stockValue)} ر.س', style: const TextStyle(fontSize: 9, color: Colors.grey))]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
