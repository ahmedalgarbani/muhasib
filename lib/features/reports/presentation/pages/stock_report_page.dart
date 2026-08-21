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
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class StockReportPage extends StatefulWidget {
  const StockReportPage({super.key});
  @override
  State<StockReportPage> createState() => _StockReportPageState();
}

class _StockReportPageState extends State<StockReportPage> {
  StockLoaded? _lastState;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<StockCubit>()..loadStock()),
        BlocProvider(
            create: (context) => getIt<WarehousesCubit>()..loadActiveWarehouses()),
      ],
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
  int? _selectedWarehouseId;

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

  Widget _buildWarehouseFilter() {
    return BlocBuilder<WarehousesCubit, WarehousesState>(
      builder: (context, wState) {
        List<WarehouseEntity> warehouses = [];
        final isLoading = wState is WarehousesLoading;
        if (wState is WarehousesLoaded) warehouses = wState.warehouses;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warehouse, size: 20, color: AppColors.blueGrey600),
              const SizedBox(width: 8),
              const Text('المخزن:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              if (isLoading)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedWarehouseId,
                      isExpanded: true,
                      isDense: true,
                      hint: const Text('كل المخازن',
                          style: TextStyle(fontSize: 13)),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null, child: Text('كل المخازن')),
                        ...warehouses.map((w) => DropdownMenuItem<int?>(
                            value: w.id, child: Text(w.name))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedWarehouseId = val);
                        context.read<StockCubit>().filterByWarehouse(val);
                      },
                    ),
                  ),
                ),
              if (_selectedWarehouseId != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() => _selectedWarehouseId = null);
                    context.read<StockCubit>().filterByWarehouse(null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.clear, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('مسح',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildWarehouseFilter(),
        ),
        Expanded(
          child: BlocBuilder<StockCubit, StockState>(
            builder: (context, state) {
              if (state is StockLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is StockError) {
                return Center(child: Text('خطأ: ${state.message}'));
              }
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
                const SizedBox(height: 10),
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
        ),
      ),
      ],
    );
  }
}
