import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/accounts/data/models/account_model.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_movements_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_movements_state.dart';

class AccountMovementsDialog extends StatelessWidget {
  final AccountModel account;

  const AccountMovementsDialog({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AccountMovementsCubit>()..loadMovements(account.id ?? 0),
      child: _AccountMovementsContent(account: account),
    );
  }
}

class _AccountMovementsContent extends StatelessWidget {
  final AccountModel account;

  const _AccountMovementsContent({required this.account});

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final cubit = context.read<AccountMovementsCubit>();
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: cubit.startDate,
        end: cubit.endDate,
      ),
      locale: const Locale('ar'),
    );
    
    if (picked != null) {
      cubit.updateDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    double baseFont = isTablet ? 16 : 12;
    double padding = isTablet ? 20 : 12;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 100 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            /// ------------------- HEADER -------------------
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
              ),
              padding: EdgeInsets.all(padding * 1.5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حركات الحساب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: baseFont * 1.6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${account.name} - ${account.code}',
                          style: TextStyle(
                            color: AppColors.blue200,
                            fontSize: baseFont * 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    tooltip: 'تصفية حسب التاريخ',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: isTablet ? 28 : 24,
                  ),
                ],
              ),
            ),

            // Date range display
            BlocBuilder<AccountMovementsCubit, AccountMovementsState>(
              builder: (context, state) {
                if (state is AccountMovementsLoaded) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'من ${formatDate(state.startDate)} إلى ${formatDate(state.endDate)}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.read<AccountMovementsCubit>().refresh(),
                          child: const Text('تحديث'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            /// ------------------- BODY -------------------
            Expanded(
              child: BlocBuilder<AccountMovementsCubit, AccountMovementsState>(
                builder: (context, state) {
                  if (state is AccountMovementsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AccountMovementsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('خطأ: ${state.message}'),
                          const SizedBox(height: 16),
                          HasibButton(
                            label: 'إعادة المحاولة',
                            onPressed: () => context.read<AccountMovementsCubit>().refresh(),
                            variant: HasibButtonVariant.primary,
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is AccountMovementsLoaded) {
                    return AccountMovementsLoadedContentWidget(
                      state: state,
                      baseFont: baseFont,
                      padding: padding,
                    );
                  }

                  return const Center(child: Text('لا توجد بيانات'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountMovementsLoadedContentWidget extends StatelessWidget {
  final AccountMovementsLoaded state;
  final double baseFont;
  final double padding;

  const AccountMovementsLoadedContentWidget({
    super.key,
    required this.state,
    required this.baseFont,
    required this.padding,
  });

  String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'ar_SA');
    return formatter.format(number);
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final movements = state.movements;
    final summary = state.summary;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding * 1.5),
      child: Column(
        children: [
          /// --------- STAT CARDS ----------
          LayoutBuilder(
            builder: (context, c) {
              bool isNarrow = c.maxWidth < 600;
              return isNarrow
                  ? Column(
                      children: [
                        _StatCard(
                          title: 'إجمالي ${SettingsCache.debitLabel}',
                          value: formatNumber(summary.totalDebit),
                          color: Colors.green,
                          fontSize: baseFont,
                        ),
                        const SizedBox(height: 10),
                        _StatCard(
                          title: 'إجمالي ${SettingsCache.creditLabel}',
                          value: formatNumber(summary.totalCredit),
                          color: Colors.red,
                          fontSize: baseFont,
                        ),
                        const SizedBox(height: 10),
                        _StatCard(
                          title: 'الرصيد',
                          value: formatNumber(summary.netBalance),
                          color: Colors.blue,
                          fontSize: baseFont,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'إجمالي ${SettingsCache.debitLabel}',
                            value: formatNumber(summary.totalDebit),
                            color: Colors.green,
                            fontSize: baseFont,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'إجمالي ${SettingsCache.creditLabel}',
                            value: formatNumber(summary.totalCredit),
                            color: Colors.red,
                            fontSize: baseFont,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'الرصيد',
                            value: formatNumber(summary.netBalance),
                            color: Colors.blue,
                            fontSize: baseFont,
                          ),
                        ),
                      ],
                    );
            },
          ),

          SizedBox(height: padding * 1.5),

          /// ---------------- TABLE ----------------
          if (movements.isEmpty)
            Container(
              padding: EdgeInsets.all(padding * 2),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد حركات في الفترة المحددة',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: baseFont * 1.1,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 600),
                  child: Table(
                    border: TableBorder.all(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(2.5),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1.2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        children: [
                          _TableHeader('التاريخ'),
                          _TableHeader('البيان'),
                          _TableHeader(SettingsCache.debitLabel),
                          _TableHeader(SettingsCache.creditLabel),
                          _TableHeader('الرصيد'),
                        ],
                      ),
                      ...movements.map((m) {
                        return TableRow(
                          children: [
                            _TableCell(formatDate(m.entryDate)),
                            _TableCell(
                              '${m.description}\n${m.reference}',
                            ),
                            _TableCell(
                              m.debitAmount > 0 ? formatNumber(m.debitAmount) : '-',
                              color: m.debitAmount > 0 ? Colors.green : Colors.grey,
                            ),
                            _TableCell(
                              m.creditAmount > 0 ? formatNumber(m.creditAmount) : '-',
                              color: m.creditAmount > 0 ? Colors.red : Colors.grey,
                            ),
                            _TableCell(
                              formatNumber(m.balance),
                              color: m.balance >= 0 ? Colors.blue : Colors.red,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ------------------- STAT CARD -------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final double fontSize;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(fontSize * 1.2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey, fontSize: fontSize),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: fontSize * 1.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------- TABLE HEADER -------------------
class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// ------------------- TABLE CELL -------------------
class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;

  const _TableCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
