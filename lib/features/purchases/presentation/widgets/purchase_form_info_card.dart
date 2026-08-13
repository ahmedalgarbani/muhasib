import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class PurchaseFormInfoCard extends StatelessWidget {
  final TextEditingController numberController;
  final TextEditingController dateController;
  final int paymentType;
  final ValueChanged<int> onPaymentTypeChanged;
  final VoidCallback onSelectDate;

  const PurchaseFormInfoCard({
    super.key,
    required this.numberController,
    required this.dateController,
    required this.paymentType,
    required this.onPaymentTypeChanged,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الفاتورة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    label: 'رقم الفاتورة',
                    controller: numberController,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.tag, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'رقم الفاتورة مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    label: 'التاريخ',
                    controller: dateController,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    readOnly: true,
                    onTap: onSelectDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'التاريخ مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'نوع الدفع:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('نقدي', style: TextStyle(fontSize: 12)),
                  selected: paymentType == 0,
                  onSelected: (selected) {
                    if (selected) onPaymentTypeChanged(0);
                  },
                  selectedColor: AppColors.success.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('آجل', style: TextStyle(fontSize: 12)),
                  selected: paymentType == 1,
                  onSelected: (selected) {
                    if (selected) onPaymentTypeChanged(1);
                  },
                  selectedColor: AppColors.success.withOpacity(0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
