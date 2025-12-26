import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class StockReportPage extends StatelessWidget {
  const StockReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StockCubit>()..loadStock(),
      child: ReportBasePage(
        title: 'تقرير المخزون',
        icon: Icons.warehouse,
        color: const Color(0xFF1976D2),
        showDateFilter: false,
        reportBuilder: (filter) => const _StockReportContent(),
      ),
    );
  }
}

class _StockReportContent extends StatefulWidget {
  const _StockReportContent();

  @override
  State<_StockReportContent> createState() => _StockReportContentState();
}

class _StockReportContentState extends State<_StockReportContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockCubit, StockState>(
      builder: (context, state) {
        if (state is StockLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is StockError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'خطأ: ${state.message}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<StockCubit>().refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is StockLoaded) {
          final stocks = state.filteredStocks;
          final summary = state.summary;

          return Column(
            children: [
              // Summary cards
              ReportSummaryRow(
                cards: [
                  ReportSummaryCard(
                    title: 'قيمة المخزون',
                    value: '${summary.totalStockValue.toStringAsFixed(0)} ر.س',
                    icon: Icons.monetization_on,
                    color: Colors.green,
                  ),
                  ReportSummaryCard(
                    title: 'إجمالي الأصناف',
                    value: '${summary.totalProducts}',
                    icon: Icons.category,
                    color: Colors.blue,
                  ),
                  ReportSummaryCard(
                    title: 'إجمالي الوحدات',
                    value: '${summary.totalQuantity.toStringAsFixed(0)}',
                    icon: Icons.inventory,
                    color: Colors.purple,
                  ),
                  ReportSummaryCard(
                    title: 'نقص في المخزون',
                    value: '${summary.lowStockCount}',
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                ],
              ),

              // Search and filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث عن صنف...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<StockCubit>().updateSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    context.read<StockCubit>().updateSearch(value);
                  },
                ),
              ),

              // Stock list
              Expanded(
                child: stocks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد منتجات',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: stocks.length,
                        itemBuilder: (context, index) {
                          final item = stocks[index];
                          final isLowStock = item.isLowStock;
                          final isOutOfStock = !item.isInStock;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isOutOfStock
                                  ? const BorderSide(color: Colors.red, width: 2)
                                  : isLowStock
                                      ? const BorderSide(color: Colors.orange, width: 2)
                                      : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Product info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (isOutOfStock)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.error, size: 14, color: Colors.red),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'نفذ',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else if (isLowStock)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.warning, size: 14, color: Colors.orange),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'نقص',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.orange,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              item.productCode,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                            if (item.categoryName != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.categoryName!,
                                                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Quantity and value
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item.currentStock.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: isLowStock ? Colors.orange : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            ' / ${item.maxStock.toStringAsFixed(0)}',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.stockValue.toStringAsFixed(0)} ر.س',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }
}

