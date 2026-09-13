import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

class TinySummaryWidget extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const TinySummaryWidget({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class WarningBannerWidget extends StatelessWidget {
  final String message;

  const WarningBannerWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(AppRadius.sm10),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalEntryCardWidget extends StatelessWidget {
  final dynamic entry;
  final String Function(double) formatCurrency;

  const JournalEntryCardWidget({
    super.key,
    required this.entry,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final isBalanced = (entry.totalDebit - entry.totalCredit).abs() < 0.01;
    return CustomCardContainer(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: entry.isPosted
                  ? AppColors.blueGrey700
                  : Colors.orange.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Text(
                  entry.number ?? '#${entry.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.description ?? 'بدون وصف',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  entry.dateLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ...entry.lines.map(
            (l) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${l.accountCode} - ${l.accountName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l.debitAmount > 0 ? formatCurrency(l.debitAmount) : '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l.creditAmount > 0
                          ? formatCurrency(l.creditAmount)
                          : '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isBalanced
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm6),
                  ),
                  child: Text(
                    isBalanced ? 'قيد متوازن ✓' : 'غير متوازن ⚠',
                    style: TextStyle(
                      color: isBalanced ? Colors.green[700] : Colors.red[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text(
                          formatCurrency(entry.totalDebit),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          formatCurrency(entry.totalCredit),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
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
