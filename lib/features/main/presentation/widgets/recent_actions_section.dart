import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_detail_old.dart';
import 'package:muhasib/features/main/presentation/widgets/recent_action_item.dart';

class RecentActionsSection extends StatelessWidget {
  const RecentActionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Flexible(
                child: Text(
                  'آخر العمليات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const RecentActionItem(
            icon: Icons.shopping_cart,
            title: 'فاتورة مبيعات #1234',
            amount: '2,450.00',
            date: 'منذ ساعتين',
            isIncome: true,
          ),
          const RecentActionItem(
            icon: Icons.shopping_bag,
            title: 'فاتورة شراء #5678',
            amount: '1,820.50',
            date: 'منذ 4 ساعات',
            isIncome: false,
          ),
          const RecentActionItem(
            icon: Icons.account_balance_wallet,
            title: 'تحويل بين الحسابات',
            amount: '5,000.00',
            date: 'اليوم',
            isIncome: true,
          ),
          const RecentActionItem(
            icon: Icons.description,
            title: 'سند قبض #9012',
            amount: '3,200.00',
            date: 'أمس',
            isIncome: true,
          ),
          const RecentActionItem(
            icon: Icons.people,
            title: 'دفعة من زبون',
            amount: '8,750.00',
            date: 'منذ يومين',
            isIncome: true,
          ),
        ],
      ),
    );
  }
}
