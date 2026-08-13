import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/widgets/product_sub_units_widgets.dart';

class ProductSubUnitsPage extends StatefulWidget {
  const ProductSubUnitsPage({super.key});

  @override
  State<ProductSubUnitsPage> createState() => _ProductSubUnitsPageState();
}

class _ProductSubUnitsPageState extends State<ProductSubUnitsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _selectedProductFilter;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ProductSubUnitsCubit>()..loadAllSubUnits(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductUnitsCubit>()..loadAllUnits(),
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (innerContext) => Scaffold(
            key: _scaffoldKey,
            backgroundColor: Theme.of(innerContext).scaffoldBackgroundColor,
            appBar: const CustomAppBar(),
            body: Column(
              children: [
                ProductSubUnitsHeaderWidget(
                  selectedProductFilter: _selectedProductFilter,
                  onProductFilterChanged: (value) {
                    setState(() => _selectedProductFilter = value);
                    if (value != null) {
                      innerContext
                          .read<ProductSubUnitsCubit>()
                          .loadSubUnitsByProduct(value);
                    } else {
                      innerContext
                          .read<ProductSubUnitsCubit>()
                          .loadAllSubUnits();
                    }
                  },
                ),
                Expanded(
                  child: BlocBuilder<ProductSubUnitsCubit, ProductSubUnitsState>(
                    builder: (context, state) {
                      if (state is ProductSubUnitsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ProductSubUnitsError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (state is ProductSubUnitsLoaded) {
                        if (state.subUnits.isEmpty) {
                          return const EmptyStateWidget(
                            title: 'لا توجد وحدات فرعية',
                            subtitle: 'ابدأ بإضافة وحدة فرعية جديدة للمنتجات',
                            icon: Icons.layers_outlined,
                          );
                        }
                        return ProductSubUnitsListWidget(
                          subUnits: state.subUnits,
                          onEditSubUnit: (subUnit) =>
                              _showSubUnitDialog(innerContext, subUnit: subUnit),
                          onDeleteSubUnit: (subUnit) =>
                              _showDeleteConfirmation(innerContext, subUnit),
                        );
                      }
                      return const Center(
                        child: Text('ابدأ بإضافة وحدات فرعية'),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showSubUnitDialog(innerContext),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('وحدة فرعية جديدة'),
            ),
          ),
        ),
      ),
    );
  }

  void _showSubUnitDialog(
    BuildContext context, {
    ProductSubUnitEntity? subUnit,
  }) {
    final productsCubit = context.read<ProductsCubit>();
    final unitsCubit = context.read<ProductUnitsCubit>();
    final subUnitsCubit = context.read<ProductSubUnitsCubit>();
    final packagingController = TextEditingController(
      text: subUnit?.packaging.toString() ?? '1',
    );
    final conversionController = TextEditingController(
      text: subUnit?.conversionRate.toString() ?? '1.0',
    );
    int? selectedProductId = subUnit?.categoryId;
    int? selectedUnitId = subUnit?.unitId;
    bool isMainUnit = subUnit?.isMainUnit ?? false;
    bool isActive = subUnit?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: productsCubit),
            BlocProvider.value(value: unitsCubit),
            BlocProvider.value(value: subUnitsCubit),
          ],
          child: StatefulBuilder(
            builder: (context, setState) => CustomDialog(
              title: Text(
                subUnit == null ? 'وحدة فرعية جديدة' : 'تعديل الوحدة الفرعية',
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
                      builder: (context, unitsState) {
                        if (unitsState is ProductUnitsLoaded) {
                          return CustomDropdownField<int>(
                            label: 'الوحدة',
                            value: selectedUnitId,
                            items: unitsState.units
                                .map(
                                  (unit) => DropdownMenuItem<int>(
                                    value: unit.id,
                                    child: Text('${unit.name} (${unit.short})'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedUnitId = value);
                            },
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      controller: packagingController,
                      keyboardType: TextInputType.number,
                      label: 'العبوة (عدد الوحدات)',
                      hint: 'مثال: 12',
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      controller: conversionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      label: 'معامل التحويل',
                      hint: 'مثال: 1.0',
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('وحدة رئيسية'),
                      value: isMainUnit,
                      onChanged: (value) {
                        setState(() => isMainUnit = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('نشط'),
                      value: isActive,
                      onChanged: (value) {
                        setState(() => isActive = value ?? true);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                HasibButton(
                  label: subUnit == null ? 'إضافة' : 'حفظ',
                  onPressed: () {
                    if (selectedProductId == null || selectedUnitId == null) {
                      AppToast.showError(
                        context,
                        'الرجاء اختيار المنتج والوحدة',
                      );
                      return;
                    }

                    final packaging =
                        int.tryParse(packagingController.text) ?? 1;
                    final conversion =
                        double.tryParse(conversionController.text) ?? 1.0;

                    final entity = ProductSubUnitEntity(
                      id: subUnit?.id,
                      categoryId: selectedProductId,
                      unitId: selectedUnitId,
                      packaging: packaging,
                      conversionRate: conversion,
                      isMainUnit: isMainUnit,
                      isActive: isActive,
                    );

                    if (subUnit == null) {
                      subUnitsCubit.createSubUnit(entity);
                    } else {
                      subUnitsCubit.updateSubUnit(entity);
                    }

                    Navigator.pop(dialogContext);
                  },
                  variant: HasibButtonVariant.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ProductSubUnitEntity subUnit,
  ) {
    final subUnitsCubit = context.read<ProductSubUnitsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: CustomDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذه الوحدة الفرعية؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (subUnit.id != null) {
                  subUnitsCubit.deleteSubUnit(subUnit.id!);
                }
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}
