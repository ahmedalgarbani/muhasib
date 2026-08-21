import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/barcode_scanner_sheet.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_entity.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/presentation/cubit/inventory_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_action_buttons.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_document_header_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_lines_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_notes_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_product_count_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_summary_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_type_selector.dart';
import 'package:muhasib/features/stores/presentation/widgets/inventory_warehouse_selector_card.dart';
import 'package:muhasib/features/stores/presentation/widgets/product_picker_sheet.dart';
import 'package:muhasib/features/stores/data/datasources/inventory_local_datasource.dart';
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
  bool _pendingPost = false;
  late final InventoryCubit _inventoryCubit;
  late final WarehousesCubit _warehousesCubit;
  late final ProductsCubit _productsCubit;

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
    _inventoryCubit = getIt<InventoryCubit>();
    _warehousesCubit = getIt<WarehousesCubit>()..loadActiveWarehouses();
    _productsCubit = getIt<ProductsCubit>()..loadProducts();
    _generateInventoryNumber();
  }

  void _generateInventoryNumber() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final micro = DateTime.now().microsecond % 1000;
    _inventoryNumberController.text = 'INV-$ts${micro.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _inventoryCubit.close();
    _warehousesCubit.close();
    _productsCubit.close();
    _inventoryNumberController.dispose();
    _statementController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _warehousesCubit),
        BlocProvider.value(value: _productsCubit),
        BlocProvider.value(value: _inventoryCubit),
      ],
      child: BlocListener<InventoryCubit, InventoryState>(
        bloc: _inventoryCubit,
        listener: (context, state) {
          if (state is InventoryCreated) {
            if (_pendingPost) {
              _inventoryCubit.postInventory(state.id);
            } else {
              AppToast.showSuccess(context, 'تم حفظ الجرد كمسودة');
              context.pop();
            }
          } else if (state is InventoryPosted) {
            AppToast.showSuccess(context, 'تم ترحيل الجرد بنجاح');
            context.pop();
          } else if (state is InventoryError) {
            AppToast.showError(context, state.message);
          }
        },
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
                  const SizedBox(height: 12),
                  InventoryActionButtons(
                    isEmpty: _inventoryLines.isEmpty,
                    onSaveDraft: _saveInventory,
                    onPostInventory: _postInventory,
                  ),
                  const SizedBox(height: 12),
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

  Future<void> _scanBarcode() async {
    if (_selectedWarehouse == null) {
      AppToast.showWarning(context, 'يرجى اختيار المخزن أولاً');
      return;
    }

    final scannedCode = await showBarcodeScannerSheet(context);
    if (scannedCode == null || scannedCode.trim().isEmpty || !mounted) return;

    final code = scannedCode.trim();
    _searchController.text = code;
    await _processProductCodeOrSearch(code);
  }

  Future<void> _addProductToInventory() async {
    if (_selectedWarehouse == null) {
      AppToast.showWarning(context, 'يرجى اختيار المخزن أولاً');
      return;
    }

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final handled = await _processProductCodeOrSearch(query);
      if (handled) return;
    }

    final product = await showProductPicker(context, cubit: _productsCubit);
    if (product == null || !mounted) return;

    await _addOrIncrementProductInInventory(product);
    _searchController.clear();
  }

  Future<bool> _processProductCodeOrSearch(String query) async {
    final state = _productsCubit.state;
    final products = state is ProductsLoaded
        ? state.products
        : <ProductEntity>[];

    ProductEntity? matchedProduct;
    final qLower = query.toLowerCase();

    for (final p in products) {
      if (p.barcodeNo.toLowerCase() == qLower ||
          p.id.toString() == query ||
          p.name.toLowerCase() == qLower) {
        matchedProduct = p;
        break;
      }
    }

    if (matchedProduct != null) {
      await _addOrIncrementProductInInventory(matchedProduct);
      _searchController.clear();
      return true;
    } else {
      AppToast.showWarning(
        context,
        'لم يتم العثور على منتج بالباركود/الاسم: $query',
      );
      return false;
    }
  }

  Future<void> _addOrIncrementProductInInventory(ProductEntity product) async {
    // Authoritative quantity is per-warehouse (warehouse_stocks), not global product.quantity
    double systemQty = product.quantity;
    if (_selectedWarehouse != null && product.id != null) {
      try {
        final ds = getIt<InventoryLocalDataSource>();
        systemQty = await ds.getProductQuantityInWarehouse(
            product.id!, _selectedWarehouse!.id!);
      } catch (_) {
        // Fallback to global quantity if datasource unavailable
        systemQty = product.quantity;
      }
    }

    final existingIndex = _inventoryLines.indexWhere(
      (l) => l.categoryId == product.id,
    );

    if (existingIndex != -1) {
      final line = _inventoryLines[existingIndex];
      final newActualQty = line.actualQuantity + 1;
      setState(() {
        _inventoryLines[existingIndex] = line.copyWith(
          actualQuantity: newActualQty,
          difference: newActualQty - line.quantity,
        );
      });
      AppToast.showSuccess(
        context,
        'تمت زيادة كمية الجرد للمنتج: ${product.name} (+1)',
      );
    } else {
      setState(() {
        _inventoryLines.add(
          InventoryLineEntity(
            statement: product.name,
            quantity: systemQty,
            actualQuantity: 1,
            difference: 1 - systemQty,
            costAmount: product.costAmount ?? 0,
            categoryId: product.id,
            groupId: product.groupId ?? 1,
            unitId: product.unitId ?? 1,
            categorySubUnitId: 1,
            inventoryId: 0,
          ),
        );
      });
      AppToast.showSuccess(
        context,
        'تمت إضافة المنتج إلى الجرد: ${product.name} (النظام: $systemQty)',
      );
    }
  }

  bool _validateInventory() {
    if (_selectedWarehouse == null) {
      AppToast.showError(context, 'يرجى اختيار المخزن');
      return false;
    }
    if (_inventoryLines.isEmpty) {
      AppToast.showError(context, 'يرجى إضافة صنف واحد على الأقل');
      return false;
    }
    return true;
  }

  InventoryEntity _buildInventoryEntity() {
    final totalDifference = _inventoryLines.fold<double>(
      0,
      (sum, line) => sum + (line.actualQuantity - line.quantity),
    );
    return InventoryEntity(
      number: _inventoryNumberController.text,
      date: _selectedDate.millisecondsSinceEpoch ~/ 1000,
      statement: _statementController.text.trim(),
      inventoryType: _inventoryType == 'periodic'
          ? InventoryType.periodic
          : _inventoryType == 'cycle'
          ? InventoryType.cycle
          : _inventoryType == 'annual'
          ? InventoryType.annual
          : InventoryType.spot,
      status: TransferStatus.draft,
      stockId: _selectedWarehouse?.id,
      totalDifference: totalDifference,
      lines: _inventoryLines,
    );
  }

  void _saveInventory() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateInventory()) return;

    _pendingPost = false;
    _inventoryCubit.createInventory(_buildInventoryEntity());
  }

  void _postInventory() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateInventory()) return;

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
              _pendingPost = true;
              _inventoryCubit.createInventory(_buildInventoryEntity());
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
