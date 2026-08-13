import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/step1_customer.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/step2_items.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/step3_payment.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/step4_review.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/sticky_invoice_header.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/step_indicator.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/customer_bottom_sheet.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:go_router/go_router.dart';

class SalesInvoiceScreen extends StatefulWidget {
  final InvoiceType invoiceType;

  const SalesInvoiceScreen({
    super.key,
    this.invoiceType = InvoiceType.salesInvoice,
  });

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  int _currentStep = 1;
  late Invoice _invoice;

  @override
  void initState() {
    super.initState();
    _invoice = Invoice(
      number: '',
      date: DateTime.now(),
      items: [],
      discount: Discount(type: DiscountType.amount, value: 0),
      payments: [],
    );

    _generateNumber();

    // Load customers (from customers table) and products
    context.read<CustomersCubit>().loadCustomers();
    context.read<ProductsCubit>().loadProducts();
  }

  Future<void> _generateNumber() async {
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
  }

  void _updateInvoice(Invoice invoice) {
    setState(() => _invoice = invoice);
  }

  void _nextStep() {
    final maxStep = widget.invoiceType.isQuotation ? 3 : 4;
    if (_currentStep < maxStep) setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 1) setState(() => _currentStep--);
  }

  void _showCustomerBottomSheet(List<Customer> customers) {
    CustomerBottomSheet.show(
      context,
      customers: customers,
      onSelect: (customer) {
        setState(() => _invoice = _invoice.copyWith(customer: customer));
      },
    );
  }

  Future<void> _saveInvoice() async {
    if (_invoice.customer == null) {
      AppToast.showError(context, 'الرجاء اختيار العميل');
      return;
    }

    if (_invoice.items.isEmpty) {
      AppToast.showError(context, 'الرجاء إضافة أصناف');
      return;
    }

    if (_invoice.number.isEmpty) {
      await _generateNumber();
    }

    // Calculate discount and tax amounts
    final discountAmount = _invoice.discount.type == DiscountType.percent
        ? _invoice.subtotal * _invoice.discount.value / 100
        : _invoice.discount.value;
    final taxAmount = _invoice.taxAmount;
    final totalAfterDiscount = _invoice.subtotal - discountAmount;
    final finalAmount = totalAfterDiscount + taxAmount;

    // Derive safe foreign keys and statuses
    final isQuotation = widget.invoiceType.isQuotation;
    final selectedCustomerId = int.tryParse(_invoice.customer!.id);
    final derivedCustomerId =
        (selectedCustomerId == 1 || selectedCustomerId == 2)
        ? selectedCustomerId
        : (_invoice.payments.any((p) => p.method == PaymentMethod.deferred)
              ? 2
              : 1);
    final derivedTransType = isQuotation
        ? 0
        : (_invoice.remaining > 0 ? 1 : 0); // 0=cash, 1=deferred
    final derivedPaymentStatus = isQuotation
        ? 0
        : (_invoice.paid >= _invoice.total
            ? 2 // fully paid
            : (_invoice.paid > 0 ? 1 : 0)); // 1=partial, 0=unpaid

    // Map local Invoice to InvoiceEntity with all required fields
    final invoiceEntity = InvoiceEntity(
      invoiceType: widget.invoiceType.value,
      number: _invoice.number,
      date: _invoice.date.millisecondsSinceEpoch,
      statement: '', // Optional statement
      amount: _invoice.subtotal,
      totalAmount: _invoice.total,
      taxAmt: taxAmount,
      taxRatio: SettingsCache.taxEnabled ? SettingsCache.defaultTaxRate : 0.0,
      discountAmt: discountAmount,
      discountRatio: _invoice.discount.type == DiscountType.percent
          ? _invoice.discount.value
          : 0.0,
      otherFeeAmt: 0.0,
      otherFeeNetRatio: 0.0,
      netRevenueAmt: finalAmount,
      totalAmountAfterDiscount: totalAfterDiscount,
      finalAmt: finalAmount,
      currencyId: null, // Avoid FK if currencies are not seeded
      currencyCode: 'SAR', // Default currency code
      exchangeRate: 1.0,
      customerId: derivedCustomerId ?? 1,
      stockId: SettingsCache.defaultWarehouse,
      invoiceTransType: derivedTransType,
      paymentStatus: derivedPaymentStatus,
      creatorId: 1, // Default user
      lastModifierId: 1, // Default user
      creationTime: DateTime.now().millisecondsSinceEpoch,
      lastModificationTime: DateTime.now().millisecondsSinceEpoch,
      lines: _invoice.items.map((item) {
        final lineDiscountAmt = 0.0; // No line discount for now
        final lineTaxAmt = 0.0; // No line tax for now
        final lineTotalAmt = item.price * item.quantity;

        return InvoiceLineEntity(
          invoiceType: widget.invoiceType.value,
          amount: item.price,
          totalAmount: lineTotalAmt,
          taxAmt: lineTaxAmt,
          taxRatio: 0,
          discountAmt: lineDiscountAmt,
          discountRatio: 0,
          otherFeeAmt: 0.0,
          otherFeeNetRatio: 0,
          netRevenueAmt: lineTotalAmt,
          quantity: item.quantity.toDouble(),
          groupId: 1, // TODO: Get from product
          unitId: 1, // TODO: Get from product
          categorySubUnitId: 1, // Required field - using default
          stockId: SettingsCache.defaultWarehouse,
          categoryId: int.tryParse(item.id) ?? 1, // Use item ID as category ID
          invoiceId: 0, // Will be set by database
          customerId: derivedCustomerId ?? 1,
          invoiceTransType: derivedTransType,
          date: _invoice.date.millisecondsSinceEpoch,
          creatorId: 1,
          lastModifierId: 1,
          creationTime: DateTime.now().millisecondsSinceEpoch,
          lastModificationTime: DateTime.now().millisecondsSinceEpoch,
        );
      }).toList(),
    );

    // Call Cubit
    if (!mounted) return;
    await context.read<SalesCubit>().addInvoice(invoiceEntity);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesCubit, SalesState>(
      listener: (context, state) {
        if (state is InvoiceCreated) {
          AppToast.showSuccess(context, 'تم حفظ الفاتورة بنجاح');
          context.pop(); // Go back
        } else if (state is SalesError) {
          AppToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: widget.invoiceType == InvoiceType.quotation
              ? 'عرض سعر جديد'
              : 'فاتورة مبيعات جديدة',
        ),
        body: SafeArea(
          child: BlocBuilder<CustomersCubit, CustomersState>(
            builder: (context, customersState) {
              final customers = customersState is CustomersLoaded
                  ? customersState.customers
                  : <Customer>[];

              return BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, productsState) {
                  List<InvoiceItem> availableItems = [];
                  if (productsState is ProductsLoaded) {
                    availableItems = productsState.products
                        .map(
                          (p) => InvoiceItem(
                            id: p.id?.toString() ?? '0',
                            name: p.name,
                            barcode: p.barcodeNo,
                            price: p.sellAmount ?? 0,
                            unit: p.unitId?.toString() ?? 'قطعة',
                            stock: p.quantity.toInt(),
                            costPrice: p.costAmount,
                            trackInventory: p.trackInventory,
                          ),
                        )
                        .toList();
                  }

                  return Column(
                    children: [
                      if (_currentStep <= 2)
                        StickyInvoiceHeader(
                          invoice: _invoice,
                          onCustomerTap: () =>
                              _showCustomerBottomSheet(customers),
                        ),
                      StepIndicator(
                        currentStep: _currentStep,
                        steps: widget.invoiceType.isQuotation
                            ? const ['العميل', 'الأصناف', 'المراجعة']
                            : const ['العميل', 'الأصناف', 'الدفع', 'المراجعة'],
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _currentStep - 1,
                          children: [
                            Step1Customer(
                              invoice: _invoice,
                              customers: customers,
                              onInvoiceUpdate: _updateInvoice,
                              onNext: _nextStep,
                              onShowCustomerSheet: () =>
                                  _showCustomerBottomSheet(customers),
                            ),
                            Step2Items(
                              invoice: _invoice,
                              availableItems: availableItems,
                              onInvoiceUpdate: _updateInvoice,
                              onNext: _nextStep,
                              onPrevious: _previousStep,
                            ),
                            if (!widget.invoiceType.isQuotation)
                              Step3Payment(
                                invoice: _invoice,
                                onInvoiceUpdate: _updateInvoice,
                                onNext: _nextStep,
                                onPrevious: _previousStep,
                              ),
                            Step4Review(
                              invoice: _invoice,
                              onPrevious: _previousStep,
                              onSave: _saveInvoice,
                              isQuotation: widget.invoiceType.isQuotation,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
