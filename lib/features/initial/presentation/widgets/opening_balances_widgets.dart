import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class OpeningBalancesHeaderWidget extends StatelessWidget {
  final DateTime selectedDate;

  const OpeningBalancesHeaderWidget({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstant.defaultPadding,
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أدخل الأرصدة الافتتاحية للحسابات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'الحساب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'مدين',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'دائن',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 100, child: Center(child: Text('المبلغ'))),
            ],
          ),
        ],
      ),
    );
  }
}

class OpeningBalancesAccountsListWidget extends StatelessWidget {
  final List<AccountEntity> accounts;
  final Map<int, TextEditingController> balanceControllers;
  final Map<int, bool> debitCreditSelection;
  final Function(int accountId, bool isDebit) onSelectionChanged;
  final VoidCallback onChanged;

  const OpeningBalancesAccountsListWidget({
    super.key,
    required this.accounts,
    required this.balanceControllers,
    required this.debitCreditSelection,
    required this.onSelectionChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        balanceControllers.putIfAbsent(
          account.id!,
          () => TextEditingController(text: '0'),
        );
        debitCreditSelection.putIfAbsent(account.id!, () => true);

        return CustomCardContainer(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${account.code} - ${account.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (account.statement != null)
                        Text(
                          account.statement!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Radio<bool>(
                    value: true,
                    groupValue: debitCreditSelection[account.id],
                    onChanged: (value) {
                      if (value != null) {
                        onSelectionChanged(account.id!, value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: Radio<bool>(
                    value: false,
                    groupValue: debitCreditSelection[account.id],
                    onChanged: (value) {
                      if (value != null) {
                        onSelectionChanged(account.id!, value);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextInputField(
                    controller: balanceControllers[account.id],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OpeningBalancesFooterWidget extends StatelessWidget {
  final Map<String, double> totals;
  final bool isBalanced;
  final bool isSaving;
  final VoidCallback onClearAll;
  final VoidCallback? onSaveBalances;

  const OpeningBalancesFooterWidget({
    super.key,
    required this.totals,
    required this.isBalanced,
    this.isSaving = false,
    required this.onClearAll,
    required this.onSaveBalances,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('إجمالي المدين'),
                  Text(
                    NumberFormat('#,##0.00').format(totals['debit']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('إجمالي الدائن'),
                  Text(
                    NumberFormat('#,##0.00').format(totals['credit']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('الفرق'),
                  Text(
                    NumberFormat(
                      '#,##0.00',
                    ).format((totals['debit']! - totals['credit']!).abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isBalanced ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isBalanced)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تحذير: المجاميع غير متوازنة! يجب أن يكون إجمالي المدين مساوياً لإجمالي الدائن',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              HasibButton(
                label: 'مسح الكل',
                onPressed: isSaving ? null : onClearAll,
                leading: const Icon(Icons.clear),
                variant: HasibButtonVariant.secondary,
              ),
              HasibButton(
                label: 'حفظ الأرصدة',
                onPressed: isBalanced && !isSaving ? onSaveBalances : null,
                leading: const Icon(Icons.save),
                loading: isSaving,
                variant: HasibButtonVariant.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
