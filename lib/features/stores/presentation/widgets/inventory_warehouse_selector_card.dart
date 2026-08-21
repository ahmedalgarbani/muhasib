import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class InventoryWarehouseSelectorCard extends StatelessWidget {
  final WarehouseEntity? selectedWarehouse;
  final ValueChanged<WarehouseEntity?> onWarehouseChanged;

  const InventoryWarehouseSelectorCard({
    super.key,
    required this.selectedWarehouse,
    required this.onWarehouseChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomCardContainer(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warehouse, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'المخزن',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<WarehousesCubit, WarehousesState>(
              builder: (context, state) {
                if (state is WarehousesLoading) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator()));
                }
                if (state is WarehousesError) {
                  return Text('خطأ في تحميل المخازن: ${state.message}',
                      style: TextStyle(color: Colors.red[700]));
                }
                List<WarehouseEntity> warehouses = [];
                if (state is WarehousesLoaded) {
                  warehouses = state.warehouses;
                }
                if (warehouses.isEmpty) {
                  return const Text('لا توجد مخازن نشطة — قم بإنشاء مخزن أولاً',
                      style: TextStyle(color: Colors.grey));
                }

                return CustomDropdownField<WarehouseEntity>(
                  value: selectedWarehouse,
                  label: 'اختر المخزن',
                  prefixIcon: const Icon(Icons.store),
                  items: warehouses.map((warehouse) {
                    return DropdownMenuItem(
                      value: warehouse,
                      child: Text(warehouse.name),
                    );
                  }).toList(),
                  onChanged: onWarehouseChanged,
                  validator: (value) {
                    if (value == null) {
                      return 'يرجى اختيار المخزن';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
