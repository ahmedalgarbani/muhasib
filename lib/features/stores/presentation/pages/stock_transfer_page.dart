import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/custom_text_field.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

class StockTransferPage extends StatefulWidget {
  const StockTransferPage({super.key});

  @override
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _transferNumberController = TextEditingController();
  final _statementController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _transferType = 'regular'; // 'regular', 'return', 'adjustment'
  final String _transferStatus =
      'draft'; // 'draft', 'pending', 'in_transit', 'completed'
  WarehouseEntity? _sourceWarehouse;
  WarehouseEntity? _destinationWarehouse;
  final List<StockTransferLineEntity> _transferLines = [];

  final List<Map<String, dynamic>> _transferTypes = [
    {
      'value': 'regular',
      'label': 'تحويل عادي',
      'icon': Icons.swap_horiz,
      'color': Colors.blue,
    },
    {
      'value': 'return',
      'label': 'إرجاع',
      'icon': Icons.undo,
      'color': Colors.orange,
    },
    {
      'value': 'adjustment',
      'label': 'تسوية',
      'icon': Icons.tune,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateTransferNumber();
  }

  void _generateTransferNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _transferNumberController.text =
        'TRF-${timestamp.substring(timestamp.length - 8)}';
  }

  @override
  void dispose() {
    _transferNumberController.dispose();
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
      ],
      child: Scaffold(
        backgroundColor: AppColors.neutral100,
        appBar: CustomAppBar(
          title: 'تحويل مخزني',
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showTransferHistory(context),
              tooltip: 'سجل التحويلات',
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
                _buildTransferTypeSelection(),
                const SizedBox(height: 16),
                _buildDocumentHeaderCard(colorScheme),
                const SizedBox(height: 16),
                _buildWarehouseSelectionCard(colorScheme),
                const SizedBox(height: 16),
                _buildNotesCard(colorScheme),
                const SizedBox(height: 24),
                _buildActionButtons(colorScheme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferTypeSelection() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _transferTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = _transferTypes[index];
          final isSelected = _transferType == type['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _transferType = type['value']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120,
              decoration: BoxDecoration(
                color: isSelected
                    ? (type['color'] as Color).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? type['color'] as Color
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: isSelected
                        ? type['color'] as Color
                        : Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type['label'],
                    style: TextStyle(
                      color: isSelected
                          ? type['color'] as Color
                          : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentHeaderCard(ColorScheme colorScheme) {
    return CustomCardContainer(
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
                Icon(Icons.receipt_long, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'بيانات المستند',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _transferNumberController,
                    label: 'رقم التحويل',
                    hint: 'رقم التحويل',
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
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
    );
  }

  Widget _buildWarehouseSelectionCard(ColorScheme colorScheme) {
    return CustomCardContainer(
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
                Icon(Icons.warehouse, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'المخازن',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<WarehousesCubit, WarehousesState>(
              builder: (context, state) {
                List<WarehouseEntity> warehouses = [];
                if (state is WarehousesLoaded) {
                  warehouses = state.warehouses;
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'من المخزن',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomDropdownField<WarehouseEntity>(
                                value: _sourceWarehouse,
                                hint: 'اختر المخزن المصدر',
                                prefixIcon: const Icon(Icons.output),
                                items: warehouses.map((warehouse) {
                                  return DropdownMenuItem(
                                    value: warehouse,
                                    child: Text(warehouse.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _sourceWarehouse = value;
                                    // Ensure source and destination are different
                                    if (_destinationWarehouse == value) {
                                      _destinationWarehouse = null;
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'يرجى اختيار المخزن المصدر';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.arrow_forward,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'إلى المخزن',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomDropdownField<WarehouseEntity>(
                                value: _destinationWarehouse,
                                hint: 'اختر المخزن الوجهة',
                                prefixIcon: const Icon(Icons.input),
                                items: warehouses
                                    .where((w) => w != _sourceWarehouse)
                                    .map((warehouse) {
                                      return DropdownMenuItem(
                                        value: warehouse,
                                        child: Text(warehouse.name),
                                      );
                                    })
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _destinationWarehouse = value);
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'يرجى اختيار المخزن الوجهة';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ColorScheme colorScheme) {
    return CustomCardContainer(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _statementController,
              label: 'الملاحظات',
              hint: 'أدخل أي ملاحظات عن التحويل',
              prefixIcon: Icons.comment,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: HasibButton(
            label: 'حفظ كمسودة',
            leading: const Icon(Icons.save),
            onPressed: () => _saveTransfer(),
            variant: HasibButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: HasibButton(
            label: 'إرسال',
            leading: const Icon(Icons.send, color: Colors.white),
            onPressed: () => _submitTransfer(),
            variant: HasibButtonVariant.primary,
          ),
        ),
      ],
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

  void _saveTransfer() {
    if (!_formKey.currentState!.validate()) return;
    AppToast.showSuccess(context, 'تم حفظ التحويل كمسودة');
  }

  void _submitTransfer() {
    if (!_formKey.currentState!.validate()) return;
    AppToast.showSuccess(context, 'تم إرسال التحويل بنجاح');
    context.pop();
  }

  void _showTransferHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'سجل التحويلات',
        icon: Icons.history,
        content: const Text('سيتم عرض سجل التحويلات السابقة هنا'),
        actions: [
          HasibButton(
            label: 'إغلاق',
            onPressed: () => Navigator.pop(context),
            variant: HasibButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
