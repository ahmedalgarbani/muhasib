import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_data_table.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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
            reportBuilder: (filter) =>
                _StockReportContent(searchQuery: filter.searchQuery ?? ''),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastState == null) return;
    final headers = ['الصنف', 'الكود', 'الكمية', 'التكلفة', 'القيمة'];
    final data = _lastState!.filteredStocks
        .map(
          (s) => [
            s.productName,
            s.productCode,
            s.currentStock.toStringAsFixed(2),
            s.costPrice.toStringAsFixed(2),
            s.stockValue.toStringAsFixed(2),
          ],
        )
        .toList();
    await ExportService.printData(
      title: 'تقرير جرد المخزون',
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel() async {
    if (_lastState == null) return;
    final headers = [
      'اسم الصنف',
      'الكود',
      'الكمية الحالية',
      'سعر التكلفة',
      'إجمالي القيمة',
    ];
    final data = _lastState!.filteredStocks
        .map(
          (s) => [
            s.productName,
            s.productCode,
            s.currentStock.toStringAsFixed(2),
            s.costPrice.toStringAsFixed(2),
            s.stockValue.toStringAsFixed(2),
          ],
        )
        .toList();
    await ExportService.exportToExcel(
      fileName: 'stock_inventory',
      headers: headers,
      data: data,
    );
  }
}

class _StockReportContent extends StatefulWidget {
  final String searchQuery;

  const _StockReportContent({required this.searchQuery});
  @override
  State<_StockReportContent> createState() => _StockReportContentState();
}

class _StockReportContentState extends State<_StockReportContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockCubit>().updateSearch(widget.searchQuery);
    });
  }

  @override
  void didUpdateWidget(covariant _StockReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      context.read<StockCubit>().updateSearch(widget.searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockCubit, StockState>(
      builder: (context, state) {
        if (state is StockLoading)
          return const Center(child: CircularProgressIndicator());
        if (state is StockError)
          return Center(child: Text('خطأ: ${state.message}'));
        if (state is StockLoaded) {
          final stocks = state.filteredStocks;
          final s = state.summary;

          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ReportKpiCard(
                        title: 'إجمالي قيمة المخزون',
                        value: NumberFormatter.formatCurrency(
                          s.totalStockValue,
                          symbol: 'ر.س',
                        ),
                        icon: Icons.monetization_on,
                        color: Colors.green[700]!,
                        subtitle: 'بالتكلفة الفعلية',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportKpiCard(
                        title: 'إجمالي كمية الأصناف',
                        value: '${s.totalQuantity.toInt()} قطعة',
                        icon: Icons.inventory,
                        color: Colors.blue[700]!,
                        subtitle: 'عدد الأنواع: ${stocks.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReportKpiCard(
                        title: 'تنبيهات حد النقص',
                        value: '${s.lowStockCount} صنف',
                        icon: Icons.warning,
                        color: s.lowStockCount > 0
                            ? Colors.orange[700]!
                            : Colors.grey[700]!,
                        subtitle: s.lowStockCount > 0
                            ? 'يحتاج إلى إعادة طلب'
                            : 'المخزون آمن',
                        isPositiveTrend: s.lowStockCount == 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ReportDataTable<dynamic>(
                  columns: const [
                    ReportTableColumn(title: 'رمز الصنف / اسم المنتج', flex: 3),
                    ReportTableColumn(
                      title: 'الكمية المتوفرة',
                      flex: 2,
                      alignment: TextAlign.center,
                    ),
                    ReportTableColumn(
                      title: 'سعر التكلفة',
                      flex: 2,
                      alignment: TextAlign.center,
                    ),
                    ReportTableColumn(
                      title: 'إجمالي قيمة المخزون',
                      flex: 2,
                      alignment: TextAlign.end,
                    ),
                  ],
                  items: stocks,
                  rowBuilder: (context, item, index) {
                    final isLow = item.currentStock <= item.minStock;
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    item.productCode,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (isLow) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xs,
                                        ),
                                      ),
                                      child: Text(
                                        'حد النقص',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.currentStock.toInt()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isLow
                                  ? Colors.orange[800]
                                  : Colors.grey[900],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            NumberFormatter.formatCurrency(
                              item.costPrice,
                              symbol: 'ر.س',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            NumberFormatter.formatCurrency(
                              item.stockValue,
                              symbol: 'ر.س',
                            ),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  footerRow: Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'الإجمالي العام للمخزون',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${s.totalQuantity.toInt()} قطعة',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Expanded(flex: 2, child: SizedBox()),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormatter.formatCurrency(
                            s.totalStockValue,
                            symbol: 'ر.س',
                          ),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
