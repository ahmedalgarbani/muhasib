import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_data_table.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class CustomerBalancesReportPage extends StatefulWidget {
  const CustomerBalancesReportPage({super.key});
  @override
  State<CustomerBalancesReportPage> createState() =>
      _CustomerBalancesReportPageState();
}

class _CustomerBalancesReportPageState
    extends State<CustomerBalancesReportPage> {
  List<_PartyBalanceRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أرصدة العملاء الحالية',
      icon: Icons.people_outline,
      color: AppColors.materialGreen800,
      showDateFilter: false,
      onPrint: _lastRows == null
          ? null
          : () => ExportService.printData(
              title: 'أرصدة العملاء',
              headers: ['العميل', 'الرصيد'],
              data: _lastRows!
                  .map((r) => [r.name, r.balance.toStringAsFixed(2)])
                  .toList(),
            ),
      onExportExcel: _lastRows == null
          ? null
          : () => ExportService.exportToExcel(
              fileName: 'customer_balances',
              headers: ['الاسم', 'الرصيد الحالي'],
              data: _lastRows!
                  .map((r) => [r.name, r.balance.toStringAsFixed(2)])
                  .toList(),
            ),
      reportBuilder: (filter) => _PartyBalancesContent(
        customerType: 1,
        titleLabel: 'العملاء',
        filter: filter,
        onLoad: (r) => setState(() => _lastRows = r),
      ),
    );
  }
}

class SupplierBalancesReportPage extends StatefulWidget {
  const SupplierBalancesReportPage({super.key});
  @override
  State<SupplierBalancesReportPage> createState() =>
      _SupplierBalancesReportPageState();
}

class _SupplierBalancesReportPageState
    extends State<SupplierBalancesReportPage> {
  List<_PartyBalanceRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أرصدة الموردين الحالية',
      icon: Icons.local_shipping_outlined,
      color: AppColors.materialBlue800,
      showDateFilter: false,
      onPrint: _lastRows == null
          ? null
          : () => ExportService.printData(
              title: 'أرصدة الموردين',
              headers: ['المورد', 'الرصيد'],
              data: _lastRows!
                  .map((r) => [r.name, r.balance.toStringAsFixed(2)])
                  .toList(),
            ),
      onExportExcel: _lastRows == null
          ? null
          : () => ExportService.exportToExcel(
              fileName: 'supplier_balances',
              headers: ['الاسم', 'الرصيد المستحق'],
              data: _lastRows!
                  .map((r) => [r.name, r.balance.toStringAsFixed(2)])
                  .toList(),
            ),
      reportBuilder: (filter) => _PartyBalancesContent(
        customerType: 2,
        titleLabel: 'الموردين',
        filter: filter,
        onLoad: (r) => setState(() => _lastRows = r),
      ),
    );
  }
}

class _PartyBalancesContent extends StatefulWidget {
  final int customerType;
  final String titleLabel;
  final ReportFilter filter;
  final Function(List<_PartyBalanceRow>) onLoad;

  const _PartyBalancesContent({
    required this.customerType,
    required this.titleLabel,
    required this.filter,
    required this.onLoad,
  });

  @override
  State<_PartyBalancesContent> createState() => _PartyBalancesContentState();
}

class _PartyBalancesContentState extends State<_PartyBalancesContent> {
  late Future<List<_PartyBalanceRow>> _future;
  List<_PartyBalanceRow>? _notifiedRows;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _PartyBalancesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerType != widget.customerType ||
        oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedRows = null;
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_PartyBalanceRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('خطأ: ${snapshot.error}'));
        var rows = snapshot.data ?? [];
        if (rows.isNotEmpty && rows != _notifiedRows) {
          _notifiedRows = rows;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(rows),
          );
        }

        if (widget.filter.searchQuery != null &&
            widget.filter.searchQuery!.isNotEmpty) {
          final q = widget.filter.searchQuery!.toLowerCase();
          rows = rows.where((r) => r.name.toLowerCase().contains(q)).toList();
        }

        if (rows.isEmpty)
          return const Center(child: Text('لا توجد أرصدة مسجلة حالياً'));

        final total = rows.fold<double>(0, (s, r) => s + r.balance);
        final fmt = NumberFormat('#,##0.00', 'ar');

        return SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReportKpiCard(
                      title: 'إجمالي الأرصدة القائمة',
                      value: '${fmt.format(total)} ر.س',
                      icon: Icons.monetization_on,
                      color: widget.customerType == 1
                          ? Colors.green[700]!
                          : Colors.blue[700]!,
                      subtitle: 'إجمالي الذمم المطلوبة',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReportKpiCard(
                      title: 'عدد المسجلين',
                      value: '${rows.length} ${widget.titleLabel}',
                      icon: Icons.people,
                      color: Colors.purple[700]!,
                      subtitle: 'إجمالي السجلات الحالية',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ReportDataTable<_PartyBalanceRow>(
                columns: [
                  ReportTableColumn(title: 'اسم ${widget.titleLabel}', flex: 3),
                  const ReportTableColumn(
                    title: 'حالة الرصيد',
                    flex: 2,
                    alignment: TextAlign.center,
                  ),
                  const ReportTableColumn(
                    title: 'الرصيد المستحق',
                    flex: 2,
                    alignment: TextAlign.end,
                  ),
                ],
                items: rows,
                rowBuilder: (context, r, index) => Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: r.balance >= 0
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            r.balance >= 0 ? 'رصيد لصالحنا' : 'مطالبة مالية',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: r.balance >= 0
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${fmt.format(r.balance.abs())} ر.س',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: r.balance >= 0
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
                footerRow: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'إجمالي أرصدة ${widget.titleLabel}',
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
                        '${fmt.format(total)} ر.س',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: widget.customerType == 1
                              ? Colors.green[800]
                              : Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<_PartyBalanceRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery(
      'SELECT c.id, c.name, COALESCE(a.balance, 0) as balance FROM customers c LEFT JOIN accounts a ON a.id = c.account_id WHERE c.is_active = 1 AND c.type = ? ORDER BY ABS(balance) DESC',
      [widget.customerType],
    );
    return rows
        .map(
          (m) => _PartyBalanceRow(
            id: m['id'] as int,
            name: m['name'] as String,
            balance: (m['balance'] as num).toDouble(),
          ),
        )
        .toList();
  }
}

class _PartyBalanceRow {
  final int id;
  final String name;
  final double balance;
  _PartyBalanceRow({
    required this.id,
    required this.name,
    required this.balance,
  });
}
