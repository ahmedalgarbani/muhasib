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
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/widgets/warehouse_page_sections.dart';
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
                    if (_destinationWarehouse == value) {
                      _destinationWarehouse = null;
                    }
                  }),
                  onDestinationChanged: (value) =>
                      setState(() => _destinationWarehouse = value),
                ),
                const SizedBox(height: 16),
                WarehouseNotesCard(
                  colorScheme: colorScheme,
                  controller: _statementController,
                  hint: 'أدخل أي ملاحظات عن التحويل',
                ),
                const SizedBox(height: 24),
                WarehouseActionButtons(
                  primaryLabel: 'إرسال',
                  onSecondary: _saveTransfer,
                  onPrimary: _submitTransfer,
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
