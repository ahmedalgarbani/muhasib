import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_detail_old.dart';
import 'package:muhasib/features/main/presentation/cubit/main_cubit.dart';
import 'package:muhasib/features/main/presentation/widgets/recent_action_item.dart';

class RecentActionsSection extends StatelessWidget {
  final List<RecentTransactionEntity> transactions;

  const RecentActionsSection({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountTransactionPage(),
                    ),
                  );
                },
                child: const Text('عرض الكل', style: TextStyle(fontSize: 12)),
              ),
              const Flexible(
                child: Text(
                  'آخر العمليات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد عمليات مسجلة حتى الآن',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...transactions.map(
              (tx) => RecentActionItem(
                icon: tx.icon,
                title: tx.title,
                amount: tx.amount,
                date: tx.date,
                isIncome: tx.isIncome,
              ),
            ),
        ],
      ),
    );
  }
}
