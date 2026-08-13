import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

/// Standalone Journal Entry Item Card for the journal entries list page.
class JournalEntryCardWidget extends StatelessWidget {
  final JournalEntryEntity entry;
  final intl.NumberFormat numberFormat;
  final VoidCallback onTap;

  const JournalEntryCardWidget({
    super.key,
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
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        child: Padding(
          padding: AppConstant.defaultPadding,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm10),
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
                  JournalEntryStatusBadge(isPosted: entry.isPosted),
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JournalEntryStatusBadge extends StatelessWidget {
  final bool isPosted;

  const JournalEntryStatusBadge({super.key, required this.isPosted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPosted ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg20),
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
