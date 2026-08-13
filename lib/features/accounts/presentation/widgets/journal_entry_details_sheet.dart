import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

/// Bottom Sheet Widget for displaying detailed journal entry lines & summary.
class JournalEntryDetailsSheet extends StatelessWidget {
  final JournalEntryEntity entry;
  final intl.NumberFormat numberFormat;

  const JournalEntryDetailsSheet({
    super.key,
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl30),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'تفاصيل القيد المحاسبي',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
                    JournalEntryInfoGrid(entry: entry),
                    const SizedBox(height: 32),
                    const Text(
                      'الأسطر المحاسبية',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...entry.lines.map(
                      (line) => JournalEntryLineCard(
                        line: line,
                        numberFormat: numberFormat,
                      ),
                    ),
                    const SizedBox(height: 24),
                    JournalEntryDetailedSummary(
                      entry: entry,
                      numberFormat: numberFormat,
                    ),
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
}

class JournalEntryInfoGrid extends StatelessWidget {
  final JournalEntryEntity entry;

  const JournalEntryInfoGrid({super.key, required this.entry});

  @override
  Widget build(BuildContext context) => Wrap(
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

class JournalEntryLineCard extends StatelessWidget {
  final JournalEntryLineEntity line;
  final intl.NumberFormat numberFormat;

  const JournalEntryLineCard({
    super.key,
    required this.line,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) => CustomCardContainer(
    margin: const EdgeInsets.only(bottom: 12),
    padding: AppConstant.defaultPadding,
    backgroundColor: AppColors.slate100.withValues(alpha: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.accountName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
            _LineAmount(
              label: SettingsCache.debitLabel,
              amount: numberFormat.format(line.debit),
              isDebit: true,
            ),
            const Spacer(),
            _LineAmount(
              label: SettingsCache.creditLabel,
              amount: numberFormat.format(line.credit),
              isDebit: false,
            ),
          ],
        ),
        if (line.notes != null && line.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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

class JournalEntryDetailedSummary extends StatelessWidget {
  final JournalEntryEntity entry;
  final intl.NumberFormat numberFormat;

  const JournalEntryDetailedSummary({
    super.key,
    required this.entry,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) => CustomCardContainer(
    padding: const EdgeInsets.all(20),
    backgroundColor: AppColors.primary.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg20),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
    ),
    child: Column(
      children: [
        _SummaryRow(
          label: 'إجمالي ${SettingsCache.debitLabel}',
          value: numberFormat.format(entry.totalDebit),
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'إجمالي ${SettingsCache.creditLabel}',
          value: numberFormat.format(entry.totalCredit),
          color: Colors.red,
        ),
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

class _LineAmount extends StatelessWidget {
  final String label;
  final String amount;
  final bool isDebit;

  const _LineAmount({
    required this.label,
    required this.amount,
    required this.isDebit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isDebit
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
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

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color ?? Theme.of(context).colorScheme.onSurface,
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
