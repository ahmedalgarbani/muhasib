import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/helpers/formatters.dart';

class ItemCard extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.gray900, height: 1.5)),
                      const SizedBox(height: 4),
                      Text(
                        SettingsCache.showCostInInvoice &&
                                item.costPrice != null
                            ? '${NumberFormatter.formatCurrency(item.price)} × ${item.quantity} = ${NumberFormatter.formatCurrency(item.total)} | التكلفة: ${NumberFormatter.formatCurrency(item.costPrice!)}'
                            : '${NumberFormatter.formatCurrency(item.price)} × ${item.quantity} = ${NumberFormatter.formatCurrency(item.total)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.gray600, height: 1.4),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onPressed: onDecrement,
                  isPrimary: false,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900, height: 1.4).copyWith(fontSize: 24),
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onPressed: onIncrement,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.grey900,
          size: 24,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
