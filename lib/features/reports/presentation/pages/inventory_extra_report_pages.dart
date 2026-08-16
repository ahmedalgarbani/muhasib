import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

import 'package:muhasib/core/constant/app_constant.dart';

class StockMovementReportPage extends StatefulWidget {
  const StockMovementReportPage({super.key});
  @override
  State<StockMovementReportPage> createState() =>
      _StockMovementReportPageState();
}

class _StockMovementReportPageState extends State<StockMovementReportPage> {
  _MovResult? _lastResult;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير حركة المخزون',
      icon: Icons.swap_horiz,
      color: AppColors.materialGreen700,
      onPrint: _lastResult == null
          ? null
          : () => ExportService.printData(
              title: 'حركة المخزون',
              headers: ['التاريخ', 'الصنف', 'داخل', 'خارج', 'المرجع'],
              data: _lastResult!.rows
                  .map(
                    (r) => [
                      r.dateLabel,
                      r.productName,
                      r.qtyIn.toString(),
                      r.qtyOut.toString(),
                      r.referenceNo,
                    ],
                  )
                  .toList(),
            ),
      onExportExcel: _lastResult == null
          ? null
          : () => ExportService.exportToExcel(
              fileName: 'stock_movements',
              headers: [
                'التاريخ',
                'الصنف',
                'كمية داخلة',
                'كمية خارجة',
                'رقم المرجع',
              ],
              data: _lastResult!.rows
                  .map(
                    (r) => [
                      r.dateLabel,
                      r.productName,
                      r.qtyIn.toString(),
                      r.qtyOut.toString(),
                      r.referenceNo,
                    ],
                  )
                  .toList(),
            ),
      reportBuilder: (filter) => _StockMovementsContent(
        filter: filter,
        onLoad: (r) => setState(() => _lastResult = r),
      ),
    );
  }
}

class LowStockReportPage extends StatefulWidget {
  const LowStockReportPage({super.key});
  @override
  State<LowStockReportPage> createState() => _LowStockReportPageState();
}

class _LowStockReportPageState extends State<LowStockReportPage> {
  List<_LowStockRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تنبيه نقص المخزون',
      icon: Icons.warning_amber,
      color: AppColors.materialOrange500,
      showDateFilter: false,
      onPrint: _lastRows == null
          ? null
          : () => ExportService.printData(
              title: 'نواقص المخزون',
              headers: ['الصنف', 'الكمية الحالية', 'حد الطلب'],
              data: _lastRows!
                  .map((r) => [r.name, r.qty.toString(), r.min.toString()])
                  .toList(),
            ),
      reportBuilder: (_) =>
          _LowStockContent(onLoad: (r) => setState(() => _lastRows = r)),
    );
  }
}

class StockValuationReportPage extends StatefulWidget {
  const StockValuationReportPage({super.key});
  @override
  State<StockValuationReportPage> createState() =>
      _StockValuationReportPageState();
}

