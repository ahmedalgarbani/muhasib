import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class TransactionItemCardWidget extends StatelessWidget {
  final dynamic transaction;

  const TransactionItemCardWidget({super.key, required this.transaction});

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sales':
        return 'مبيعات';
      case 'purchase':
        return 'مشتريات';
      case 'journal':
        return 'قيد يومية';
      case 'receipt':
        return 'قبض';
      case 'payment':
        return 'صرف';
      case 'opening':
        return 'افتتاحي';
      default:
        return 'أخرى';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  '${t.date.day}/${t.date.month}/${t.date.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(
              t.description,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              'نوع الحركة: ${_getTypeLabel(t.transactionType)}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              '${t.totalAmount.toStringAsFixed(2)} ر.س',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.blue,
              ),
            ),
          ),
          if (t.details.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.green[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.details
                              .where((d) => d.debitAmount > 0)
                              .firstOrNull
                              ?.accountName ??
                          t.details.firstOrNull?.accountName ??
                          '—',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.circle, size: 8, color: Colors.red[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.details
                              .where((d) => d.creditAmount > 0)
                              .firstOrNull
                              ?.accountName ??
                          t.details.firstOrNull?.accountName ??
                          '—',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
