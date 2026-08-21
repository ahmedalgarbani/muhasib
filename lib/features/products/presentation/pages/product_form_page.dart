import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/domain/entities/product_sub_unit_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class ProductFormPage extends StatefulWidget {
  final ProductEntity? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _statementController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minStockController;
  late final TextEditingController _maxStockController;

  int? _selectedGroupId;
  int? _selectedUnitId;
  int? _selectedStockId;
  bool _isActive = true;
  bool _isTaxable = true;
  bool _isLoading = false;

  // Multi-unit
  final List<_ExtraUnitRow> _extraUnits = [];
  List<ProductSubUnitEntity> _existingSubUnits = [];
  bool _loadingSubUnits = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _statementController = TextEditingController(
      text: widget.product?.statement ?? '',
    );
    _barcodeController = TextEditingController(
      text: widget.product?.barcodeNo ?? '',
    );
    _costPriceController = TextEditingController(
      text: widget.product?.costAmount?.toString() ?? '',
    );
    _sellPriceController = TextEditingController(
      text: widget.product?.sellAmount?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.product?.quantity.toString() ?? '0',
    );
    _minStockController = TextEditingController(
      text: widget.product?.minStockLevel?.toString() ?? '0',
    );
    _maxStockController = TextEditingController(
      text: widget.product?.maxStockLevel?.toString() ?? '',
    );

    _selectedGroupId = widget.product?.groupId;
    _selectedUnitId = widget.product?.unitId;
    _selectedStockId = widget.product?.stockId;
    _isActive = widget.product?.isActive ?? true;
    _isTaxable = widget.product?.isTaxable ?? true;

    // تحميل الوحدات الإضافية سيتم عبر Bloc في البناء (post-frame) لتجنب تكرار instances
  }

  bool _didLoadExtraUnits = false;
  void _ensureExtraUnitsLoaded(BuildContext context) {
    if (_didLoadExtraUnits) return;
    if (widget.product?.id == null) return;
    _didLoadExtraUnits = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductSubUnitsCubit>().loadSubUnitsByProduct(
        widget.product!.id!,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statementController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    for (final r in _extraUnits) {
      r.dispose();
    }
    super.dispose();
  }

  void _addExtraUnit() {
    setState(() {
      _extraUnits.add(_ExtraUnitRow());
    });
  }

  void _removeExtraUnit(int index) {
    final row = _extraUnits[index];
    // If it has an id, we need to delete from DB later
    if (row.existingId != null) {
      // Mark for deletion via cubit on save
      row.markDeleted = true;
      setState(() {});
      // immediate delete via cubit if editing existing product
      if (widget.product?.id != null) {
        getIt<ProductSubUnitsCubit>().deleteSubUnit(row.existingId!);
      }
    }
    setState(() {
      _extraUnits.removeAt(index);
      row.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ProductGroupsCubit>()..loadAllGroups(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductUnitsCubit>()..loadAllUnits(),
        ),
        BlocProvider(
          create: (context) => getIt<WarehousesCubit>()..loadActiveWarehouses(),
        ),
        BlocProvider(create: (context) => getIt<ProductSubUnitsCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProductsCubit, ProductsState>(
            listener: (context, state) async {
              if (state is ProductCreated) {
                final newProductId = state.id;
                if (_extraUnits.isNotEmpty && newProductId != null) {
                  await _persistExtraUnits(newProductId);
                }
                if (mounted) {
                  AppToast.showSuccess(context, 'تم إضافة المنتج بنجاح');
                  Navigator.pop(context);
                }
                setState(() => _isLoading = false);
              } else if (state is ProductUpdated) {
                if (widget.product?.id != null && _extraUnits.isNotEmpty) {
                  await _persistExtraUnits(widget.product!.id!);
                }
                if (mounted) {
                  AppToast.showSuccess(context, 'تم تحديث المنتج بنجاح');
                  Navigator.pop(context);
                }
                setState(() => _isLoading = false);
              } else if (state is ProductsError) {
                AppToast.showError(context, 'خطأ: ${state.message}');
                setState(() => _isLoading = false);
              }
            },
          ),
          BlocListener<ProductSubUnitsCubit, ProductSubUnitsState>(
            listener: (context, state) {
              if (state is ProductSubUnitsLoaded &&
                  widget.product?.id != null) {
                // تعبئة الوحدات الإضافية مرة واحدة عند التحميل الأول
                if (_existingSubUnits.isEmpty && _extraUnits.isEmpty) {
                  _existingSubUnits = state.subUnits;
                  for (final su in _existingSubUnits) {
                    if (su.isMainUnit) continue;
                    _extraUnits.add(_ExtraUnitRow.fromEntity(su));
                  }
                  if (mounted) setState(() {});
                }
              }
            },
          ),
        ],
        child: Builder(
          builder: (innerContext) {
            _ensureExtraUnitsLoaded(innerContext);
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: CustomAppBar(
                  title: widget.product == null ? 'منتج جديد' : 'تعديل المنتج',
                ),
                body: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    children: [
                      ProductFormSectionCard(
                        title: 'المعلومات الأساسية',
                        icon: Icons.info_outline,
                        children: [
                          TextInputField(
                            controller: _nameController,
                            label: 'اسم المنتج',
                            hint: 'أدخل اسم المنتج',
                            prefixIcon: const Icon(Icons.inventory),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال اسم المنتج';
                              }
                              if (value.length > 100) {
                                return 'الاسم طويل جداً (الحد الأقصى 100 حرف)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextInputField(
                            controller: _statementController,
                            label: 'الوصف',
                            hint: 'أدخل وصف المنتج',
                            prefixIcon: const Icon(Icons.description),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال وصف المنتج';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextInputField(
                            controller: _barcodeController,
                            label: 'الباركود (الوحدة الأساسية)',
                            hint: 'أدخل الباركود الأساسي',
                            prefixIcon: const Icon(Icons.qr_code),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال الباركود';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProductFormSectionCard(
                        title: 'التصنيف',
                        icon: Icons.category,
                        children: [
                          BlocBuilder<ProductGroupsCubit, ProductGroupsState>(
                            builder: (context, state) {
                              if (state is ProductGroupsLoaded) {
                                return CustomDropdownField<int>(
                                  value: _selectedGroupId,
                                  label: 'المجموعة',
                                  prefixIcon: const Icon(Icons.folder),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('بدون مجموعة'),
                                    ),
                                    ...state.groups.map((group) {
                                      return DropdownMenuItem(
                                        value: group.id,
                                        child: Text(group.name),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedGroupId = value);
                                  },
                                );
                              }
                              return const LinearProgressIndicator();
                            },
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
                            builder: (context, state) {
                              if (state is ProductUnitsLoaded) {
                                return CustomDropdownField<int>(
                                  value: _selectedUnitId,
                                  label: 'الوحدة الأساسية',
                                  prefixIcon: const Icon(Icons.straighten),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('بدون وحدة'),
                                    ),
                                    ...state.units.map((unit) {
                                      return DropdownMenuItem(
                                        value: unit.id,
                                        child: Text(
                                          '${unit.name} (${unit.short})',
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedUnitId = value);
                                  },
                                );
                              }
                              return const LinearProgressIndicator();
                            },
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<WarehousesCubit, WarehousesState>(
                            builder: (context, state) {
                              if (state is WarehousesLoaded &&
                                  state.warehouses.isNotEmpty) {
                                if (_selectedStockId == null) {
                                  WarehouseEntity? mainW;
                                  for (final w in state.warehouses) {
                                    if (w.isMainStock == true) {
                                      mainW = w;
                                      break;
                                    }
                                  }
                                  _selectedStockId =
                                      (mainW ?? state.warehouses.first).id;
                                }

                                return CustomDropdownField<int>(
                                  value: _selectedStockId,
                                  label: 'المخزن',
                                  isRequired: true,
                                  prefixIcon: const Icon(Icons.store),
                                  validator: (value) {
                                    if (value == null) {
                                      return 'يرجى اختيار المخزن';
                                    }
                                    return null;
                                  },
                                  items: state.warehouses.map((warehouse) {
                                    return DropdownMenuItem(
                                      value: warehouse.id,
                                      child: Text(
                                        warehouse.name +
                                            (warehouse.isMainStock == true
                                                ? ' (الرئيسي)'
                                                : ''),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedStockId = value);
                                  },
                                );
                              }
                              return const LinearProgressIndicator();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ProductFormSectionCard(
                        title: 'الأسعار والمخزون (الوحدة الأساسية)',
                        icon: Icons.attach_money,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextInputField(
                                  controller: _costPriceController,
                                  label: 'سعر التكلفة (أساس)',
                                  hint: '0.00',
                                  prefixIcon: const Icon(Icons.money_off),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextInputField(
                                  controller: _sellPriceController,
                                  label: 'سعر البيع (أساس)',
                                  hint: '0.00',
                                  prefixIcon: const Icon(Icons.price_check),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextInputField(
                                  controller: _quantityController,
                                  label: widget.product == null
                                      ? 'الكمية الافتتاحية (أساس)'
                                      : 'الكمية الحالية',
                                  hint: '0',
                                  prefixIcon: const Icon(Icons.inventory_2),
                                  keyboardType: TextInputType.number,
                                  readOnly: widget.product != null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextInputField(
                                  controller: _minStockController,
                                  label: 'الحد الأدنى',
                                  hint: '0',
                                  prefixIcon: const Icon(Icons.trending_down),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextInputField(
                            controller: _maxStockController,
                            label: 'الحد الأقصى (اختياري)',
                            hint: '0',
                            prefixIcon: const Icon(Icons.trending_up),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'المخزون يُدار دائماً بالوحدة الأساسية. الكميات المحولة تُحسب تلقائياً.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Multi-unit dynamic section
                      _buildMultiUnitSection(),
                      const SizedBox(height: 16),
                      ProductFormSectionCard(
                        title: 'إعدادات إضافية',
                        icon: Icons.settings,
                        children: [
                          SwitchListTile(
                            title: const Text('المنتج نشط'),
                            subtitle: const Text(
                              'يمكن استخدام المنتج في الفواتير',
                            ),
                            value: _isActive,
                            onChanged: (value) {
                              setState(() => _isActive = value);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('خاضع للضريبة'),
                            subtitle: const Text(
                              'سيتم حساب الضريبة على هذا المنتج',
                            ),
                            value: _isTaxable,
                            onChanged: (value) {
                              setState(() => _isTaxable = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      HasibButton(
                        label: widget.product == null
                            ? 'إضافة المنتج'
                            : 'تحديث المنتج',
                        loading: _isLoading,
                        onPressed: _isLoading ? null : _saveProduct,
                        variant: HasibButtonVariant.primary,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMultiUnitSection() {
    return ProductFormSectionCard(
      title: 'الوحدات الإضافية / التعبئة',
      icon: Icons.layers,
      children: [
        Text(
          'أضف وحدات التعبئة للصنف (مثال: درزن 12 حبة، كرتون 24). يُحسب السعر تلقائياً إن ترك فارغاً.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        if (_loadingSubUnits) const LinearProgressIndicator(),
        if (_extraUnits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'لا توجد وحدات إضافية — اضغط أدناه للإضافة',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ),
        ..._extraUnits.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          return _ExtraUnitCard(
            row: row,
            index: idx,
            onRemove: () => _removeExtraUnit(idx),
            baseCost: double.tryParse(_costPriceController.text) ?? 0,
            baseSell: double.tryParse(_sellPriceController.text) ?? 0,
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addExtraUnit,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة وحدة'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 42),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _persistExtraUnits(int productId) async {
    final cubit = getIt<ProductSubUnitsCubit>();
    for (final row in List<_ExtraUnitRow>.from(_extraUnits)) {
      if (row.markDeleted) continue;
      if (row.unitId == null) continue;
      if (row.packagingController.text.isEmpty) continue;
      final packaging = int.tryParse(row.packagingController.text) ?? 1;
      final conversionRate =
          double.tryParse(row.conversionController.text) ?? 1.0;
      if (packaging <= 0 || conversionRate <= 0) continue;

      final entity = ProductSubUnitEntity(
        id: row.existingId,
        categoryId: productId,
        unitId: row.unitId,
        packaging: packaging,
        conversionRate: conversionRate,
        isMainUnit: false,
        isActive: true,
        barcode: row.barcodeController.text.trim().isEmpty
            ? null
            : row.barcodeController.text.trim(),
        costPrice: row.costController.text.isEmpty
            ? null
            : double.tryParse(row.costController.text),
        sellPrice: row.sellController.text.isEmpty
            ? null
            : double.tryParse(row.sellController.text),
        wholesalePrice: row.wholesaleController.text.isEmpty
            ? null
            : double.tryParse(row.wholesaleController.text),
        isDefaultSale: row.isDefaultSale,
        isDefaultPurchase: row.isDefaultPurchase,
      );

      if (row.existingId == null) {
        await cubit.createSubUnit(entity);
      } else {
        await cubit.updateSubUnit(entity);
      }
    }
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStockId == null) {
      AppToast.showError(context, 'يرجى اختيار المخزن');
      return;
    }

    // Validate extra units: no duplicate unit, valid conversion
    final seenUnits = <int>{};
    for (final r in _extraUnits) {
      if (r.unitId == null) {
        AppToast.showError(context, 'يرجى اختيار وحدة لكل سطر إضافي');
        return;
      }
      if (seenUnits.contains(r.unitId)) {
        AppToast.showError(context, 'وحدة مكررة في الوحدات الإضافية');
        return;
      }
      seenUnits.add(r.unitId!);
      final pack = int.tryParse(r.packagingController.text) ?? 0;
      if (pack <= 0) {
        AppToast.showError(context, 'كمية التعبئة يجب أن تكون موجبة');
        return;
      }
      final conv = double.tryParse(r.conversionController.text) ?? 0;
      if (conv <= 0) {
        AppToast.showError(context, 'معامل التحويل يجب أن يكون موجباً');
        return;
      }
      if (r.barcodeController.text.trim().isNotEmpty) {
        // Basic check: barcode should be unique length
        if (r.barcodeController.text.trim().length < 3) {
          AppToast.showError(context, 'الباركود قصير جداً');
          return;
        }
      }
    }
    // Also check barcode not equals base barcode
    final baseBarcode = _barcodeController.text.trim();
    for (final r in _extraUnits) {
      if (r.barcodeController.text.trim() == baseBarcode &&
          baseBarcode.isNotEmpty) {
        AppToast.showError(
          context,
          'باركود الوحدة الإضافية يطابق باركود الوحدة الأساسية',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final product = ProductEntity(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      statement: _statementController.text.trim(),
      barcodeNo: _barcodeController.text.trim(),
      costAmount: _costPriceController.text.isNotEmpty
          ? double.tryParse(_costPriceController.text)
          : null,
      sellAmount: _sellPriceController.text.isNotEmpty
          ? double.tryParse(_sellPriceController.text)
          : null,
      quantity: widget.product == null
          ? (double.tryParse(_quantityController.text) ?? 0)
          : (widget.product?.quantity ?? 0),
      minStockLevel: double.tryParse(_minStockController.text) ?? 0,
      maxStockLevel: _maxStockController.text.isNotEmpty
          ? double.tryParse(_maxStockController.text)
          : null,
      groupId: _selectedGroupId,
      unitId: _selectedUnitId,
      stockId: _selectedStockId ?? 1,
      isActive: _isActive,
      isTaxable: _isTaxable,
      creationTime: widget.product?.creationTime,
      lastModificationTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    if (widget.product == null) {
      context.read<ProductsCubit>().createProduct(product);
    } else {
      context.read<ProductsCubit>().updateProduct(product);
    }
  }
}

class _ExtraUnitRow {
  int? existingId;
  int? unitId;
  bool isDefaultSale = false;
  bool isDefaultPurchase = false;
  bool markDeleted = false;
  final TextEditingController packagingController;
  final TextEditingController conversionController;
  final TextEditingController barcodeController;
  final TextEditingController costController;
  final TextEditingController sellController;
  final TextEditingController wholesaleController;

  _ExtraUnitRow({
    this.existingId,
    this.unitId,
    int packaging = 1,
    double conversionRate = 1.0,
    String? barcode,
    double? costPrice,
    double? sellPrice,
    double? wholesalePrice,
    bool isDefaultSale = false,
    bool isDefaultPurchase = false,
  }) : packagingController = TextEditingController(text: packaging.toString()),
       conversionController = TextEditingController(
         text: conversionRate.toString(),
       ),
       barcodeController = TextEditingController(text: barcode ?? ''),
       costController = TextEditingController(
         text: costPrice?.toString() ?? '',
       ),
       sellController = TextEditingController(
         text: sellPrice?.toString() ?? '',
       ),
       wholesaleController = TextEditingController(
         text: wholesalePrice?.toString() ?? '',
       ),
       isDefaultSale = isDefaultSale,
       isDefaultPurchase = isDefaultPurchase;

  factory _ExtraUnitRow.fromEntity(ProductSubUnitEntity e) {
    return _ExtraUnitRow(
      existingId: e.id,
      unitId: e.unitId,
      packaging: e.packaging,
      conversionRate: e.conversionRate,
      barcode: e.barcode,
      costPrice: e.costPrice,
      sellPrice: e.sellPrice,
      wholesalePrice: e.wholesalePrice,
      isDefaultSale: e.isDefaultSale,
      isDefaultPurchase: e.isDefaultPurchase,
    );
  }

  void dispose() {
    packagingController.dispose();
    conversionController.dispose();
    barcodeController.dispose();
    costController.dispose();
    sellController.dispose();
    wholesaleController.dispose();
  }
}

class _ExtraUnitCard extends StatefulWidget {
  final _ExtraUnitRow row;
  final int index;
  final VoidCallback onRemove;
  final double baseCost;
  final double baseSell;

  const _ExtraUnitCard({
    required this.row,
    required this.index,
    required this.onRemove,
    required this.baseCost,
    required this.baseSell,
  });

  @override
  State<_ExtraUnitCard> createState() => _ExtraUnitCardState();
}

class _ExtraUnitCardState extends State<_ExtraUnitCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'وحدة #${widget.index + 1}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: widget.onRemove,
                tooltip: 'حذف',
              ),
            ],
          ),
          BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
            builder: (context, state) {
              if (state is ProductUnitsLoaded) {
                return CustomDropdownField<int>(
                  value: widget.row.unitId,
                  label: 'الوحدة',
                  prefixIcon: const Icon(Icons.straighten, size: 18),
                  items: state.units
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.short})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => widget.row.unitId = v),
                );
              }
              return const LinearProgressIndicator();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  controller: widget.row.packagingController,
                  label: 'تحتوي على',
                  hint: '24',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.numbers, size: 18),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextInputField(
                  controller: widget.row.conversionController,
                  label: 'معامل التحويل',
                  hint: '1.0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: const Icon(Icons.transform, size: 18),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildAutoPriceHint(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  controller: widget.row.sellController,
                  label: 'سعر البيع',
                  hint: 'سعر الكرتون',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextInputField(
                  controller: widget.row.wholesaleController,
                  label: 'سعر الجملة',
                  hint: 'اختياري',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(Icons.satellite, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  controller: widget.row.costController,
                  label: 'سعر التكلفة',
                  hint: 'اختياري',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.money_off_csred, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextInputField(
                  controller: widget.row.barcodeController,
                  label: 'الباركود',
                  hint: 'باركود الكرتون',
                  prefixIcon: const Icon(Icons.qr_code_2, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'افتراضي للبيع',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: widget.row.isDefaultSale,
                  onChanged: (v) =>
                      setState(() => widget.row.isDefaultSale = v ?? false),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'افتراضي للشراء',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: widget.row.isDefaultPurchase,
                  onChanged: (v) =>
                      setState(() => widget.row.isDefaultPurchase = v ?? false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPriceHint() {
    final packaging = int.tryParse(widget.row.packagingController.text) ?? 1;
    final conv = double.tryParse(widget.row.conversionController.text) ?? 1.0;
    if (packaging <= 0 || conv <= 0) return const SizedBox.shrink();
    final factor = packaging * conv;
    final autoSell = PrecisionHelper.calcUnitPrice(
      basePrice: widget.baseSell,
      packaging: packaging,
      conversionRate: conv,
    );
    final autoCost = PrecisionHelper.calcUnitPrice(
      basePrice: widget.baseCost,
      packaging: packaging,
      conversionRate: conv,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'معامل إجمالي: x$factor → سعر تلقائي: بيع ${autoSell.toStringAsFixed(2)} / تكلفة ${autoCost.toStringAsFixed(2)} (اترك الحقل فارغاً لاستخدام التلقائي)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductFormSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const ProductFormSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.labelLarge),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
