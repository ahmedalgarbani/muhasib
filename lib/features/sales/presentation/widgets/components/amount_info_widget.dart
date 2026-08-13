import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';

class AmountInfoWidget extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const AmountInfoWidget({
    super.key,
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: AppColors.gray600,
            height: 1.4,
          ),
        ),
        Text(
          NumberFormatter.formatNumber(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: AppColors.gray900,
            height: 1.5,
          ).copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
