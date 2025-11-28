import 'package:flutter/material.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class StockReportPage extends StatelessWidget {
  const StockReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير المخزون',
      icon: Icons.warehouse,
      color: const Color(0xFF1976D2),
      showDateFilter: false,
      reportBuilder: (filter) => const _StockReportContent(),
    );
  }
}

class _StockReportContent extends StatelessWidget {
  const _StockReportContent();

  @override
  Widget build(BuildContext context) {
    final items = [
      _StockItem('SKU001', 'هاتف آيفون 15', 'إلكترونيات', 45, 10, 4500, 50),
      _StockItem('SKU002', 'سماعات أيربودز', 'إلكترونيات', 120, 20, 700, 200),
      _StockItem('SKU003', 'شاحن سريع', 'اكسسوارات', 200, 50, 150, 500),
      _StockItem('SKU004', 'كفر حماية', 'اكسسوارات', 350, 30, 80, 500),
      _StockItem('SKU005', 'واقي شاشة', 'اكسسوارات', 15, 50, 40, 300),
      _StockItem('SKU006', 'ساعة ذكية', 'إلكترونيات', 25, 5, 1200, 40),
      _StockItem('SKU007', 'حقيبة لابتوب', 'حقائب', 80, 10, 250, 100),
    ];

    final totalValue = items.fold<double>(0, (sum, item) => sum + (item.quantity * item.cost));
    final lowStockCount = items.where((item) => item.quantity <= item.minStock).length;
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Column(
      children: [
        // Summary cards
        ReportSummaryRow(
          cards: [
            ReportSummaryCard(
              title: 'قيمة المخزون',
              value: '${totalValue.toStringAsFixed(0)} ر.س',
              icon: Icons.monetization_on,
              color: Colors.green,
            ),
            ReportSummaryCard(
              title: 'إجمالي الأصناف',
              value: '${items.length}',
              icon: Icons.category,
              color: Colors.blue,
            ),
            ReportSummaryCard(
              title: 'إجمالي الوحدات',
              value: '$totalItems',
              icon: Icons.inventory,
              color: Colors.purple,
            ),
            ReportSummaryCard(
              title: 'نقص في المخزون',
              value: '$lowStockCount',
              icon: Icons.warning,
              color: Colors.orange,
            ),
          ],
        ),

        // Search and filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'بحث عن صنف...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Stock list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isLowStock = item.quantity <= item.minStock;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isLowStock
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
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isLowStock)
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
                                  item.sku,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                                  ),
                                ),
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
                                '${item.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isLowStock ? Colors.orange : Colors.black,
                                ),
                              ),
                              Text(
                                ' / ${item.maxStock}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(item.quantity * item.cost).toStringAsFixed(0)} ر.س',
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
}

class _StockItem {
  final String sku;
  final String name;
  final String category;
  final int quantity;
  final int minStock;
  final double cost;
  final int maxStock;

  _StockItem(this.sku, this.name, this.category, this.quantity, this.minStock, this.cost, this.maxStock);
}

