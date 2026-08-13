import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import '../../domain/entities/currency_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class CurrenciesListWidget extends StatelessWidget {
  const CurrenciesListWidget({
    super.key,
    required this.currencies,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CurrencyEntity> currencies;
  final ValueChanged<CurrencyEntity> onEdit;
  final ValueChanged<CurrencyEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (currencies.isEmpty)
      return const Center(child: Text('لا توجد عملات مضافة'));
    return ListView.builder(
      padding: AppConstant.defaultPadding,
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        return CustomCardContainer(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: currency.isLocalCurrency
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                currency.symbol ?? currency.code,
                style: TextStyle(
                  color: currency.isLocalCurrency
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  currency.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (currency.isLocalCurrency) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const Text(
                      'محلية',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'الكود: ${currency.code} | سعر الصرف: ${currency.exchangeRate}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => onEdit(currency),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(currency),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
