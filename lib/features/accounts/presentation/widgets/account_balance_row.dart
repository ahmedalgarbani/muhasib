import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            Icon(
              balance >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: balance >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              _formatNumber(balance),
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              currency,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'ar_SA');
    return formatter.format(number);
  }
}
