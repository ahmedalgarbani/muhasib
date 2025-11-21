import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

class ItemCard extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey200, width: 2),
          borderRadius: BorderRadius.circular(12),
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
                      Text(item.name, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormatter.formatCurrency(item.price)} �? ${item.quantity} = ${NumberFormatter.formatCurrency(item.total)}',
                        style: AppTextStyles.small,
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
                      style: AppTextStyles.title.copyWith(fontSize: 24),
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
        color: isPrimary ? AppColors.primary : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
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
