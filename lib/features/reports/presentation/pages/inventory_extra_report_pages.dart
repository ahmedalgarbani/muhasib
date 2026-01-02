import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class StockMovementReportPage extends StatelessWidget {
  const StockMovementReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'حركة المخزون',
      icon: Icons.swap_horiz,
      color: const Color(0xFF388E3C),
      reportBuilder: (filter) => _StockMovementsContent(filter: filter),
    );
  }
}

class LowStockReportPage extends StatelessWidget {
  const LowStockReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تنبيه نقص المخزون',
      icon: Icons.warning,
      color: const Color(0xFFFF9800),
      showDateFilter: false,
      reportBuilder: (filter) => const _LowStockContent(),
    );
  }
}

class StockValuationReportPage extends StatelessWidget {
  const StockValuationReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقييم المخزون',
      icon: Icons.monetization_on,
      color: const Color(0xFF7B1FA2),
      showDateFilter: false,
      reportBuilder: (filter) => const _StockValuationContent(),
    );
  }
}

class _StockMovementsContent extends StatelessWidget {
  final ReportFilter filter;

  const _StockMovementsContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MovResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null || data.rows.isEmpty) {
          return const Center(child: Text('لا توجد حركات في الفترة المحددة'));
        }

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي الداخل',
                  value: data.totalIn.toStringAsFixed(2),
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الخارج',
                  value: data.totalOut.toStringAsFixed(2),
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                ),
                ReportSummaryCard(
                  title: 'عدد الحركات',
                  value: data.rows.length.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                if (data.undocumentedCount > 0)
                  ReportSummaryCard(
                    title: 'بدون مرجع!',
                    value: data.undocumentedCount.toString(),
                    icon: Icons.warning,
                    color: Colors.red,
                  ),
              ],
            ),
            // Warning for undocumented movements
            if (data.undocumentedCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تحذير: حركات بدون مرجع!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            Text(
                              'يوجد ${data.undocumentedCount} حركة بدون مستند مرجعي - هذا قد يشير إلى خلل في النظام.',
                              style: TextStyle(fontSize: 12, color: Colors.red[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.rows.length,
                itemBuilder: (context, index) {
                  final r = data.rows[index];
                  final isUndocumented = r.referenceNo.isEmpty;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isUndocumented
                          ? const BorderSide(color: Colors.red, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            r.qtyIn > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                            color: r.qtyIn > 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text('${r.productName}')),
                          if (isUndocumented)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'بدون مرجع!',
                                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المخزن: ${r.warehouseName}'),
                          Row(
                            children: [
                              Text('${r.dateLabel}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              if (r.referenceNo.isNotEmpty) ...[
                                const Text(' | '),
                                Text('المرجع: ${r.referenceNo}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ],
                          ),
                          if (r.statement.isNotEmpty)
                            Text(r.statement, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            r.qtyIn > 0 ? '+${r.qtyIn.toStringAsFixed(2)}' : '-${r.qtyOut.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: r.qtyIn > 0 ? Colors.green : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          if (r.value != 0)
                            Text(
                              '${r.value.toStringAsFixed(2)} ر.س',
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
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
      },
    );
  }

  Future<_MovResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'WHERE cm.trans_date >= ? AND cm.trans_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final rows = await db.rawQuery('''
      SELECT
        cm.trans_date,
        cm.quantity_in,
        cm.quantity_out,
        cm.cost_local_amount,
        cm.refrenc_no,
        cm.statement,
        c.name as product_name,
        s.name as stock_name
      FROM category_movs cm
      LEFT JOIN categories c ON c.id = cm.category_id
      LEFT JOIN stocks s ON s.id = cm.stock_id
      $dateFilter
      ORDER BY cm.trans_date DESC
    ''', args);

    final parsedRows = rows.map((m) {
      return _MovRow(
        transDate: (m['trans_date'] as int?) ?? 0,
        qtyIn: (m['quantity_in'] as num?)?.toDouble() ?? 0.0,
        qtyOut: (m['quantity_out'] as num?)?.toDouble() ?? 0.0,
        value: (m['cost_local_amount'] as num?)?.toDouble() ?? 0.0,
        referenceNo: ((m['refrenc_no'] as String?) ?? '').trim(),
        statement: ((m['statement'] as String?) ?? '').trim(),
        productName: (m['product_name'] as String?) ?? '',
        warehouseName: (m['stock_name'] as String?) ?? '',
      );
    }).toList();

    final totalIn = parsedRows.fold<double>(0, (s, r) => s + r.qtyIn);
    final totalOut = parsedRows.fold<double>(0, (s, r) => s + r.qtyOut);
    final undocumented = parsedRows.where((r) => r.referenceNo.isEmpty).length;

    return _MovResult(
      rows: parsedRows,
      totalIn: totalIn,
      totalOut: totalOut,
      undocumentedCount: undocumented,
    );
  }
}

class _MovResult {
  final List<_MovRow> rows;
  final double totalIn;
  final double totalOut;
  final int undocumentedCount;
  
  const _MovResult({
    required this.rows,
    required this.totalIn,
    required this.totalOut,
    required this.undocumentedCount,
  });
}


class _LowStockContent extends StatelessWidget {
  const _LowStockContent();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LowStockRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('لا توجد أصناف منخفضة'));
        }

        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'عدد الأصناف',
                  value: rows.length.toString(),
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(r.name),
                      subtitle: Text('المخزن: ${r.stockName}'),
                      trailing: Text(
                        '${r.qty.toStringAsFixed(2)} / ${r.min.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
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

  Future<List<_LowStockRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.name,
        c.quantity,
        COALESCE(c.min_stock_level, 0) as min_stock_level,
        s.name as stock_name
      FROM categories c
      LEFT JOIN stocks s ON s.id = c.stock_id
      WHERE c.is_active = 1 AND c.quantity <= COALESCE(c.min_stock_level, 0)
      ORDER BY c.name
      ''',
    );

    return rows.map((m) {
      return _LowStockRow(
        name: (m['name'] as String?) ?? '',
        qty: (m['quantity'] as num?)?.toDouble() ?? 0.0,
        min: (m['min_stock_level'] as num?)?.toDouble() ?? 0.0,
        stockName: (m['stock_name'] as String?) ?? '',
      );
    }).toList();
  }
}

class _StockValuationContent extends StatelessWidget {
  const _StockValuationContent();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ValuationRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final total = rows.fold<double>(0, (s, r) => s + r.value);
        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي القيمة بالتكلفة',
                  value: total.toStringAsFixed(2),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'عدد الأصناف',
                  value: rows.length.toString(),
                  icon: Icons.category,
                  color: Colors.blue,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(r.name),
                      subtitle: Text('المخزن: ${r.stockName} | كمية: ${r.qty.toStringAsFixed(2)}'),
                      trailing: Text(
                        r.value.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  Future<List<_ValuationRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.name,
        c.quantity,
        COALESCE(c.cost_amount, 0) as cost_amount,
        (COALESCE(c.cost_amount, 0) * COALESCE(c.quantity, 0)) as value,
        s.name as stock_name
      FROM categories c
      LEFT JOIN stocks s ON s.id = c.stock_id
      WHERE c.is_active = 1
      ORDER BY value DESC
      ''',
    );

    return rows.map((m) {
      return _ValuationRow(
        name: (m['name'] as String?) ?? '',
        qty: (m['quantity'] as num?)?.toDouble() ?? 0.0,
        value: (m['value'] as num?)?.toDouble() ?? 0.0,
        stockName: (m['stock_name'] as String?) ?? '',
      );
    }).toList();
  }
}

class _MovRow {
  final int transDate;
  final double qtyIn;
  final double qtyOut;
  final double value;
  final String referenceNo;
  final String statement;
  final String productName;
  final String warehouseName;

  const _MovRow({
    required this.transDate,
    required this.qtyIn,
    required this.qtyOut,
    required this.value,
    required this.referenceNo,
    required this.statement,
    required this.productName,
    required this.warehouseName,
  });

  String get dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(transDate * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _LowStockRow {
  final String name;
  final double qty;
  final double min;
  final String stockName;

  const _LowStockRow({
    required this.name,
    required this.qty,
    required this.min,
    required this.stockName,
  });
}

class _ValuationRow {
  final String name;
  final double qty;
  final double value;
  final String stockName;

  const _ValuationRow({
    required this.name,
    required this.qty,
    required this.value,
    required this.stockName,
  });
}


