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

class CustomerBalancesReportPage extends StatefulWidget {
  const CustomerBalancesReportPage({super.key});
  @override
  State<CustomerBalancesReportPage> createState() => _CustomerBalancesReportPageState();
}

class _CustomerBalancesReportPageState extends State<CustomerBalancesReportPage> {
  List<_PartyBalanceRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أرصدة العملاء الحالية',
      icon: Icons.people_outline,
      color: AppColors.materialGreen800,
      showDateFilter: false,
      onPrint: _lastRows == null ? null : () => ExportService.printData(title: 'أرصدة العملاء', headers: ['العميل', 'الرصيد'], data: _lastRows!.map((r) => [r.name, r.balance.toStringAsFixed(2)]).toList()),
      onExportExcel: _lastRows == null ? null : () => ExportService.exportToExcel(fileName: 'customer_balances', headers: ['الاسم', 'الرصيد الحالي'], data: _lastRows!.map((r) => [r.name, r.balance.toStringAsFixed(2)]).toList()),
      reportBuilder: (_) => _PartyBalancesContent(customerType: 1, titleLabel: 'العملاء', onLoad: (r) => setState(() => _lastRows = r)),
    );
  }
}

class SupplierBalancesReportPage extends StatefulWidget {
  const SupplierBalancesReportPage({super.key});
  @override
  State<SupplierBalancesReportPage> createState() => _SupplierBalancesReportPageState();
}

class _SupplierBalancesReportPageState extends State<SupplierBalancesReportPage> {
  List<_PartyBalanceRow>? _lastRows;
  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'أرصدة الموردين الحالية',
      icon: Icons.local_shipping_outlined,
      color: AppColors.materialBlue800,
      showDateFilter: false,
      onPrint: _lastRows == null ? null : () => ExportService.printData(title: 'أرصدة الموردين', headers: ['المورد', 'الرصيد'], data: _lastRows!.map((r) => [r.name, r.balance.toStringAsFixed(2)]).toList()),
      onExportExcel: _lastRows == null ? null : () => ExportService.exportToExcel(fileName: 'supplier_balances', headers: ['الاسم', 'الرصيد المستحق'], data: _lastRows!.map((r) => [r.name, r.balance.toStringAsFixed(2)]).toList()),
      reportBuilder: (_) => _PartyBalancesContent(customerType: 2, titleLabel: 'الموردين', onLoad: (r) => setState(() => _lastRows = r)),
    );
  }
}

class _PartyBalancesContent extends StatelessWidget {
  final int customerType;
  final String titleLabel;
  final Function(List<_PartyBalanceRow>) onLoad;
  const _PartyBalancesContent({required this.customerType, required this.titleLabel, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_PartyBalanceRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('خطأ: ${snapshot.error}'));
        final rows = snapshot.data ?? [];
        if (rows.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(rows));
        if (rows.isEmpty) return const Center(child: Text('لا توجد أرصدة مسجلة حالياً'));

        final total = rows.fold<double>(0, (s, r) => s + r.balance);
        final fmt = NumberFormat('#,##0.00', 'ar');

        return Column(children: [
          ReportSummaryRow(cards: [
            ReportSummaryCard(title: 'الإجمالي العام', value: fmt.format(total), icon: Icons.monetization_on, color: Colors.green),
            ReportSummaryCard(title: 'عدد $titleLabel', value: rows.length.toString(), icon: Icons.people, color: Colors.blue),
          ]),
          Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: rows.length, itemBuilder: (context, index) {
            final r = rows[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: Colors.grey[100]!)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), trailing: Text('${fmt.format(r.balance.abs())} ر.س', style: TextStyle(fontWeight: FontWeight.bold, color: r.balance >= 0 ? Colors.green[700] : Colors.red[700], fontSize: 14)), subtitle: Text(r.balance >= 0 ? 'رصيد لصالحنا' : 'رصيد مطالبات', style: TextStyle(fontSize: 10, color: Colors.grey[500]))),
            );
          })),
        ]);
      },
    );
  }

  Future<List<_PartyBalanceRow>> _load() async {
    final db = await getIt<DatabaseService>().database;
    final rows = await db.rawQuery('SELECT c.id, c.name, COALESCE(a.balance, 0) as balance FROM customers c LEFT JOIN accounts a ON a.id = c.account_id WHERE c.is_active = 1 AND c.type = ? ORDER BY ABS(balance) DESC', [customerType]);
    return rows.map((m) => _PartyBalanceRow(id: m['id'] as int, name: m['name'] as String, balance: (m['balance'] as num).toDouble())).toList();
  }
}

class _PartyBalanceRow { final int id; final String name; final double balance; _PartyBalanceRow({required this.id, required this.name, required this.balance}); }
