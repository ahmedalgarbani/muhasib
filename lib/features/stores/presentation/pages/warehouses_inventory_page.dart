import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_action_buttons.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_document_header_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_lines_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_notes_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_product_count_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_summary_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_type_selector.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_warehouse_selector_card.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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

  final List<Map<String, dynamic>> _inventoryTypes = const [
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
          padding: AppConstant.defaultPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InventoryTypeSelector(
                  selectedType: _inventoryType,
                  inventoryTypes: _inventoryTypes,
                  onTypeSelected: (type) {
                    setState(() => _inventoryType = type);
                  },
                ),
                const SizedBox(height: 16),
                InventoryDocumentHeaderCard(
                  inventoryNumberController: _inventoryNumberController,
                  selectedDate: _selectedDate,
                  onSelectDate: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                InventoryWarehouseSelectorCard(
                  selectedWarehouse: _selectedWarehouse,
                  onWarehouseChanged: (value) {
                    setState(() {
                      _selectedWarehouse = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_isCountMode) ...[
                  InventoryProductCountCard(
                    searchController: _searchController,
                    onScanBarcode: _scanBarcode,
                    onAddProduct: _addProductToInventory,
                  ),
                  const SizedBox(height: 16),
                ],
                InventoryLinesCard(
                  inventoryLines: _inventoryLines,
                  isCountMode: _isCountMode,
                  onQuantityChanged: (index, qty) {
                    final line = _inventoryLines[index];
                    setState(() {
                      _inventoryLines[index] = line.copyWith(
                        actualQuantity: qty,
                        difference: qty - line.quantity,
                      );
                    });
                  },
                  onDeleteLine: (index) {
                    setState(() {
                      _inventoryLines.removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_inventoryLines.isNotEmpty) ...[
                  InventorySummaryCard(inventoryLines: _inventoryLines),
                  const SizedBox(height: 16),
                ],
                InventoryNotesCard(statementController: _statementController),
                const SizedBox(height: 24),
                InventoryActionButtons(
                  isEmpty: _inventoryLines.isEmpty,
                  onSaveDraft: _saveInventory,
                  onPostInventory: _postInventory,
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
