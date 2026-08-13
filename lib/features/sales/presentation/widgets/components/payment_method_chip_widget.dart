import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';

class PaymentMethodChipWidget extends StatelessWidget {
  final PaymentMethod method;
  final String label;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const PaymentMethodChipWidget({
    super.key,
    required this.method,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
    );
  }
}
