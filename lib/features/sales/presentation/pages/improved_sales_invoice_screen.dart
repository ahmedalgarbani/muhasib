import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/improved_step1_customer.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/improved_step2_products.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/improved_step3_totals.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/improved_step4_payment.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/payment_dialog.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/features/sales/presentation/pages/payment_editor_page.dart';

class ImprovedSalesInvoiceScreen extends StatefulWidget {
  final InvoiceType invoiceType;

  const ImprovedSalesInvoiceScreen({
    super.key,
    this.invoiceType = InvoiceType.salesInvoice,
  });

  @override
  State<ImprovedSalesInvoiceScreen> createState() =>
      _ImprovedSalesInvoiceScreenState();
}

class _ImprovedSalesInvoiceScreenState
    extends State<ImprovedSalesInvoiceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentStep = 1;
  late Invoice _invoice;
  List<Payment> _payments = [];
  bool _isSaving = false;
  int? _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    // المخزن الافتراضي من الإعدادات مع تراجع آمن
    _selectedWarehouseId = SettingsCache.defaultWarehouse;
    if (_selectedWarehouseId == 0) _selectedWarehouseId = 1;
    _invoice = Invoice(
      number: '',
      date: DateTime.now(),
      items: [],
      discount: Discount(type: DiscountType.amount, value: 0),
      payments: [],
      currency:
          'SAR', // will be replaced dynamically in _ensureCurrencyAndWarehouse()
      warehouse:
          '', // will be replaced dynamically in _ensureCurrencyAndWarehouse()
      warehouseId: _selectedWarehouseId ?? 1,
    );
    _generateNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCurrencyAndWarehouse();
    });
  }

  Future<void> _generateNumber() async {
    try {
      final isQuotation = widget.invoiceType.isQuotation;
      final sequenceType = isQuotation ? 'quotation' : 'sales_invoice';
      final service = getIt<NumberSequenceService>();
      if (!isQuotation) {
        final starting = SettingsCache.invoiceStartingNumber;
        final current = await service.getCurrentValue(sequenceType);
        if (current < starting - 1) {
          await service.resetSequence(sequenceType, starting - 1);
        }
      }
      final number = await service.getNextNumberWithPrefix(
        sequenceType,
        isQuotation
            ? SettingsCache.quotationPrefix
            : SettingsCache.invoicePrefix,
      );
      if (mounted) {
        setState(() => _invoice = _invoice.copyWith(number: number));
      }
    } catch (_) {}
  }

  Future<void> _ensureCurrencyAndWarehouse() async {
    String? dynamicCurrency;
    String? dynamicWarehouseName;
    int? dynamicWarehouseId = _selectedWarehouseId;

    // 1. Dynamic currency from CurrenciesCubit (isLocalCurrency) - replaces hard-coded 'ريال يمني'
    try {
      final currCubit = context.read<CurrenciesCubit>();
      final currState = currCubit.state;
      if (currState is CurrenciesLoaded && currState.currencies.isNotEmpty) {
        final local =
            currState.currencies.where((c) => c.isLocalCurrency).firstOrNull ??
            currState.currencies.first;
        dynamicCurrency = local.code.isNotEmpty ? local.code : local.name;
      }
    } catch (_) {}
    // Fallback to DB query if cubit not ready
    if (dynamicCurrency == null) {
      try {
        final db = await getIt<DatabaseService>().database;
        final rows = await db.query(
          'currencies',
          where: 'is_local_currency = ?',
          whereArgs: [1],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          dynamicCurrency =
              (rows.first['code'] as String?) ??
              (rows.first['name'] as String?);
        }
      } catch (_) {}
    }
    dynamicCurrency ??= 'SAR';

    // 2. Dynamic warehouse name from WarehousesCubit - replaces hard-coded 'المخزن الرئيسي'
    try {
      final whCubit = context.read<WarehousesCubit>();
      final whState = whCubit.state;
      if (whState is WarehousesLoaded && whState.warehouses.isNotEmpty) {
        final warehouses = whState.warehouses;
        final match = warehouses
            .where((w) => w.id == dynamicWarehouseId)
            .firstOrNull;
        if (match != null) {
          dynamicWarehouseName = match.name;
          dynamicWarehouseId = match.id;
        } else {
          // fallback to main stock or first warehouse
          final main =
              warehouses.where((w) => w.isMainStock == true).firstOrNull ??
              warehouses.first;
          dynamicWarehouseName = main.name;
          dynamicWarehouseId = main.id;
          _selectedWarehouseId = main.id;
        }
      }
    } catch (_) {}
    // Fallback to DB if cubit empty
    if (dynamicWarehouseName == null) {
      try {
        final db = await getIt<DatabaseService>().database;
        final rows = await db.query(
          'stocks',
          where: 'id = ?',
          whereArgs: [dynamicWarehouseId],
          limit: 1,
        );
        if (rows.isNotEmpty)
          dynamicWarehouseName = rows.first['name'] as String?;
        if (dynamicWarehouseName == null) {
          final mainRows = await db.query(
            'stocks',
            where: 'is_main_stock = ?',
            whereArgs: [1],
            limit: 1,
          );
          if (mainRows.isNotEmpty) {
            dynamicWarehouseName = mainRows.first['name'] as String?;
            dynamicWarehouseId = mainRows.first['id'] as int?;
            _selectedWarehouseId = dynamicWarehouseId;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _invoice = _invoice.copyWith(
        currency: dynamicCurrency,
        warehouse: dynamicWarehouseName ?? _invoice.warehouse,
        warehouseId: dynamicWarehouseId ?? _invoice.warehouseId,
      );
    });
  }

  void _updateInvoice(Invoice invoice) {
    setState(() {
      _invoice = invoice;
      // مزامنة اختيار المخزن المحاسبي
      if (invoice.warehouseId != null) {
        _selectedWarehouseId = invoice.warehouseId;
      }
    });
  }

  void _onWarehouseChanged(int? warehouseId, String? warehouseName) {
    setState(() {
      _selectedWarehouseId = warehouseId;
      _invoice = _invoice.copyWith(
        warehouseId: warehouseId,
        warehouse: warehouseName ?? _invoice.warehouse,
      );
    });
  }

  void _nextStep() {
    final maxStep = widget.invoiceType.isQuotation ? 3 : 4;
    if (_currentStep < maxStep) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveInvoice() async {
    if (_invoice.customer == null) {
      _showErrorSnackBar('الرجاء اختيار العميل');
      return;
    }

    if (_invoice.items.isEmpty) {
      _showErrorSnackBar('الرجاء إضافة أصناف');
      return;
    }

    setState(() => _isSaving = true);
    if (_invoice.number.isEmpty) {
      await _generateNumber();
    }
    final invoiceEntity = _buildInvoiceEntity();
    context.read<SalesCubit>().addInvoice(invoiceEntity);
  }

  InvoiceEntity _buildInvoiceEntity() {
    // استخدم نفس منطق Invoice لتجنب اختلاف الإجمالي بين الواجهة والقيد المحاسبي
    final discountAmount = _invoice.discountAmount;
    final taxAmount = _invoice.taxAmount;
    final finalAmount = _invoice.total; // يشمل otherCharges + tax بشكل دقيق

    final isQuotation = widget.invoiceType.isQuotation;
    final hasDeferred = _payments.any(
      (p) => p.method == PaymentMethod.deferred,
    );
    final totalPaid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final remainingForPay = finalAmount - totalPaid;
    final isFullyPaid = remainingForPay.abs() < 0.01 || remainingForPay <= 0.01;
    final transType = isQuotation ? 0 : (hasDeferred || !isFullyPaid ? 1 : 0);

    final cashPaid = _payments
        .where((p) => p.method == PaymentMethod.cash)
        .fold(0.0, (sum, p) => sum + p.amount);
    final bankPaid = _payments
        .where((p) => p.method == PaymentMethod.bank)
        .fold(0.0, (sum, p) => sum + p.amount);

    final headerWarehouseId =
        _selectedWarehouseId ??
        _invoice.warehouseId ??
        SettingsCache.defaultWarehouse ??
        1;
    final invoiceLines = _invoice.items.map((item) {
      return InvoiceLineEntity(
        invoiceType: isQuotation ? 3 : 1,
        amount: item.price * item.quantity,
        totalAmount: item.total,
        quantity: item.quantity.toDouble(),
        categoryId: int.tryParse(item.id),
        groupId: item.groupId ?? 1,
        unitId: item.unitId ?? 1,
        categorySubUnitId: item.subUnitId ?? 1,
        stockId: headerWarehouseId,
        customerId: int.parse(_invoice.customer!.id),
        date: _invoice.date.millisecondsSinceEpoch ~/ 1000,
        invoiceTransType: transType,
        netRevenueAmt: item.total,
        invoiceId: 0,
        // Multi-unit: الكمية الأساسية دقيقة
        baseQuantity:
            item.baseQuantity ??
            PrecisionHelper.calcBaseQuantity(
              quantity: item.quantity.toDouble(),
              packaging: item.packaging,
              conversionRate: item.conversionRate,
            ),
        conversionRate: item.conversionRate,
        packaging: item.packaging,
        costPrice: item.costPrice,
        costTotal: PrecisionHelper.roundCurrency(
          (item.costPrice ?? 0) *
              (item.baseQuantity ??
                  PrecisionHelper.calcBaseQuantity(
                    quantity: item.quantity.toDouble(),
                    packaging: item.packaging,
                    conversionRate: item.conversionRate,
                  )),
        ),
        price: item.price,
        sellingPrice: item.price,
      );
    }).toList();

    return InvoiceEntity(
      number: _invoice.number,
      date: _invoice.date.millisecondsSinceEpoch ~/ 1000,
      customerId: int.parse(_invoice.customer!.id),
      stockId: headerWarehouseId,
      amount: _invoice.subtotal,
      discountAmt: discountAmount,
      taxAmt: taxAmount,
      totalAmount: _invoice.subtotal,
      finalAmt: finalAmount,
      invoiceType: isQuotation ? 3 : 1,
      invoiceTransType: transType,
      paymentStatus: isQuotation ? 0 : (isFullyPaid ? 1 : 0),
      paidAmount: cashPaid > 0 ? cashPaid : null,
      bankPaidAmount: bankPaid > 0 ? bankPaid : null,
      lines: invoiceLines,
      statement: _invoice.notes,
    );
  }

  Future<void> _handleInvoiceCreated(int id) async {
    try {
      final isQuotation = widget.invoiceType.isQuotation;

      setState(() => _isSaving = false);
      _showSuccessSnackBar(
        isQuotation ? 'تم حفظ عرض السعر بنجاح' : 'تم حفظ الفاتورة بنجاح',
      );

      if (mounted) {
        try {
          context.read<ProductsCubit>().loadProducts();
          context.read<CustomersCubit>().loadCustomers();
          context.read<WarehousesCubit>().loadWarehouses();
        } catch (_) {}
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('حدث خطأ أثناء معالجة الفاتورة: ${e.toString()}');
    }
  }

  Future<void> _showPaymentDialog() async {
    final result = await Navigator.of(context).push<List<Payment>>(
      MaterialPageRoute(
        builder: (_) => PaymentEditorPage(
          totalAmount: _invoice.total,
          existingPayments: _payments,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _payments = result;
        _invoice = _invoice.copyWith(payments: result);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    AppToast.showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    AppToast.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final isQuotation = widget.invoiceType.isQuotation;
    final maxStep = isQuotation ? 3 : 4;

    return BlocListener<SalesCubit, SalesState>(
      listener: (context, state) {
        if (state is SalesLoading) {
          setState(() => _isSaving = true);
        } else if (state is InvoiceCreated) {
          _handleInvoiceCreated(state.id);
        } else if (state is InvoiceUpdated) {
          setState(() => _isSaving = false);
          _showSuccessSnackBar('تم تحديث الفاتورة بنجاح');
          if (mounted) context.pop();
        } else if (state is SalesError) {
          setState(() => _isSaving = false);
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: isQuotation ? 'عرض سعر جديد' : 'فاتورة مبيعات جديدة',
        ),
        body: Column(
          children: [
            // Progress Indicator
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: List.generate(maxStep * 2 - 1, (index) {
                  if (index.isOdd) {
                    final stepBefore = index ~/ 2;
                    final isLineCompleted = stepBefore < _currentStep - 1;
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: isLineCompleted
                            ? AppColors.success
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      ),
                    );
                  }
                  final stepIndex = index ~/ 2;
                  final stepNumber = stepIndex + 1;
                  final isActive = stepNumber <= _currentStep;
                  final isCompleted = stepNumber < _currentStep;

                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              stepNumber.toString(),
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.gray500,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ),

            // Step Title
            Container(
              width: double.infinity,
              padding: AppConstant.defaultPadding,
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Text(
                    _getStepTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStepSubtitle(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),

            // Step Content
            Expanded(
              child: ImprovedStepContentWidget(
                currentStep: _currentStep,
                invoice: _invoice,
                payments: _payments,
                onInvoiceUpdate: _updateInvoice,
                onNext: _nextStep,
                onAddPayment: _showPaymentDialog,
              ),
            ),

            // Navigation Buttons
            Container(
              padding: AppConstant.defaultPadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text('السابق', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 12),
                  Expanded(
                    child: HasibButton(
                      label: _currentStep == maxStep
                          ? 'حفظ الفاتورة'
                          : 'التالي',
                      onPressed: _isSaving
                          ? null
                          : (_currentStep == maxStep
                                ? _saveInvoice
                                : _handleNext),
                      loading: _isSaving,
                      leading: Icon(
                        _currentStep == maxStep
                            ? Icons.check
                            : Icons.arrow_forward,
                        size: 20,
                      ),
                      variant: _currentStep == maxStep
                          ? HasibButtonVariant.success
                          : HasibButtonVariant.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'معلومات العميل';
      case 2:
        return 'الأصناف والمنتجات';
      case 3:
        return 'الخصومات والإجماليات';
      case 4:
        return 'طرق الدفع';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 1:
        return 'اختر العميل وحدد تفاصيل الفاتورة';
      case 2:
        return 'أضف المنتجات المطلوبة';
      case 3:
        return 'راجع الإجماليات وأضف الخصومات';
      case 4:
        return 'حدد طريقة الدفع وأكمل العملية';
      default:
        return '';
    }
  }

  void _handleNext() {
    switch (_currentStep) {
      case 1:
        if (_invoice.customer == null) {
          _showErrorSnackBar('الرجاء اختيار العميل');
          return;
        }
        break;
      case 2:
        if (_invoice.items.isEmpty) {
          _showErrorSnackBar('الرجاء إضافة منتج واحد على الأقل');
          return;
        }
        break;
    }
    _nextStep();
  }
}

class ImprovedStepContentWidget extends StatelessWidget {
  final int currentStep;
  final Invoice invoice;
  final List<Payment> payments;
  final ValueChanged<Invoice> onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onAddPayment;

  const ImprovedStepContentWidget({
    super.key,
    required this.currentStep,
    required this.invoice,
    required this.payments,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onAddPayment,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 1:
        return ImprovedStep1Customer(
          invoice: invoice,
          onInvoiceUpdate: onInvoiceUpdate,
          onNext: onNext,
        );
      case 2:
        return ImprovedStep2Products(
          invoice: invoice,
          onInvoiceUpdate: onInvoiceUpdate,
        );
      case 3:
        return ImprovedStep3Totals(invoice: invoice);
      case 4:
        return ImprovedStep4Payment(
          invoice: invoice,
          payments: payments,
          onAddPayment: onAddPayment,
        );
      default:
        return const SizedBox();
    }
  }
}
