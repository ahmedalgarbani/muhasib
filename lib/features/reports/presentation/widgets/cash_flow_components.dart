import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class CashFlowSectionCardWidget extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;
  final String Function(double) formatCurrency;

  const CashFlowSectionCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Text(
            '${formatCurrency(value)} ر.س',
            style: TextStyle(
              color: value >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class CashFlowFinalSummaryWidget extends StatelessWidget {
  final dynamic result;

  const CashFlowFinalSummaryWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final d = result;
    final isMatching =
        d.closingBalance.toStringAsFixed(2) ==
        d.actualCashBalance.toStringAsFixed(2);
    final diff = (d.closingBalance - d.actualCashBalance).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'التوافق مع أرصدة النقد',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            isMatching ? 'متطابق ✓' : 'فرق: ${diff.toStringAsFixed(1)}',
            style: TextStyle(
              color: isMatching ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
