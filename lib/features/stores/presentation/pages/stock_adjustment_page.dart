import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_text_field.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/stock_adjustments_cubit.dart';
import 'package:muhasib/features/stores/presentation/widgets/product_picker_sheet.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _statementController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _adjustmentType = 'decrease'; // 'increase' or 'decrease'
  String _adjustmentReason = 'damage';
  WarehouseEntity? _selectedWarehouse;
  final List<StockAdjustmentLineEntity> _adjustmentLines = [];
  bool _pendingPost = false;

  final List<Map<String, String>> _adjustmentReasons = [
    {'value': 'damage', 'label': 'تلف'},
    {'value': 'expiry', 'label': 'انتهاء صلاحية'},
    {'value': 'theft', 'label': 'سرقة'},
    {'value': 'loss', 'label': 'فقدان'},
    {'value': 'error', 'label': 'خطأ في المخزون'},
    {'value': 'found', 'label': 'بضاعة موجودة'},
    {'value': 'gift', 'label': 'هدية'},
    {'value': 'sample', 'label': 'عينة'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  @override
  void initState() {
    super.initState();
    _generateDocumentNumber();
  }

  void _generateDocumentNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _documentNumberController.text =
        'ADJ-${timestamp.substring(timestamp.length - 8)}';
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<WarehousesCubit>()..loadActiveWarehouses(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
        BlocProvider(create: (context) => getIt<StockAdjustmentsCubit>()),
      ],
      child: BlocListener<StockAdjustmentsCubit, StockAdjustmentsState>(
        listener: (context, state) {
          if (state is AdjustmentCreated) {
            if (_pendingPost) {
              context.read<StockAdjustmentsCubit>().postAdjustment(state.id);
            } else {
              AppToast.showSuccess(context, 'تم حفظ التسوية كمسودة');
              context.pop();
            }
          } else if (state is AdjustmentPosted) {
            AppToast.showSuccess(context, 'تم ترحيل التسوية بنجاح');
            context.pop();
          } else if (state is StockAdjustmentsError) {
            AppToast.showError(context, state.message);
          }
        },
        child: Scaffold(
        backgroundColor: AppColors.neutral100,
        appBar: CustomAppBar(
          title: 'تسوية مخزنية',
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showHistoryDialog(context),
              tooltip: 'سجل التسويات',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Document Header Card
                CustomCardContainer(
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
                            Icon(
                              Icons.receipt_long,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'بيانات المستند',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _documentNumberController,
                                label: 'رقم المستند',
                                hint: 'رقم المستند',
                                prefixIcon: Icons.tag,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'التاريخ',
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  child: Text(
                                    '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Adjustment Type Card
                CustomCardContainer(
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
                            Icon(Icons.tune, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'نوع التسوية',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('نقص'),
                                subtitle: const Text('خصم من المخزون'),
                                value: 'decrease',
                                groupValue: _adjustmentType,
                                onChanged: (value) {
                                  setState(() => _adjustmentType = value!);
                                },
                                activeColor: Colors.red,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('زيادة'),
                                subtitle: const Text('إضافة للمخزون'),
                                value: 'increase',
                                groupValue: _adjustmentType,
                                onChanged: (value) {
                                  setState(() => _adjustmentType = value!);
                                },
                                activeColor: Colors.green,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  BlocBuilder<WarehousesCubit, WarehousesState>(
                                    builder: (context, state) {
                                      List<WarehouseEntity> warehouses = [];
                                      if (state is WarehousesLoaded) {
                                        warehouses = state.warehouses;
                                      }

                                      return CustomDropdownField<
                                        WarehouseEntity
                                      >(
                                        value: _selectedWarehouse,
                                        label: 'المخزن',
                                        prefixIcon: const Icon(Icons.warehouse),
                                        items: warehouses.map((warehouse) {
                                          return DropdownMenuItem(
                                            value: warehouse,
                                            child: Text(warehouse.name),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(
                                            () => _selectedWarehouse = value,
                                          );
                                        },
                                        validator: (value) {
                                          if (value == null) {
                                            return 'يرجى اختيار المخزن';
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomDropdownField<String>(
                                value: _adjustmentReason,
                                label: 'السبب',
                                prefixIcon: const Icon(Icons.help_outline),
                                items: _adjustmentReasons.map((reason) {
                                  return DropdownMenuItem(
                                    value: reason['value'],
                                    child: Text(reason['label']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _adjustmentReason = value!);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Product Lines Card
                CustomCardContainer(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'الأصناف',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            HasibButton(
                              label: 'إضافة صنف',
                              onPressed: () => _addProductLine(context),
                              leading: const Icon(Icons.add),
                              variant: HasibButtonVariant.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_adjustmentLines.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'لا توجد أصناف',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _adjustmentLines.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final line = _adjustmentLines[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _adjustmentType == 'increase'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  child: Icon(
                                    _adjustmentType == 'increase'
                                        ? Icons.add
                                        : Icons.remove,
                                    color: _adjustmentType == 'increase'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  line.statement.isEmpty
                                      ? 'صنف ${index + 1}'
                                      : line.statement,
                                ),
                                subtitle: Text(
                                  'الكمية: ${line.quantity} | القيمة: ${line.amount.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _adjustmentLines.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Card
                CustomCardContainer(
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
                            Icon(Icons.note, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'ملاحظات',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _statementController,
                          label: 'الملاحظات',
                          hint: 'أدخل أي ملاحظات إضافية',
                          prefixIcon: Icons.comment,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: HasibButton(
                        label: 'حفظ كمسودة',
                        onPressed: _adjustmentLines.isEmpty
                            ? null
                            : () => _saveAdjustment('draft'),
                        leading: const Icon(Icons.save),
                        variant: HasibButtonVariant.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HasibButton(
                        label: 'ترحيل',
                        onPressed: _adjustmentLines.isEmpty
                            ? null
                            : () => _postAdjustment(),
                        leading: const Icon(Icons.check),
                        variant: HasibButtonVariant.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addProductLine(BuildContext context) async {
    if (_selectedWarehouse == null) {
      AppToast.showWarning(context, 'يرجى اختيار المخزن أولاً');
      return;
    }

    final product = await showProductPicker(context);
    if (product == null) return;

    final input = await _showLineInputDialog(product);
    if (input == null || !mounted) return;

    setState(() {
      _adjustmentLines.add(
        StockAdjustmentLineEntity(
          categoryId: product.id!,
          groupId: product.groupId ?? 1,
          unitId: product.unitId ?? 1,
          categorySubUnitId: 1,
          quantity: input.quantity,
          statement: product.name,
          amount: input.unitCost,
          totalAmount: input.quantity * input.unitCost,
          currencyId: 1,
          stockId: _selectedWarehouse!.id ?? 0,
        ),
      );
    });
  }

  /// Dialog for quantity + unit cost of the adjustment line
  Future<({double quantity, double unitCost})?> _showLineInputDialog(
    ProductEntity product,
  ) async {
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController(
      text: (product.costAmount ?? 0).toStringAsFixed(2),
    );

    final result = await showDialog<({double quantity, double unitCost})>(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: Text('إضافة الصنف: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: qtyController,
              label: 'الكمية',
              prefixIcon: Icons.inventory,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: costController,
              label: 'تكلفة الوحدة',
              prefixIcon: Icons.money,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'إضافة',
            onPressed: () {
              final qty = double.tryParse(qtyController.text.trim()) ?? 0;
              final cost = double.tryParse(costController.text.trim()) ?? 0;
              if (qty <= 0 || cost < 0) return;
              Navigator.pop(dialogContext, (quantity: qty, unitCost: cost));
            },
            variant: HasibButtonVariant.primary,
          ),
        ],
      ),
    );

    qtyController.dispose();
    costController.dispose();
    return result;
  }

  bool _validateAdjustment() {
    if (_selectedWarehouse == null) {
      AppToast.showError(context, 'يرجى اختيار المخزن');
      return false;
    }
    if (_adjustmentLines.isEmpty) {
      AppToast.showError(context, 'يرجى إضافة صنف واحد على الأقل');
      return false;
    }
    return true;
  }

  StockAdjustmentEntity _buildAdjustmentEntity() {
    return StockAdjustmentEntity(
      number: _documentNumberController.text,
      date: _selectedDate.millisecondsSinceEpoch ~/ 1000,
      type: _adjustmentType == 'increase'
          ? AdjustmentType.increase
          : AdjustmentType.decrease,
      currencyId: 1,
      statement: _statementController.text.trim(),
      status: TransferStatus.draft,
      stockId: _selectedWarehouse?.id,
      settlementReason: _adjustmentReason,
      lines: _adjustmentLines,
    );
  }

  void _saveAdjustment(String status) {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateAdjustment()) return;

    _pendingPost = false;
    context
        .read<StockAdjustmentsCubit>()
        .createAdjustment(_buildAdjustmentEntity());
  }

  void _postAdjustment() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateAdjustment()) return;

    _showAccountingPreview();
  }

  void _showAccountingPreview() {
    final totalValue = _adjustmentLines.fold<double>(
      0,
      (sum, line) => sum + (line.quantity * line.amount),
    );

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: const Text('معاينة القيود المحاسبية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _adjustmentType == 'increase' ? 'قيد الزيادة:' : 'قيد النقص:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_adjustmentType == 'increase')
                Text(
                  'من ح/ المخزون ${totalValue.toStringAsFixed(2)}\n'
                  '  إلى ح/ إيرادات تسوية المخزون ${totalValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: 'monospace'),
                )
              else
                Text(
                  'من ح/ خسائر تسوية المخزون ${totalValue.toStringAsFixed(2)}\n'
                  '  إلى ح/ المخزون ${totalValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              const SizedBox(height: 16),
              const Text(
                'سيتم ترحيل التسوية وتحديث المخزون والقيود المحاسبية. هل تريد المتابعة؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'ترحيل',
            onPressed: () {
              Navigator.pop(context);
              _pendingPost = true;
              context
                  .read<StockAdjustmentsCubit>()
                  .createAdjustment(_buildAdjustmentEntity());
            },
            variant: HasibButtonVariant.success,
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: const Text('سجل التسويات'),
        content: const SizedBox(
          width: double.maxFinite,
          child: Text('سيتم عرض سجل التسويات السابقة هنا'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
