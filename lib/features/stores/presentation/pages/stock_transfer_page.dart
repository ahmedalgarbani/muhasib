import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/presentation/cubit/stock_transfers_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/widgets/product_picker_sheet.dart';
import 'package:muhasib/features/stores/presentation/widgets/warehouse_page_sections.dart';
import 'package:muhasib/features/stores/data/datasources/inventory_local_datasource.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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
  WarehouseEntity? _sourceWarehouse;
  WarehouseEntity? _destinationWarehouse;
  final List<StockTransferLineEntity> _transferLines = [];

  bool _pendingSubmit = false;
  late final StockTransfersCubit _stockTransfersCubit;
  late final WarehousesCubit _warehousesCubit;
  late final ProductsCubit _productsCubit;

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
    _stockTransfersCubit = getIt<StockTransfersCubit>();
    _warehousesCubit = getIt<WarehousesCubit>()..loadActiveWarehouses();
    _productsCubit = getIt<ProductsCubit>()..loadProducts();
    _generateTransferNumber();
  }

  void _generateTransferNumber() {
    // Use full timestamp (13 digits) to avoid collisions — 8-digit substring cycles ~27h
    final ts = DateTime.now().millisecondsSinceEpoch;
    final micro = DateTime.now().microsecond % 1000;
    _transferNumberController.text = 'TRF-$ts${micro.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _stockTransfersCubit.close();
    _warehousesCubit.close();
    _productsCubit.close();
    _transferNumberController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _warehousesCubit),
        BlocProvider.value(value: _productsCubit),
        BlocProvider.value(value: _stockTransfersCubit),
      ],
      child: BlocListener<StockTransfersCubit, StockTransfersState>(
        bloc: _stockTransfersCubit,
        listener: (context, state) {
          if (state is TransferCreated) {
            if (_pendingSubmit) {
              _stockTransfersCubit.updateTransferStatus(
                state.id,
                TransferStatus.completed,
              );
            } else {
              AppToast.showSuccess(context, 'تم حفظ التحويل كمسودة');
              context.pop();
            }
          } else if (state is TransferStatusUpdated) {
            AppToast.showSuccess(context, 'تم ترحيل التحويل بنجاح');
            context.pop();
          } else if (state is StockTransfersError) {
            AppToast.showError(context, state.message);
          }
        },
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
            padding: AppConstant.defaultPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WarehouseTypeSelector(
                    types: _transferTypes,
                    value: _transferType,
                    height: 100,
                    width: 120,
                    onChanged: (value) => setState(() => _transferType = value),
                  ),
                  const SizedBox(height: 16),
                  WarehouseDocumentCard(
                    colorScheme: colorScheme,
                    numberController: _transferNumberController,
                    date: _selectedDate,
                    numberLabel: 'رقم التحويل',
                    onSelectDate: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  TransferWarehouseSelection(
                    colorScheme: colorScheme,
                    source: _sourceWarehouse,
                    destination: _destinationWarehouse,
                    onSourceChanged: (value) => setState(() {
                      _sourceWarehouse = value;
                      if (_destinationWarehouse?.id == value?.id) {
                        _destinationWarehouse = null;
                      }
                    }),
                    onDestinationChanged: (value) {
                      if (value?.id == _sourceWarehouse?.id) {
                        AppToast.showWarning(
                            context, 'لا يمكن اختيار نفس المخزن للوجهة');
                        return;
                      }
                      setState(() => _destinationWarehouse = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTransferLinesCard(colorScheme),
                  const SizedBox(height: 16),
                  WarehouseNotesCard(
                    colorScheme: colorScheme,
                    controller: _statementController,
                    hint: 'أدخل أي ملاحظات عن التحويل',
                  ),
                  const SizedBox(height: 12),
                  WarehouseActionButtons(
                    primaryLabel: 'ترحيل',
                    onSecondary: _saveTransfer,
                    onPrimary: _submitTransfer,
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

  Widget _buildTransferLinesCard(ColorScheme colorScheme) {
    return CustomCardContainer(
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
                Text(
                  'الأصناف المنقولة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                HasibButton(
                  label: 'إضافة صنف',
                  onPressed: _addTransferLine,
                  leading: const Icon(Icons.add),
                  variant: HasibButtonVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_transferLines.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'لا توجد أصناف مضافة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transferLines.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final line = _transferLines[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.statement,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'التكلفة: ${line.costAmount?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextInputField(
                          label: 'الكمية',
                          initialValue: line.quantity.toString(),
                          inputType: TextInputType.number,
                          onChanged: (value) {
                            final qty = double.tryParse(value) ?? 0;
                            setState(() {
                              _transferLines[index] = StockTransferLineEntity(
                                id: line.id,
                                quantity: qty,
                                statement: line.statement,
                                costAmount: line.costAmount,
                                categoryId: line.categoryId,
                                groupId: line.groupId,
                                unitId: line.unitId,
                                categorySubUnitId: line.categorySubUnitId,
                                stockTransferId: line.stockTransferId,
                              );
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() => _transferLines.removeAt(index));
                        },
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

  Future<void> _addTransferLine() async {
    if (_sourceWarehouse == null) {
      AppToast.showWarning(context, 'يرجى اختيار مخزن المصدر أولاً');
      return;
    }
    final product = await showProductPicker(context, cubit: _productsCubit);
    if (product == null || !mounted) return;

    // Fetch authoritative available qty for feedback (per-warehouse)
    double available = 0;
    try {
      final ds = getIt<InventoryLocalDataSource>();
      available = await ds.getProductQuantityInWarehouse(
          product.id!, _sourceWarehouse!.id!);
    } catch (_) {}

    // If already added, just increment if stock allows
    final existingIdx =
        _transferLines.indexWhere((l) => l.categoryId == product.id);
    if (existingIdx != -1) {
      final currentQty = _transferLines[existingIdx].quantity;
      if (available > 0 && currentQty + 1 > available) {
        AppToast.showWarning(context,
            'الكمية المطلوبة (${currentQty + 1}) أكبر من المتاح ($available)');
        return;
      }
      setState(() {
        final line = _transferLines[existingIdx];
        _transferLines[existingIdx] = StockTransferLineEntity(
          id: line.id,
          quantity: line.quantity + 1,
          statement: line.statement,
          costAmount: line.costAmount,
          categoryId: line.categoryId,
          groupId: line.groupId,
          unitId: line.unitId,
          categorySubUnitId: line.categorySubUnitId,
          stockTransferId: line.stockTransferId,
        );
      });
      AppToast.showSuccess(context, 'تمت زيادة الكمية (المتاح: $available)');
      return;
    }

    if (available == 0) {
      AppToast.showWarning(context,
          'لا يوجد رصيد لهذا المنتج في المخزن المصدر (المتاح: 0)');
      // still allow adding but warn
    }

    setState(() {
      _transferLines.add(
        StockTransferLineEntity(
          quantity: 1,
          statement: product.name,
          costAmount: product.costAmount ?? 0,
          categoryId: product.id,
          groupId: product.groupId ?? 1,
          unitId: product.unitId ?? 1,
          categorySubUnitId: 1,
        ),
      );
    });
    if (available > 0) {
      AppToast.showSuccess(context, 'تمت الإضافة (المتاح: $available)');
    }
  }

  bool _validateInput() {
    if (_sourceWarehouse == null || _destinationWarehouse == null) {
      AppToast.showError(context, 'يرجى اختيار مخزن المصدر والوجهة');
      return false;
    }
    if (_sourceWarehouse!.id == _destinationWarehouse!.id) {
      AppToast.showError(context, 'لا يمكن التحويل لنفس المخزن');
      return false;
    }
    if (_transferLines.isEmpty) {
      AppToast.showError(context, 'يرجى إضافة صنف واحد على الأقل');
      return false;
    }
    if (_transferLines.any((l) => l.quantity <= 0)) {
      AppToast.showError(context, 'يرجى إدخال كميات صحيحة للأصناف');
      return false;
    }
    return true;
  }

  StockTransferEntity _buildTransferEntity() {
    return StockTransferEntity(
      number: _transferNumberController.text,
      date: _selectedDate.millisecondsSinceEpoch ~/ 1000,
      statement: _statementController.text.trim(),
      status: TransferStatus.draft,
      fromStockId: _sourceWarehouse?.id,
      toStockId: _destinationWarehouse?.id,
      transferType: _transferType == 'regular'
          ? TransferType.regular
          : (_transferType == 'return'
                ? TransferType.returnTransfer
                : TransferType.adjustment),
      lines: _transferLines,
    );
  }

  void _saveTransfer() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateInput()) return;
    _pendingSubmit = false;
    _stockTransfersCubit.createTransfer(_buildTransferEntity());
  }

  void _submitTransfer() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateInput()) return;
    _pendingSubmit = true;
    _stockTransfersCubit.createTransfer(_buildTransferEntity());
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

  void _showTransferHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'سجل التحويلات',
        icon: Icons.history,
        content: const Text('يمكن عرض سجل التحويلات من صفحة المخازن الرئيسية'),
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
