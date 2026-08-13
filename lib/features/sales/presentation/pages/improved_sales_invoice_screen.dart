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
import 'package:muhasib/core/constant/app_constant.dart';

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

  @override
  void initState() {
    super.initState();
    _invoice = Invoice(
      number: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      items: [],
      discount: Discount(type: DiscountType.amount, value: 0),
      payments: [],
      currency: 'ريال يمني',
      warehouse: 'المخزن الرئيسي',
    );
  }

  void _updateInvoice(Invoice invoice) {
    setState(() => _invoice = invoice);
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

    final invoiceEntity = _buildInvoiceEntity();
    context.read<SalesCubit>().addInvoice(invoiceEntity);
  }

  InvoiceEntity _buildInvoiceEntity() {
    final discountAmount = _invoice.discount.type == DiscountType.percent
        ? _invoice.subtotal * _invoice.discount.value / 100
        : _invoice.discount.value;
    final taxAmount = _invoice.subtotal * 0.15;
    final totalAfterDiscount = _invoice.subtotal - discountAmount;
    final finalAmount = totalAfterDiscount + taxAmount;

    final isQuotation = widget.invoiceType.isQuotation;
    final hasDeferred = _payments.any(
      (p) => p.method == PaymentMethod.deferred,
    );
    final totalPaid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final isFullyPaid = totalPaid >= finalAmount;
    final transType = isQuotation ? 0 : (hasDeferred || !isFullyPaid ? 1 : 0);

    final invoiceLines = _invoice.items.map((item) {
      return InvoiceLineEntity(
        invoiceType: isQuotation ? 3 : 1,
        amount: item.price * item.quantity,
        totalAmount: item.total,
        quantity: item.quantity.toDouble(),
        groupId: int.parse(item.id),
        unitId: 1,
        categorySubUnitId: 1,
        stockId: 1,
        customerId: int.parse(_invoice.customer!.id),
        date: _invoice.date.millisecondsSinceEpoch ~/ 1000,
        invoiceTransType: transType,
        netRevenueAmt: item.total,
        invoiceId: 0,
      );
    }).toList();

    return InvoiceEntity(
      number: _invoice.number,
      date: _invoice.date.millisecondsSinceEpoch ~/ 1000,
      customerId: int.parse(_invoice.customer!.id),
      stockId: 1,
      amount: _invoice.subtotal,
      discountAmt: discountAmount,
      taxAmt: taxAmount,
      totalAmount: _invoice.subtotal,
      finalAmt: finalAmount,
      invoiceType: isQuotation ? 3 : 1,
      invoiceTransType: transType,
      paymentStatus: isQuotation ? 0 : (isFullyPaid ? 1 : 0),
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
        context.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('حدث خطأ أثناء معالجة الفاتورة: ${e.toString()}');
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        totalAmount: _invoice.total,
        existingPayments: _payments,
        onPaymentsUpdate: (payments) {
          setState(() {
            _payments = payments;
            _invoice = _invoice.copyWith(payments: payments);
          });
        },
      ),
    );
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

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SalesCubit>()),
        BlocProvider(create: (_) => getIt<CustomersCubit>()),
        BlocProvider(create: (_) => getIt<WarehousesCubit>()),
        BlocProvider(create: (_) => getIt<ProductsCubit>()),
      ],
      child: BlocListener<SalesCubit, SalesState>(
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
          backgroundColor: AppColors.neutral100,
          appBar: CustomAppBar(
            title: isQuotation ? 'عرض سعر جديد' : 'فاتورة مبيعات جديدة',
          ),
          body: Column(
            children: [
              // Progress Indicator
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(maxStep, (index) {
                    final stepNumber = index + 1;
                    final isActive = stepNumber <= _currentStep;
                    final isCompleted = stepNumber < _currentStep;

                    return Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success
                                : AppColors.gray200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Text(
                                    stepNumber.toString(),
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : AppColors.gray500,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        if (index < maxStep - 1)
                          Container(
                            width: 60,
                            height: 2,
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.gray200,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Step Title
              Container(
                width: double.infinity,
                padding: AppConstant.defaultPadding,
                color: Colors.white,
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
                  color: Colors.white,
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
