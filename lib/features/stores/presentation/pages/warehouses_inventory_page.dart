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
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

class WarehousesInventoryPage extends StatefulWidget {
  const WarehousesInventoryPage({super.key});

  @override
  State<WarehousesInventoryPage> createState() =>
      _WarehousesInventoryPageState();
}

class _WarehousesInventoryPageState extends State<WarehousesInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryNumberController = TextEditingController();
  final _statementController = TextEditingController();
  final _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _inventoryType = 'spot'; // 'periodic', 'cycle', 'spot', 'annual'
  WarehouseEntity? _selectedWarehouse;
  final List<InventoryLineEntity> _inventoryLines = [];
  bool _isCountMode = false;

  final List<Map<String, dynamic>> _inventoryTypes = [
    {
      'value': 'spot',
      'label': 'جرد فوري',
      'icon': Icons.flash_on,
      'color': Colors.orange,
    },
    {
      'value': 'periodic',
      'label': 'جرد دوري',
      'icon': Icons.schedule,
      'color': Colors.blue,
    },
    {
      'value': 'cycle',
      'label': 'جرد دائري',
      'icon': Icons.autorenew,
      'color': Colors.green,
    },
    {
      'value': 'annual',
      'label': 'جرد سنوي',
      'icon': Icons.event_available,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateInventoryNumber();
  }

  void _generateInventoryNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _inventoryNumberController.text =
        'INV-${timestamp.substring(timestamp.length - 8)}';
  }

  @override
  void dispose() {
    _inventoryNumberController.dispose();
    _statementController.dispose();
    _searchController.dispose();
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
          title: 'جرد المخزون',
          actions: [
            IconButton(
              icon: Icon(_isCountMode ? Icons.edit : Icons.inventory),
              onPressed: () {
                setState(() => _isCountMode = !_isCountMode);
              },
              tooltip: _isCountMode ? 'وضع التحرير' : 'وضع الجرد',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _inventoryLines.isEmpty
                  ? null
                  : () => _printInventoryReport(),
              tooltip: 'طباعة التقرير',
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
                // Inventory Type Selection
                _buildInventoryTypeSelection(),
                const SizedBox(height: 16),

                // Document Header Card
                _buildDocumentHeaderCard(colorScheme),
                const SizedBox(height: 16),

                // Warehouse Selection Card
                _buildWarehouseSelectionCard(colorScheme),
                const SizedBox(height: 16),

                // Product Search & Count Card
                if (_isCountMode) _buildProductCountCard(colorScheme),

                // Inventory Lines Card
                _buildInventoryLinesCard(colorScheme),
                const SizedBox(height: 16),

                // Summary Card
                if (_inventoryLines.isNotEmpty) _buildSummaryCard(colorScheme),

                // Notes Card
                _buildNotesCard(colorScheme),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(colorScheme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryTypeSelection() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _inventoryTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = _inventoryTypes[index];
          final isSelected = _inventoryType == type['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _inventoryType = type['value']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              decoration: BoxDecoration(
                color: isSelected
                    ? (type['color'] as Color).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
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
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['label'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? type['color'] as Color
                          : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
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
                    controller: _inventoryNumberController,
                    label: 'رقم الجرد',
                    hint: 'رقم الجرد',
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
                List<WarehouseEntity> warehouses = [];
                if (state is WarehousesLoaded) {
                  warehouses = state.warehouses;
                }

                return CustomDropdownField<WarehouseEntity>(
                  value: _selectedWarehouse,
                  label: 'اختر المخزن',
                  prefixIcon: const Icon(Icons.store),
                  items: warehouses.map((warehouse) {
                    return DropdownMenuItem(
                      value: warehouse,
                      child: Text(warehouse.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWarehouse = value;
                      // Load products for selected warehouse if needed
                    });
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
          ],
        ),
      ),
    );
  }

  Widget _buildProductCountCard(ColorScheme colorScheme) {
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
                Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'إضافة منتج للجرد',
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
                    controller: _searchController,
                    label: 'البحث عن منتج',
                    hint: 'اسم المنتج أو الباركود',
                    prefixIcon: Icons.search,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _scanBarcode(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                HasibButton(
                  label: 'إضافة',
                  onPressed: () => _addProductToInventory(),
                  leading: const Icon(Icons.add),
                  variant: HasibButtonVariant.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryLinesCard(ColorScheme colorScheme) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'قائمة الجرد',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_inventoryLines.isNotEmpty)
                  Text(
                    '${_inventoryLines.length} صنف',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_inventoryLines.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد أصناف للجرد',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (!_isCountMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'انتقل لوضع الجرد لبدء العد',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _inventoryLines.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return _buildInventoryLineItem(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryLineItem(int index) {
    final line = _inventoryLines[index];
    final difference = line.actualQuantity - line.quantity;
    final isPositive = difference >= 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        line.statement.isNotEmpty ? line.statement : 'صنف ${index + 1}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'متوقع: ${line.quantity} | فعلي: ${line.actualQuantity}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'الفرق: ${difference > 0 ? '+' : ''}$difference',
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: _isCountMode
          ? SizedBox(
              width: 100,
              child: TextInputField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                hint: '0',
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final qty = double.tryParse(value) ?? 0;
                  setState(() {
                    _inventoryLines[index] = line.copyWith(
                      actualQuantity: qty,
                      difference: qty - line.quantity,
                    );
                  });
                },
                controller: TextEditingController(
                  text: line.actualQuantity.toString(),
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _inventoryLines.removeAt(index);
                });
              },
            ),
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    final totalExpected = _inventoryLines.fold<double>(
      0,
      (sum, line) => sum + line.quantity,
    );
    final totalActual = _inventoryLines.fold<double>(
      0,
      (sum, line) => sum + line.actualQuantity,
    );
    final totalDifference = totalActual - totalExpected;

    return CustomCardContainer(
      elevation: 2,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'المتوقع',
                  totalExpected.toString(),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'الفعلي',
                  totalActual.toString(),
                  Colors.green,
                ),
                _buildSummaryItem(
                  'الفرق',
                  '${totalDifference > 0 ? '+' : ''}$totalDifference',
                  totalDifference >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
              hint: 'أدخل أي ملاحظات عن الجرد',
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
          child: OutlinedButton.icon(
            onPressed: _inventoryLines.isEmpty ? null : () => _saveInventory(),
            icon: const Icon(Icons.save),
            label: const Text('حفظ كمسودة'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: HasibButton(
            label: 'ترحيل الجرد',
            onPressed: _inventoryLines.isEmpty ? null : () => _postInventory(),
            leading: const Icon(Icons.check),
            variant: HasibButtonVariant.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _scanBarcode() {
    AppToast.showInfo(context, 'سيتم إضافة ماسح الباركود قريباً');
  }

  void _addProductToInventory() {
    if (_selectedWarehouse == null) {
      AppToast.showWarning(context, 'يرجى اختيار المخزن أولاً');
      return;
    }

    final productName = _searchController.text.trim();
    if (productName.isEmpty) {
      AppToast.showWarning(context, 'يرجى أدخال اسم المنتج أو الباركود');
      return;
    }

    setState(() {
      _inventoryLines.add(
        InventoryLineEntity(
          statement: productName,
          quantity: 0,
          actualQuantity: 0,
          difference: 0,
          costAmount: 0,
          categoryId: 0,
          groupId: 1,
          unitId: 1,
          categorySubUnitId: 1,
          inventoryId: 0,
        ),
      );
    });
    _searchController.clear();
  }

  void _saveInventory() {
    if (!_formKey.currentState!.validate()) return;

    AppToast.showSuccess(context, 'تم حفظ الجرد كمسودة');
  }

  void _postInventory() {
    if (!_formKey.currentState!.validate()) return;

    _showPostConfirmation();
  }

  void _showPostConfirmation() {
    final totalDifference = _inventoryLines.fold<double>(
      0,
      (sum, line) => sum + (line.actualQuantity - line.quantity),
    );

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: const Text('ترحيل الجرد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'سيتم إنشاء تسويات مخزنية للفروقات:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (totalDifference > 0)
                Text(
                  '• زيادة: $totalDifference وحدة',
                  style: const TextStyle(color: Colors.green),
                )
              else if (totalDifference < 0)
                Text(
                  '• نقص: ${totalDifference.abs()} وحدة',
                  style: const TextStyle(color: Colors.red),
                )
              else
                const Text(
                  '• لا توجد فروقات',
                  style: TextStyle(color: Colors.blue),
                ),
              const SizedBox(height: 16),
              const Text(
                'هل تريد المتابعة؟',
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
              AppToast.showSuccess(context, 'تم ترحيل الجرد بنجاح');
              context.pop();
            },
            variant: HasibButtonVariant.success,
          ),
        ],
      ),
    );
  }

  void _printInventoryReport() {
    AppToast.showInfo(context, 'طباعة تقرير الجرد...');
  }
}
