import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';

class InvoiceSummaryRowWidget extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;
  final Color? color;

  const InvoiceSummaryRowWidget({
    super.key,
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? AppColors.success : null),
            ),
          ),
        ],
      ),
    );
  }
}
