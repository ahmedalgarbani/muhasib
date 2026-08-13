import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_unit_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ProductUnitsHeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const ProductUnitsHeaderWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: AppConstant.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وحدات القياس',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          TextInputField(
            controller: searchController,
            hint: 'ابحث في الوحدات...',
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}

class ProductUnitsListWidget extends StatelessWidget {
  final List<ProductUnitEntity> units;
  final ValueChanged<ProductUnitEntity> onEditUnit;
  final ValueChanged<ProductUnitEntity> onDeleteUnit;

  const ProductUnitsListWidget({
    super.key,
    required this.units,
    required this.onEditUnit,
    required this.onDeleteUnit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppConstant.defaultPadding,
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        return CustomCardContainer(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.square_foot, color: AppColors.success),
            ),
            title: Row(
              children: [
                Text(
                  unit.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    unit.short,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'معامل التحويل: ${unit.conversionFactor}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!unit.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const Text(
                      'غير نشط',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                const SizedBox(width: 8),
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
                      onEditUnit(unit);
                    } else if (value == 'delete') {
                      onDeleteUnit(unit);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
