import 'package:flutter/material.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_transactions_page.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_balance_row.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_card_divider.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_card_header.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// Card widget for sub/leaf accounts
class SubCardAccount extends StatelessWidget {
  final AccountEntity account;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const SubCardAccount({
    super.key,
    required this.account,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountTransactionsPage(account: account),
          ),
        );
      },
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
            // Header with icon, name, code, and badge
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
          ],
        ),
      ),
    );
  }
}
