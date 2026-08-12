import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';

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
            backgroundColor:  AppColors.gray50,
            appBar: CustomAppBar(
            ),
            body: Column(
              children: [
                _buildHeader(innerContext),
                Expanded(
                  child:
                      BlocBuilder<ProductSubUnitsCubit, ProductSubUnitsState>(
                        builder: (context, state) {
                          if (state is ProductSubUnitsLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is ProductSubUnitsError) {
                            return Center(
                              child: Text(
                                state.message,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          } else if (state is ProductSubUnitsLoaded) {
                            if (state.subUnits.isEmpty) {
                              return _buildEmptyState();
                            }
                            return _buildSubUnitsList(
                              innerContext,
                              state.subUnits,
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
                  backgroundColor:  AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('وحدة فرعية جديدة'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext innerContext) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
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
                          value: _selectedProductFilter,
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
                          onChanged: (value) {
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

  Widget _buildSubUnitsList(
    BuildContext innerContext,
    List<ProductSubUnitEntity> subUnits,
  ) {
    // Group sub units by product
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
          padding: const EdgeInsets.all(16),
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
                // Product not found, keep default name
                productName = 'منتج غير معروف';
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style:  AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...productSubUnits.map(
                      (subUnit) => _buildSubUnitItem(innerContext, subUnit),
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

  Widget _buildSubUnitItem(
    BuildContext innerContext,
    ProductSubUnitEntity subUnit,
  ) {
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
            // Unit not found, keep default name
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
                    innerContext.read<ProductSubUnitsCubit>().setMainUnit(
                      subUnit.categoryId!,
                      subUnit.id!,
                    );
                  } else if (value == 'edit') {
                    _showSubUnitDialog(innerContext, subUnit: subUnit);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(innerContext, subUnit);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد وحدات فرعية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة وحدة فرعية جديدة للمنتجات',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
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
            builder: (context, setState) => AlertDialog(
              title: Text(
                subUnit == null ? 'وحدة فرعية جديدة' : 'تعديل الوحدة الفرعية',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<ProductsCubit, ProductsState>(
                      builder: (context, productsState) {
                        if (productsState is ProductsLoaded) {
                          return DropdownButtonFormField<int>(
                            initialValue: selectedProductId,
                            decoration: const InputDecoration(
                              labelText: 'المنتج',
                              border: OutlineInputBorder(),
                            ),
                            items: productsState.products
                                .map(
                                  (product) => DropdownMenuItem(
                                    value: product.id,
                                    child: Text(product.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedProductId = value);
                            },
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
                      builder: (context, unitsState) {
                        if (unitsState is ProductUnitsLoaded) {
                          return DropdownButtonFormField<int>(
                            initialValue: selectedUnitId,
                            decoration: const InputDecoration(
                              labelText: 'الوحدة',
                              border: OutlineInputBorder(),
                            ),
                            items: unitsState.units
                                .map(
                                  (unit) => DropdownMenuItem(
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
                    TextField(
                      controller: packagingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'العبوة (عدد الوحدات)',
                        hintText: 'مثال: 12',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: conversionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'معامل التحويل',
                        hintText: 'مثال: 1.0',
                        border: OutlineInputBorder(),
                      ),
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
                ElevatedButton(
                  onPressed: () {
                    if (selectedProductId == null || selectedUnitId == null) {
                      AppToast.showError(context, 'الرجاء اختيار المنتج والوحدة');
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
                  style: ElevatedButton.styleFrom(
              backgroundColor:  AppColors.primary,
                  ),
                  child: Text(subUnit == null ? 'إضافة' : 'حفظ'),
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
        child: AlertDialog(
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