class _StockValuationReportPageState extends State<StockValuationReportPage> {
  List<_ValuationRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير تقييم المخزون',
      icon: Icons.account_balance_wallet,
      color: AppColors.materialPurple700,
      showDateFilter: false,
      onPrint: _lastRows == null
          ? null
          : () => ExportService.printData(
              title: 'تقييم المخزون',
              headers: ['الصنف', 'الكمية', 'القيمة المقدرة'],
              data: _lastRows!
                  .map(
                    (r) => [
                      r.name,
                      r.qty.toString(),
                      r.value.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
      onExportExcel: _lastRows == null
          ? null
          : () => ExportService.exportToExcel(
              fileName: 'stock_valuation',
              headers: [
                'اسم الصنف',
                'الكمية الحالية',
                'قيمة التكلفة الإجمالية',
              ],
              data: _lastRows!
                  .map(
                    (r) => [
                      r.name,
                      r.qty.toString(),
                      r.value.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
      reportBuilder: (_) =>
          _StockValuationContent(onLoad: (r) => setState(() => _lastRows = r)),
    );
  }
}

class _StockMovementsContent extends StatefulWidget {
  final ReportFilter filter;
  final Function(_MovResult) onLoad;
  const _StockMovementsContent({required this.filter, required this.onLoad});

  @override
  State<_StockMovementsContent> createState() => _StockMovementsContentState();
}

class _StockMovementsContentState extends State<_StockMovementsContent> {
  late Future<_MovResult> _future;
  _MovResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _StockMovementsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MovResult>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data != _notifiedResult) {
          _notifiedResult = data;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(data),
          );
        }
        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي الداخل',
                  value: data.totalIn.toInt().toString(),
                  icon: Icons.login,
                  color: Colors.green,
                ),
                ReportSummaryCard(
                  title: 'إجمالي الخارج',
                  value: data.totalOut.toInt().toString(),
                  icon: Icons.logout,
                  color: Colors.red,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: AppConstant.defaultPadding,
                itemCount: data.rows.length,
                itemBuilder: (context, index) {
                  final r = data.rows[index];
                  return CustomCardContainer(
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        r.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${r.dateLabel} | مرجع: ${r.referenceNo}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Text(
                        r.qtyIn > 0
                            ? '+${r.qtyIn.toInt()}'
                            : '-${r.qtyOut.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: r.qtyIn > 0 ? Colors.green : Colors.red,
                          fontSize: 16,
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

  Future<_MovResult> _load() async {
    final db = await getIt<DatabaseService>().database;
    final List<_MovRow> list = [];

    try {
      // 1. Query stock_movements table
      final smRows = await db.rawQuery('''
        SELECT sm.creation_time as trans_date, 
               CASE WHEN sm.quantity > 0 THEN sm.quantity ELSE 0 END as quantity_in,
               CASE WHEN sm.quantity < 0 THEN -sm.quantity ELSE 0 END as quantity_out,
               COALESCE(sm.reference_number, sm.reference_type, '') as refrenc_no,
               c.name 
        FROM stock_movements sm 
        JOIN categories c ON c.id = sm.product_id 
        ORDER BY sm.creation_time DESC LIMIT 100
      ''');

      for (final m in smRows) {
        list.add(
          _MovRow(
            transDate: m['trans_date'] as int,
            qtyIn: (m['quantity_in'] as num).toDouble(),
            qtyOut: (m['quantity_out'] as num).toDouble(),
            referenceNo: m['refrenc_no'] as String? ?? '',
            productName: m['name'] as String,
          ),
        );
      }
    } catch (_) {}

    // 2. Query legacy category_movs table if stock_movements has few or no records
    if (list.isEmpty) {
      try {
        final rows = await db.rawQuery(
          'SELECT cm.trans_date, cm.quantity_in, cm.quantity_out, cm.refrenc_no, c.name FROM category_movs cm JOIN categories c ON c.id = cm.category_id ORDER BY cm.trans_date DESC LIMIT 100',
        );
        for (final m in rows) {
          list.add(
            _MovRow(
              transDate: m['trans_date'] as int,
              qtyIn: (m['quantity_in'] as num).toDouble(),
              qtyOut: (m['quantity_out'] as num).toDouble(),
              referenceNo: m['refrenc_no'] as String? ?? '',
              productName: m['name'] as String,
            ),
          );
        }
      } catch (_) {}
    }

    return _MovResult(
      rows: list,
      totalIn: list.fold(0, (s, r) => s + r.qtyIn),
      totalOut: list.fold(0, (s, r) => s + r.qtyOut),
    );
  }
}

class _LowStockContent extends StatefulWidget {
  final Function(List<_LowStockRow>) onLoad;
  const _LowStockContent({required this.onLoad});

  @override
  State<_LowStockContent> createState() => _LowStockContentState();
}

class _LowStockContentState extends State<_LowStockContent> {
  late Future<List<_LowStockRow>> _future;
  List<_LowStockRow>? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LowStockRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows != _notifiedResult) {
          _notifiedResult = rows;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(rows),
          );
        }
        return ListView.builder(
          padding: AppConstant.defaultPadding,
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final r = rows[index];
            return CustomCardContainer(
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: const BorderSide(color: AppColors.orange500Alpha),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  r.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  'حد الطلب: ${r.min}',
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: Text(
                  '${r.qty}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_LowStockRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery(
      'SELECT name, quantity, COALESCE(min_stock_level, 0) as ms FROM categories WHERE is_active = 1 AND quantity <= COALESCE(min_stock_level, 0)',
    );
    return rows
        .map(
          (m) => _LowStockRow(
            name: m['name'] as String,
            qty: (m['quantity'] as num).toDouble(),
            min: (m['ms'] as num).toDouble(),
          ),
        )
        .toList();
  }
}

class _StockValuationContent extends StatefulWidget {
  final Function(List<_ValuationRow>) onLoad;
  const _StockValuationContent({required this.onLoad});

  @override
  State<_StockValuationContent> createState() => _StockValuationContentState();
}

class _StockValuationContentState extends State<_StockValuationContent> {
  late Future<List<_ValuationRow>> _future;
  List<_ValuationRow>? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ValuationRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows != _notifiedResult) {
          _notifiedResult = rows;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(rows),
          );
        }
        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي القيمة',
                  value: NumberFormatter.formatNumber(
                    rows.fold(0.0, (s, r) => s + r.value),
                  ),
                  icon: Icons.account_balance_wallet,
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        r.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'الكمية: ${r.qty}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Text(
                        NumberFormatter.formatCurrency(r.value, symbol: 'ر.س'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                          fontSize: 14,
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

  Future<List<_ValuationRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.name, 
             COALESCE((SELECT SUM(ws.quantity) FROM warehouse_stocks ws WHERE ws.product_id = c.id), c.quantity, 0) as total_qty,
             COALESCE((SELECT SUM(ws.quantity * CASE WHEN ws.avg_cost > 0 THEN ws.avg_cost ELSE COALESCE(c.cost_amount, 0) END) FROM warehouse_stocks ws WHERE ws.product_id = c.id), COALESCE(c.cost_amount, 0) * COALESCE(c.quantity, 0), 0) as val 
      FROM categories c 
      WHERE c.is_active = 1 
      GROUP BY c.id 
      HAVING total_qty > 0 OR val > 0 
      ORDER BY val DESC
    ''');
    return rows
        .map(
          (m) => _ValuationRow(
            name: m['name'] as String,
            qty: (m['total_qty'] as num).toDouble(),
            value: (m['val'] as num).toDouble(),
          ),
        )
        .toList();
  }
}

class _MovRow {
  final int transDate;
  final double qtyIn, qtyOut;
  final String referenceNo, productName;
  _MovRow({
    required this.transDate,
    required this.qtyIn,
    required this.qtyOut,
    required this.referenceNo,
    required this.productName,
  });
  String get dateLabel {
    final d = dateTimeFromReportTimestamp(transDate);
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _MovResult {
  final List<_MovRow> rows;
  final double totalIn, totalOut;
  _MovResult({
    required this.rows,
    required this.totalIn,
    required this.totalOut,
  });
}

class _LowStockRow {
  final String name;
  final double qty, min;
  _LowStockRow({required this.name, required this.qty, required this.min});
}

class _ValuationRow {
  final String name;
  final double qty, value;
  _ValuationRow({required this.name, required this.qty, required this.value});
}
