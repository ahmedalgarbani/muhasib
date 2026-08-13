import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_text_field.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/stock_adjustments_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

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
        if (getIt.isRegistered<StockAdjustmentsCubit>())
          BlocProvider(create: (context) => getIt<StockAdjustmentsCubit>()),
      ],
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
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Document Header Card
                Card(
                  elevation: 2,
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
                Card(
                  elevation: 2,
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

                                      return DropdownButtonFormField<
                                        WarehouseEntity
                                      >(
                                        initialValue: _selectedWarehouse,
                                        decoration: InputDecoration(
                                          labelText: 'المخزن',
                                          prefixIcon: const Icon(
                                            Icons.warehouse,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.md,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
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
                              child: DropdownButtonFormField<String>(
                                initialValue: _adjustmentReason,
                                decoration: InputDecoration(
                                  labelText: 'السبب',
                                  prefixIcon: const Icon(Icons.help_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                            ElevatedButton.icon(
                              onPressed: () => _addProductLine(context),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة صنف'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
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
                                  line.categoryId.toString() ??
                                      'صنف ${index + 1}',
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
                Card(
                  elevation: 2,
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
                      child: ElevatedButton.icon(
                        onPressed: _adjustmentLines.isEmpty
                            ? null
                            : () => _saveAdjustment('draft'),
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ كمسودة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _adjustmentLines.isEmpty
                            ? null
                            : () => _postAdjustment(),
                        icon: const Icon(Icons.check),
                        label: const Text('ترحيل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
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

  void _addProductLine(BuildContext context) {
    AppToast.showInfo(context, 'سيتم إضافة واجهة اختيار المنتج قريباً');
  }

  void _saveAdjustment(String status) {
    if (!_formKey.currentState!.validate()) return;

    AppToast.showSuccess(context, 'تم حفظ التسوية كمسودة');
  }

  void _postAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    _showAccountingPreview();
  }

  void _showAccountingPreview() {
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
                const Text(
                  'من ح/ المخزون\n'
                  '  إلى ح/ إيرادات التسوية',
                  style: TextStyle(fontFamily: 'monospace'),
                )
              else
                const Text(
                  'من ح/ مصروفات التسوية\n'
                  '  إلى ح/ المخزون',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              const SizedBox(height: 16),
              const Text(
                'هل تريد ترحيل التسوية؟',
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Post adjustment logic here
              AppToast.showSuccess(context, 'تم ترحيل التسوية بنجاح');
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ترحيل', style: TextStyle(color: Colors.white)),
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
