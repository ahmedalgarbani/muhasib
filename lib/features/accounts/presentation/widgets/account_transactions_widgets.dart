import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class AccountPeriodOptionWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountPeriodOptionWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class AccountTransactionItemWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final ValueChanged<Map<String, dynamic>> onTap;

  const AccountTransactionItemWidget({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      (transaction['date'] as int) * 1000,
    );
    final debit = (transaction['debit_amount'] ?? 0.0) as double;
    final credit = (transaction['credit_amount'] ?? 0.0) as double;
    final balance = (transaction['balance'] ?? 0.0) as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () => onTap(transaction),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['description'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (transaction['entry_number'] != null)
                          Text(
                            'رقم: ${transaction['entry_number']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      debit > 0 ? NumberFormatter.formatNumber(debit) : '-',
                      style: TextStyle(
                        color: debit > 0 ? Colors.red : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      credit > 0
                          ? NumberFormatter.formatNumber(credit)
                          : '-',
                      style: TextStyle(
                        color: credit > 0 ? Colors.green : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      NumberFormatter.formatNumber(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.blue : Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      DateFormatter.formatDate(date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              if (transaction['notes'] != null &&
                  transaction['notes'].toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction['notes'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountDetailRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const AccountDetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
