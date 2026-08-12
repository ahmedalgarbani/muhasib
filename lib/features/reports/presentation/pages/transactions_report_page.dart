import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/transactions_report_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/transactions_report_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class TransactionsReportPage extends StatefulWidget {
  const TransactionsReportPage({super.key});
  @override
  State<TransactionsReportPage> createState() => _TransactionsReportPageState();
}

class _TransactionsReportPageState extends State<TransactionsReportPage> {
  TransactionsReportLoaded? _lastState;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TransactionsReportCubit>()..loadTransactions(),
      child: BlocConsumer<TransactionsReportCubit, TransactionsReportState>(
        listener: (context, state) {
          if (state is TransactionsReportLoaded) setState(() => _lastState = state);
        },
        builder: (context, state) {
          return ReportBasePage(
            title: 'سجل الحركات المالية العام',
            icon: Icons.sync_alt,
            color: AppColors.materialBlue700,
            onPrint: _lastState == null ? null : () => _exportPdf(),
            onExportExcel: _lastState == null ? null : () => _exportExcel(),
            reportBuilder: (filter) => _TransactionsReportContent(filter: filter),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastState == null) return;
    final headers = ['الرقم المرجعي', 'التاريخ', 'الوصف', 'مدين', 'دائن', 'المبلغ', 'النوع'];
    final data = _lastState!.transactions.map((t) => [
      t.reference,
      '${t.date.day}/${t.date.month}/${t.date.year}',
      t.description,
      t.details.firstWhere((d) => d.debitAmount > 0, orElse: () => t.details.first).accountName,
      t.details.firstWhere((d) => d.creditAmount > 0, orElse: () => t.details.first).accountName,
      t.totalAmount.toStringAsFixed(2),
      _getTypeLabel(t.transactionType),
    ]).toList();
    await ExportService.printData(title: 'سجل الحركات العامة', headers: headers, data: data);
  }

  Future<void> _exportExcel() async {
    if (_lastState == null) return;
    final headers = ['المرجع', 'التاريخ', 'الوصف', 'الحساب المدين', 'الحساب الدائن', 'المبلغ', 'النوع'];
    final data = _lastState!.transactions.map((t) => [
      t.reference, '${t.date.day}/${t.date.month}/${t.date.year}', t.description,
      t.details.firstWhere((d) => d.debitAmount > 0, orElse: () => t.details.first).accountName,
      t.details.firstWhere((d) => d.creditAmount > 0, orElse: () => t.details.first).accountName,
      t.totalAmount.toStringAsFixed(2), _getTypeLabel(t.transactionType),
    ]).toList();
    await ExportService.exportToExcel(fileName: 'transactions_log', headers: headers, data: data);
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sales': return 'مبيعات';
      case 'purchase': return 'مشتريات';
      case 'journal': return 'قيد يومية';
      case 'receipt': return 'قبض';
      case 'payment': return 'صرف';
      case 'opening': return 'افتتاحي';
      default: return 'أخرى';
    }
  }
}

class _TransactionsReportContent extends StatefulWidget {
  final ReportFilter filter;
  const _TransactionsReportContent({required this.filter});
  @override
  State<_TransactionsReportContent> createState() => _TransactionsReportContentState();
}

class _TransactionsReportContentState extends State<_TransactionsReportContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsReportCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_TransactionsReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) context.read<TransactionsReportCubit>().updateDateRange(widget.filter);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsReportCubit, TransactionsReportState>(
      builder: (context, state) {
        if (state is TransactionsReportLoading) return const Center(child: CircularProgressIndicator());
        if (state is TransactionsReportError) return Center(child: Text('خطأ: ${state.message}'));
        if (state is TransactionsReportLoaded) {
          final t = state.transactions;
          final d = state.summary['totalDebit'] ?? 0.0;
          final c = state.summary['totalCredit'] ?? 0.0;

          return Column(
            children: [
              ReportSummaryRow(cards: [
                ReportSummaryCard(title: 'إجمالي مدين', value: '${d.toStringAsFixed(0)} ر.س', icon: Icons.arrow_upward, color: Colors.green),
                ReportSummaryCard(title: 'إجمالي دائن', value: '${c.toStringAsFixed(0)} ر.س', icon: Icons.arrow_downward, color: Colors.red),
                ReportSummaryCard(title: 'العدد', value: t.length.toString(), icon: Icons.sync, color: Colors.blue),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: t.length,
                  itemBuilder: (context, index) => _buildTransactionItem(t[index]),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTransactionItem(dynamic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t.reference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)), Text('${t.date.day}/${t.date.month}/${t.date.year}', style: TextStyle(color: Colors.grey[600], fontSize: 11))])),
          ListTile(title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text('نوع الحركة: ${_getTypeLabel(t.transactionType)}', style: const TextStyle(fontSize: 11)), trailing: Text('${t.totalAmount.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [Icon(Icons.circle, size: 8, color: Colors.green[300]), const SizedBox(width: 8), Text(t.details.firstWhere((d) => d.debitAmount > 0, orElse: () => t.details.first).accountName, style: TextStyle(fontSize: 11, color: Colors.grey[700])), const Spacer(), Icon(Icons.circle, size: 8, color: Colors.red[300]), const SizedBox(width: 8), Text(t.details.firstWhere((d) => d.creditAmount > 0, orElse: () => t.details.first).accountName, style: TextStyle(fontSize: 11, color: Colors.grey[700]))])),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sales': return 'مبيعات';
      case 'purchase': return 'مشتريات';
      case 'journal': return 'قيد يومية';
      case 'receipt': return 'قبض';
      case 'payment': return 'صرف';
      case 'opening': return 'افتتاحي';
      default: return 'أخرى';
    }
  }
}
