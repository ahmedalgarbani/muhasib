import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseFormSupplierWarehouseCard extends StatelessWidget {
  final int? selectedSupplierId;
  final int? selectedWarehouseId;
  final ValueChanged<int?> onSupplierChanged;
  final ValueChanged<int?> onWarehouseChanged;

  const PurchaseFormSupplierWarehouseCard({
    super.key,
    required this.selectedSupplierId,
    required this.selectedWarehouseId,
    required this.onSupplierChanged,
    required this.onWarehouseChanged,
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
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المورد والمخزن',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<CustomersCubit, CustomersState>(
              builder: (context, state) {
                if (state is SuppliersLoaded) {
                  final supplierItems = state.suppliers.map((supplier) {
                    final sId = int.tryParse(supplier.id) ?? 1;
                    return DropdownMenuItem<int>(
                      value: sId,
                      child: Text(
                        supplier.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList();

                  final effectiveValue = supplierItems.any((item) => item.value == selectedSupplierId)
                      ? selectedSupplierId
                      : (supplierItems.isNotEmpty ? supplierItems.first.value : null);

                  if (effectiveValue != selectedSupplierId && effectiveValue != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onSupplierChanged(effectiveValue);
                    });
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: CustomDropdownField<int>(
                          value: effectiveValue,
                          label: 'المورد',
                          prefixIcon: const Icon(Icons.business, size: 20),
                          items: supplierItems,
                          onChanged: onSupplierChanged,
                          validator: (value) {
                            if (value == null) {
                              return 'يجب اختيار المورد';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          tooltip: 'إضافة مورد جديد',
                          onPressed: () async {
                            final cubit = context.read<CustomersCubit>();
                            final newSupplier = await showDialog<Customer>(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: cubit,
                                child: const AddCustomerDialog(partyType: 2),
                              ),
                            );

                            if (newSupplier != null && context.mounted) {
                              onSupplierChanged(
                                int.tryParse(newSupplier.id),
                              );
                              cubit.loadSuppliers();
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
            const SizedBox(height: 12),
            BlocBuilder<WarehousesCubit, WarehousesState>(
              builder: (context, state) {
                if (state is WarehousesLoaded) {
                  final warehouseItems = state.warehouses.map((warehouse) {
                    return DropdownMenuItem<int>(
                      value: warehouse.id,
                      child: Text(
                        warehouse.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList();

                  final effectiveValue = warehouseItems.any((item) => item.value == selectedWarehouseId)
                      ? selectedWarehouseId
                      : (warehouseItems.isNotEmpty ? warehouseItems.first.value : null);

                  if (effectiveValue != selectedWarehouseId && effectiveValue != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onWarehouseChanged(effectiveValue);
                    });
                  }

                  return CustomDropdownField<int>(
                    value: effectiveValue,
                    label: 'المخزن',
                    prefixIcon: const Icon(Icons.warehouse, size: 20),
                    items: warehouseItems,
                    onChanged: onWarehouseChanged,
                    validator: (value) {
                      if (value == null) {
                        return 'يجب اختيار المخزن';
                      }
                      return null;
                    },
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }
}
