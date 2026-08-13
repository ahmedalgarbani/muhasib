import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';

class InvoiceTotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final bool isTotal;
  final double totalFontSize;
  final double normalFontSize;

  const InvoiceTotalRow({
    super.key,
    required this.label,
    required this.amount,
    this.color,
    this.isTotal = false,
    this.totalFontSize = 16,
    this.normalFontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = NumberFormatter.formatCurrency(amount);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? AppColors.gray900 : Colors.grey[700]),
          ),
        ),
        Text(
          amountText,
          style: TextStyle(
            fontSize: isTotal ? totalFontSize : normalFontSize,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isTotal ? AppColors.success : Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
