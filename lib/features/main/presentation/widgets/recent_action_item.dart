import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class RecentActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final String date;
  final bool isIncome;

  const RecentActionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${isIncome ? '+' : '-'}$amount',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            width: 12,
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isIncome ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: isIncome ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
