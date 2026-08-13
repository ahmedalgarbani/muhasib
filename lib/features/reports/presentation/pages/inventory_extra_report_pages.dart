import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:intl/intl.dart';
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

class _StockMovementsContent extends StatelessWidget {
  final ReportFilter filter;
  final Function(_MovResult) onLoad;
  const _StockMovementsContent({required this.filter, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MovResult>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(data));
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
                      side: BorderSide(color: Colors.grey[100]!),
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
    final rows = await db.rawQuery(
      'SELECT cm.trans_date, cm.quantity_in, cm.quantity_out, cm.refrenc_no, c.name FROM category_movs cm JOIN categories c ON c.id = cm.category_id ORDER BY cm.trans_date DESC LIMIT 100',
    );
    final list = rows
        .map(
          (m) => _MovRow(
            transDate: m['trans_date'] as int,
            qtyIn: (m['quantity_in'] as num).toDouble(),
            qtyOut: (m['quantity_out'] as num).toDouble(),
            referenceNo: m['refrenc_no'] as String? ?? '',
            productName: m['name'] as String,
          ),
        )
        .toList();
    return _MovResult(
      rows: list,
      totalIn: list.fold(0, (s, r) => s + r.qtyIn),
      totalOut: list.fold(0, (s, r) => s + r.qtyOut),
    );
  }
}

class _LowStockContent extends StatelessWidget {
  final Function(List<_LowStockRow>) onLoad;
  const _LowStockContent({required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LowStockRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(rows));
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

class _StockValuationContent extends StatelessWidget {
  final Function(List<_ValuationRow>) onLoad;
  const _StockValuationContent({required this.onLoad});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'ar');
    return FutureBuilder<List<_ValuationRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(rows));
        return Column(
          children: [
            ReportSummaryRow(
              cards: [
                ReportSummaryCard(
                  title: 'إجمالي القيمة',
                  value: fmt.format(rows.fold(0.0, (s, r) => s + r.value)),
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
                      side: BorderSide(color: Colors.grey[100]!),
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
                        '${fmt.format(r.value)} ر.س',
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
    final rows = await db.rawQuery(
      'SELECT name, quantity, COALESCE(cost_amount, 0) * COALESCE(quantity, 0) as val FROM categories WHERE is_active = 1 AND quantity > 0 ORDER BY val DESC',
    );
    return rows
        .map(
          (m) => _ValuationRow(
            name: m['name'] as String,
            qty: (m['quantity'] as num).toDouble(),
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
    final d = DateTime.fromMillisecondsSinceEpoch(transDate * 1000);
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
