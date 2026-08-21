import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

class PurchaseDetailActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onDelete;

  const PurchaseDetailActionButtons({
    super.key,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HasibButton(
            label: 'تعديل',
            onPressed: onEdit,
            leading: const Icon(Icons.edit, size: 18),
            variant: HasibButtonVariant.primary,
            padding: const EdgeInsets.symmetric(vertical: 8),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HasibButton(
            label: 'طباعة',
            onPressed: onPrint,
            leading: const Icon(Icons.print, size: 18),
            variant: HasibButtonVariant.success,
            padding: const EdgeInsets.symmetric(vertical: 8),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HasibButton(
            label: 'حذف',
            onPressed: onDelete,
            leading: const Icon(Icons.delete, size: 18),
            variant: HasibButtonVariant.danger,
            padding: const EdgeInsets.symmetric(vertical: 8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
