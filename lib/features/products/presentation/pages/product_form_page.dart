import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
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
  int? _selectedStockId; // Will be set from actual warehouses
  bool _isActive = true;
  bool _isTaxable = true;
  bool _isLoading = false;

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
    super.dispose();
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
      ],
      child: BlocListener<ProductsCubit, ProductsState>(
        listener: (context, state) {
          if (state is ProductCreated || state is ProductUpdated) {
            AppToast.showSuccess(
              context,
              widget.product == null
                  ? 'تم إضافة المنتج بنجاح'
                  : 'تم تحديث المنتج بنجاح',
            );
            Navigator.pop(context);
          } else if (state is ProductsError) {
            AppToast.showError(context, 'خطأ: ${state.message}');
            setState(() => _isLoading = false);
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.gray50,
            appBar: CustomAppBar(
              title: widget.product == null ? 'منتج جديد' : 'تعديل المنتج',
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _buildSectionCard(
                    title: 'المعلومات الأساسية',
                    icon: Icons.info_outline,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'اسم المنتج',
                        hint: 'أدخل اسم المنتج',
                        icon: Icons.inventory,
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
                      _buildTextField(
                        controller: _statementController,
                        label: 'الوصف',
                        hint: 'أدخل وصف المنتج',
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال وصف المنتج';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _barcodeController,
                        label: 'الباركود',
                        hint: 'أدخل الباركود',
                        icon: Icons.qr_code,
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
                  _buildSectionCard(
                    title: 'التصنيف',
                    icon: Icons.category,
                    children: [
                      BlocBuilder<ProductGroupsCubit, ProductGroupsState>(
                        builder: (context, state) {
                          if (state is ProductGroupsLoaded) {
                            return DropdownButtonFormField<int>(
                              initialValue: _selectedGroupId,
                              decoration: const InputDecoration(
                                labelText: 'المجموعة',
                                prefixIcon: Icon(Icons.folder),
                                border: OutlineInputBorder(),
                              ),
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
                            return DropdownButtonFormField<int>(
                              initialValue: _selectedUnitId,
                              decoration: const InputDecoration(
                                labelText: 'الوحدة',
                                prefixIcon: Icon(Icons.straighten),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('بدون وحدة'),
                                ),
                                ...state.units.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit.id,
                                    child: Text('${unit.name} (${unit.short})'),
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
                            // Set default warehouse if not selected
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

                            return DropdownButtonFormField<int>(
                              initialValue: _selectedStockId,
                              decoration: const InputDecoration(
                                labelText: 'المخزن *',
                                prefixIcon: Icon(Icons.store),
                                border: OutlineInputBorder(),
                              ),
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
                  _buildSectionCard(
                    title: 'الأسعار والمخزون',
                    icon: Icons.attach_money,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _costPriceController,
                              label: 'سعر التكلفة',
                              hint: '0.00',
                              icon: Icons.money_off,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _sellPriceController,
                              label: 'سعر البيع',
                              hint: '0.00',
                              icon: Icons.price_check,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityController,
                              label: 'الكمية',
                              hint: '0',
                              icon: Icons.inventory_2,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _minStockController,
                              label: 'الحد الأدنى',
                              hint: '0',
                              icon: Icons.trending_down,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _maxStockController,
                        label: 'الحد الأقصى (اختياري)',
                        hint: '0',
                        icon: Icons.trending_up,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'إعدادات إضافية',
                    icon: Icons.settings,
                    children: [
                      SwitchListTile(
                        title: const Text('المنتج نشط'),
                        subtitle: const Text('يمكن استخدام المنتج في الفواتير'),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.product == null
                                  ? 'إضافة المنتج'
                                  : 'تحديث المنتج',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextInputField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure stockId is set
    if (_selectedStockId == null) {
      AppToast.showError(context, 'يرجى اختيار المخزن');
      return;
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
      quantity: double.tryParse(_quantityController.text) ?? 0,
      minStockLevel: double.tryParse(_minStockController.text) ?? 0,
      maxStockLevel: _maxStockController.text.isNotEmpty
          ? double.tryParse(_maxStockController.text)
          : null,
      groupId: _selectedGroupId,
      unitId: _selectedUnitId,
      stockId: _selectedStockId ?? 1, // Ensure stockId is never null
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
