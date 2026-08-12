import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';

/// Standalone Cashbox Card Widget for displaying cashbox details.
class CashboxCardWidget extends StatelessWidget {
  final CashboxEntity cashbox;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onSetMain;
  final VoidCallback onDelete;

  const CashboxCardWidget({
    super.key,
    required this.cashbox,
    required this.onTap,
    required this.onEdit,
    this.onSetMain,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cashbox.isMainFund
                          ? AppColors.materialBlue700.withValues(alpha: 0.1)
                          : AppColors.materialTeal600.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      cashbox.isMainFund ? Icons.account_balance_wallet : Icons.point_of_sale,
                      color: cashbox.isMainFund ? AppColors.materialBlue700 : AppColors.materialTeal600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cashbox.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (cashbox.isMainFund)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.materialBlue700,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: const Text(
                                  'رئيسي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              cashbox.isActive ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: cashbox.isActive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cashbox.isActive ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                color: cashbox.isActive ? Colors.green : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      if (!cashbox.isMainFund && onSetMain != null)
                        const PopupMenuItem(
                          value: 'setMain',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 20),
                              SizedBox(width: 8),
                              Text('تعيين كرئيسي'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'setMain' && onSetMain != null) {
                        onSetMain!();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              if (cashbox.currentBalance != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'الرصيد: ${cashbox.currentBalance?.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
