import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

/// Standalone Warehouse Card Widget for displaying warehouse details.
class WarehouseCardWidget extends StatelessWidget {
  final WarehouseEntity warehouse;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onSetMain;
  final VoidCallback onDelete;

  const WarehouseCardWidget({
    super.key,
    required this.warehouse,
    required this.onTap,
    required this.onEdit,
    this.onSetMain,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: warehouse.isMainStock
                          ? AppColors.materialBlue700.withValues(alpha: 0.1)
                          : AppColors.materialTeal600.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      warehouse.isMainStock ? Icons.home_work : Icons.warehouse,
                      color: warehouse.isMainStock
                          ? AppColors.materialBlue700
                          : AppColors.materialTeal600,
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
                                warehouse.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (warehouse.isMainStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.materialBlue700,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
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
                              warehouse.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: warehouse.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              warehouse.isActive ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                color: warehouse.isActive
                                    ? Colors.green
                                    : Colors.grey,
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
                      if (!warehouse.isMainStock && onSetMain != null)
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
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      warehouse.address,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (warehouse.managerName != null &&
                  warehouse.managerName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'المدير: ${warehouse.managerName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
              if (warehouse.capacity != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storage, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'السعة: ${warehouse.capacity} م³',
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
