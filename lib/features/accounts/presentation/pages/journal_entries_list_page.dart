import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/accounts/presentation/widgets/journal_entry_card_widget.dart';
import 'package:muhasib/features/accounts/presentation/widgets/journal_entry_details_sheet.dart';

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
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'دفتر القيود اليومية',
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
              return const EmptyStateWidget(
                title: 'لا توجد قيود مسجلة بعد',
                subtitle: 'ابدأ بإضافة أول قيد محاسبي لك الآن.',
                icon: Icons.assignment_late_outlined,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<JournalEntryCubit>().loadEntries(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return JournalEntryCardWidget(
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg20))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('طباعة وتصدير قيود اليومية', style: AppTextStyles.titleMedium),
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

  void _showEntryDetails(BuildContext context, JournalEntryEntity entry, intl.NumberFormat numberFormat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JournalEntryDetailsSheet(entry: entry, numberFormat: numberFormat),
    );
  }
}
