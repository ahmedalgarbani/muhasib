import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';

import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ProductSubUnitsHeaderWidget extends StatelessWidget {
  final int? selectedProductFilter;
  final ValueChanged<int?> onProductFilterChanged;

  const ProductSubUnitsHeaderWidget({
    super.key,
    required this.selectedProductFilter,
    required this.onProductFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: AppConstant.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الوحدات الفرعية للمنتجات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              Flexible(
                child: BlocBuilder<ProductsCubit, ProductsState>(
                  builder: (context, productsState) {
                    if (productsState is ProductsLoaded) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: selectedProductFilter,
                          hint: const Text('كل المنتجات'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('كل المنتجات'),
                            ),
                            ...productsState.products.map(
                              (product) => DropdownMenuItem(
                                value: product.id,
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: onProductFilterChanged,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductSubUnitsListWidget extends StatelessWidget {
  final List<ProductSubUnitEntity> subUnits;
  final Function(ProductSubUnitEntity) onEditSubUnit;
  final Function(ProductSubUnitEntity) onDeleteSubUnit;

  const ProductSubUnitsListWidget({
    super.key,
    required this.subUnits,
    required this.onEditSubUnit,
    required this.onDeleteSubUnit,
  });

  @override
  Widget build(BuildContext context) {
    final Map<int?, List<ProductSubUnitEntity>> groupedSubUnits = {};
    for (final subUnit in subUnits) {
      if (!groupedSubUnits.containsKey(subUnit.categoryId)) {
        groupedSubUnits[subUnit.categoryId] = [];
      }
      groupedSubUnits[subUnit.categoryId]!.add(subUnit);
    }

    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, productsState) {
        return ListView.builder(
          padding: AppConstant.defaultPadding,
          itemCount: groupedSubUnits.length,
          itemBuilder: (context, index) {
            final categoryId = groupedSubUnits.keys.elementAt(index);
            final productSubUnits = groupedSubUnits[categoryId]!;

            String productName = 'منتج غير معروف';
            if (productsState is ProductsLoaded && categoryId != null) {
              try {
                final product = productsState.products.firstWhere(
                  (p) => p.id == categoryId,
                );
                productName = product.name;
              } catch (e) {
                productName = 'منتج غير معروف';
              }
            }

            return CustomCardContainer(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: AppConstant.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    ...productSubUnits.map(
                      (subUnit) => ProductSubUnitItemWidget(
                        subUnit: subUnit,
                        onEdit: () => onEditSubUnit(subUnit),
                        onDelete: () => onDeleteSubUnit(subUnit),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProductSubUnitItemWidget extends StatelessWidget {
  final ProductSubUnitEntity subUnit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductSubUnitItemWidget({
    super.key,
    required this.subUnit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
      builder: (context, unitsState) {
        String unitName = 'وحدة';
        if (unitsState is ProductUnitsLoaded && subUnit.unitId != null) {
          try {
            final unit = unitsState.units.firstWhere(
              (u) => u.id == subUnit.unitId,
            );
            unitName = unit.name;
          } catch (e) {
            unitName = 'وحدة';
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: subUnit.isMainUnit
                ? Colors.blue.shade50
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: subUnit.isMainUnit
                  ? Colors.blue.shade200
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: subUnit.isMainUnit ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${subUnit.packaging} × $unitName',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (subUnit.isMainUnit) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: const Text(
                              'رئيسية',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'معامل التحويل: ${subUnit.conversionRate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  if (!subUnit.isMainUnit)
                    const PopupMenuItem(
                      value: 'set_main',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 20),
                          SizedBox(width: 8),
                          Text('تعيين كرئيسية'),
                        ],
                      ),
                    ),
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
                  if (value == 'set_main' &&
                      subUnit.categoryId != null &&
                      subUnit.id != null) {
                    context.read<ProductSubUnitsCubit>().setMainUnit(
                          subUnit.categoryId!,
                          subUnit.id!,
                        );
                  } else if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
