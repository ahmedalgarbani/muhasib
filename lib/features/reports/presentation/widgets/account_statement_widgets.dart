import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class AccountStatementAccountSelectorWidget extends StatelessWidget {
  final int? selectedAccountId;
  final List<dynamic> accounts;
  final ValueChanged<int> onAccountSelected;

  const AccountStatementAccountSelectorWidget({
    super.key,
    required this.selectedAccountId,
    required this.accounts,
    required this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomDropdownField<int>(
        label: 'اختر الحساب المطلوب',
        value: selectedAccountId,
        prefixIcon: const Icon(Icons.account_tree),
        items: accounts
            .map(
              (a) => DropdownMenuItem<int>(
                value: a['id'] as int,
                child: Text(
                  '${a['code']} - ${a['name']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => v != null ? onAccountSelected(v) : null,
      ),
    );
  }
}

class AccountStatementSummaryItemWidget extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isBold;

  const AccountStatementSummaryItemWidget({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(left: 10),
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              NumberFormatter.formatCurrency(value, symbol: 'ر.س'),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountStatementTransactionCardWidget extends StatelessWidget {
  final dynamic transaction;

  const AccountStatementTransactionCardWidget({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  NumberFormatter.formatCurrency(t.balance, symbol: 'ر.س'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.tag, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      t.reference,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AccountStatementAmountBadgeWidget(
                  label: 'مدين: ${NumberFormatter.formatNumber(t.debitAmount)}',
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                AccountStatementAmountBadgeWidget(
                  label: 'دائن: ${NumberFormatter.formatNumber(t.creditAmount)}',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountStatementAmountBadgeWidget extends StatelessWidget {
  final String label;
  final Color color;

  const AccountStatementAmountBadgeWidget({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
