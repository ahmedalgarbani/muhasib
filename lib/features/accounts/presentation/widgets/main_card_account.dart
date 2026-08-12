import 'package:flutter/material.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_balance_row.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_card_divider.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_card_header.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// Card widget for master accounts with sub-accounts indicator
class MainCardAccount extends StatelessWidget {
  final AccountEntity account;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MainCardAccount({
    Key? key,
    required this.account,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, name, code, badge, and menu
            AccountCardHeader(
              account: account,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
              borderColor: borderColor,
              onEdit: onEdit,
              onDelete: onDelete,
            ),

            const SizedBox(height: 12),

            // Divider
            AccountCardDivider(color: borderColor),

            const SizedBox(height: 12),

            // Balance Row
            AccountBalanceRow(balance: account.balance),

            // Master account indicator
            if (account.isMaster) ...[
              const SizedBox(height: 12),
              AccountCardDivider(color: borderColor),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'اضغط لعرض الحسابات الفرعية',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
