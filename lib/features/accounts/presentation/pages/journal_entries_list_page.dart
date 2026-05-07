import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';

class JournalEntriesListPage extends StatefulWidget {
  const JournalEntriesListPage({super.key});

  @override
  State<JournalEntriesListPage> createState() => _JournalEntriesListPageState();
}

class _JournalEntriesListPageState extends State<JournalEntriesListPage> {
  @override
  void initState() {
    super.initState();
    context.read<JournalEntryCubit>().loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: _JournalEntriesListBody(),
    );
  }
}

class _JournalEntriesListBody extends StatelessWidget {
  const _JournalEntriesListBody();

  @override
  Widget build(BuildContext context) {
    final numberFormat = intl.NumberFormat('#,##0.00', 'ar');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'دفتر القيود اليومية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _showExportOptions(context),
            tooltip: 'طباعة القائمة',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.accountsJournalAdd),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('قيد جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<JournalEntryCubit, JournalEntryState>(
        builder: (context, state) {
          if (state is JournalEntryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is JournalEntriesLoaded) {
            final entries = state.entries;
            if (entries.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<JournalEntryCubit>().loadEntries(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _JournalEntryListItem(
                    entry: entry,
                    numberFormat: numberFormat,
                    onTap: () => _showEntryDetails(context, entry, numberFormat),
                  );
                },
              ),
            );
          } else if (state is JournalEntryFailure) {
            return Center(child: Text('خطأ: ${state.message}'));
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final state = context.read<JournalEntryCubit>().state;
    if (state is! JournalEntriesLoaded) return;

    final entries = state.entries;
    final headers = ['رقم القيد', 'التاريخ', 'البيان', 'إجمالي المدين', 'إجمالي الدائن'];
    final data = entries.map((e) => [
      e.number,
      intl.DateFormat('yyyy/MM/dd').format(e.entryDate),
      e.description ?? '',
      e.totalDebit.toStringAsFixed(2),
      e.totalCredit.toStringAsFixed(2),
    ]).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('طباعة وتصدير قيود اليومية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('طباعة السجل (PDF)'),
                onTap: () {
                  Navigator.pop(context);
                  ExportService.printData(
                    title: 'سجل قيود اليومية المركزية',
                    headers: headers,
                    data: data,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_view, color: Colors.green),
                title: const Text('تصدير إلى Excel'),
                onTap: () {
                  Navigator.pop(context);
                  ExportService.exportToExcel(
                    fileName: 'سجل_القيود_${intl.DateFormat('yyyyMMdd').format(DateTime.now())}',
                    headers: headers,
                    data: data,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'لا توجد قيود مسجلة بعد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإضافة أول قيد محاسبي لك الآن.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(BuildContext context, JournalEntryEntity entry, intl.NumberFormat numberFormat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JournalEntryDetailsSheet(entry: entry, numberFormat: numberFormat),
    );
  }
}

class _JournalEntryListItem extends StatelessWidget {
  final JournalEntryEntity entry;
  final intl.NumberFormat numberFormat;
  final VoidCallback onTap;

  const _JournalEntryListItem({
    required this.entry,
    required this.numberFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = intl.DateFormat('yyyy/MM/dd').format(entry.entryDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      entry.number,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.description ?? 'بدون وصف',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(entry.isPosted),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  _AmountSummary(
                    label: 'إجمالي القيد',
                    amount: numberFormat.format(entry.totalDebit),
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isPosted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPosted ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPosted ? 'مرحل' : 'مسودة',
        style: TextStyle(
          color: isPosted ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _AmountSummary({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _JournalEntryDetailsSheet extends StatelessWidget {
  final JournalEntryEntity entry;
  final intl.NumberFormat numberFormat;

  const _JournalEntryDetailsSheet({
    required this.entry,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'تفاصيل القيد المحاسبي',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildInfoGrid(context),
                    const SizedBox(height: 32),
                    const Text(
                      'الأسطر المحاسبية',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...entry.lines.map((line) => _buildLineCard(line)),
                    const SizedBox(height: 24),
                    _buildDetailedSummary(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _InfoItem(label: 'رقم القيد', value: entry.number, icon: Icons.tag),
        _InfoItem(
          label: 'تاريخ القيد',
          value: intl.DateFormat('yyyy/MM/dd').format(entry.entryDate),
          icon: Icons.calendar_today,
        ),
        _InfoItem(
          label: 'الحالة',
          value: entry.isPosted ? 'مرحل ومحمي' : 'مسودة',
          icon: entry.isPosted ? Icons.lock : Icons.edit,
          color: entry.isPosted ? Colors.green : Colors.orange,
        ),
        if (entry.description != null)
          _InfoItem(
            label: 'الوصف',
            value: entry.description!,
            icon: Icons.description,
            width: double.infinity,
          ),
      ],
    );
  }

  Widget _buildLineCard(JournalEntryLineEntity line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.accountName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      line.accountCode ?? '',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _LineAmount(label: 'مدين', amount: numberFormat.format(line.debit), isDebit: true),
              const Spacer(),
              _LineAmount(label: 'دائن', amount: numberFormat.format(line.credit), isDebit: false),
            ],
          ),
          if (line.notes != null && line.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                line.notes!,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'إجمالي المدين', value: numberFormat.format(entry.totalDebit), color: Colors.green),
          const SizedBox(height: 12),
          _SummaryRow(label: 'إجمالي الدائن', value: numberFormat.format(entry.totalCredit), color: Colors.red),
          const Divider(height: 24),
          _SummaryRow(
            label: 'الفرق (التوازن)',
            value: numberFormat.format(entry.difference),
            color: entry.difference == 0 ? Colors.green : Colors.red,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _LineAmount extends StatelessWidget {
  final String label;
  final String amount;
  final bool isDebit;

  const _LineAmount({required this.label, required this.amount, required this.isDebit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isDebit ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        Text(
          amount,
          style: TextStyle(
            color: isDebit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, required this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isBold ? 18 : 16,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final double? width;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? (MediaQuery.of(context).size.width / 2) - 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
