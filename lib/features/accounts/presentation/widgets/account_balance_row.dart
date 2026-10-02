import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';

/// Reusable widget to display account balance with formatting
class AccountBalanceRow extends StatelessWidget {
  final double balance;
  final String currency;

  const AccountBalanceRow({
    super.key,
    required this.balance,
    this.currency = 'ريال',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'الرصيد الحالي',
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  balance >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: balance >= 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  NumberFormatter.formatNumber(balance),
                  style: TextStyle(
                    color: AppColors.gray700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currency,
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
