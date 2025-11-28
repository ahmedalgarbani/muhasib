import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/improved_step1_customer.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/payment_dialog.dart';
import 'package:muhasib/features/sales/domain/templates/improved_sales_accounting_template.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/main_drawer/main_app_drawer.dart';

class ImprovedSalesInvoiceScreen extends StatefulWidget {
  final InvoiceType invoiceType;

  const ImprovedSalesInvoiceScreen({
    Key? key,
    this.invoiceType = InvoiceType.salesInvoice,
  }) : super(key: key);

  @override
  State<ImprovedSalesInvoiceScreen> createState() => _ImprovedSalesInvoiceScreenState();
}

class _ImprovedSalesInvoiceScreenState extends State<ImprovedSalesInvoiceScreen> {
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
      currency: 'ريال سعودي',
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

    setState(() => _isSaving = true);

    try {
      // Calculate amounts
      final discountAmount = _invoice.discount.type == DiscountType.percent
          ? _invoice.subtotal * _invoice.discount.value / 100
          : _invoice.discount.value;
      final taxAmount = _invoice.subtotal * 0.15; // 15% VAT
      final totalAfterDiscount = _invoice.subtotal - discountAmount;
      final finalAmount = totalAfterDiscount + taxAmount;

      // Determine invoice type and transaction type
      final isQuotation = widget.invoiceType.isQuotation;
      final hasDeferred = _payments.any((p) => p.method == PaymentMethod.deferred);
      final totalPaid = _payments.fold(0.0, (sum, p) => sum + p.amount);
      final isFullyPaid = totalPaid >= finalAmount;

      // Create invoice lines
      final invoiceLines = _invoice.items.map((item) {
        return InvoiceLineEntity(
          invoiceType: isQuotation ? 3 : 1, // 3=quotation, 1=sales
          amount: item.price * item.quantity,
          totalAmount: item.total,
          quantity: item.quantity.toDouble(),
          groupId: int.parse(item.id),
          unitId: 1,
          categorySubUnitId: 1,
          stockId: 1, // Will be set from warehouse
          customerId: int.parse(_invoice.customer!.id),
          date: _invoice.date.millisecondsSinceEpoch ~/ 1000,
          invoiceTransType: hasDeferred || !isFullyPaid ? 1 : 0, // 1=credit, 0=cash
          netRevenueAmt: item.total,
          invoiceId: 0, // Will be set after creation
        );
      }).toList();

      // Create invoice entity
      final invoiceEntity = InvoiceEntity(
        number: _invoice.number,
        date: _invoice.date.millisecondsSinceEpoch ~/ 1000,
        customerId: int.parse(_invoice.customer!.id),
        stockId: 1, // Default warehouse
        amount: _invoice.subtotal,
        discountAmt: discountAmount,
        taxAmt: taxAmount,
        totalAmount: _invoice.subtotal,
        finalAmt: finalAmount,
        invoiceType: isQuotation ? 3 : 1,
        invoiceTransType: hasDeferred || !isFullyPaid ? 1 : 0,
        paymentStatus: isFullyPaid ? 1 : 0,
        lines: invoiceLines,
        statement: _invoice.notes,
      );

      // Save invoice using the correct method
      await context.read<SalesCubit>().addInvoice(invoiceEntity);

      // Create accounting entries if not quotation
      if (!isQuotation) {
        final entries = ImprovedSalesAccountingTemplate.createSalesInvoiceEntries(
          invoice: invoiceEntity,
          payments: _payments,
          customer: _invoice.customer!,
          inventoryCost: _calculateInventoryCost(),
        );

        // Save journal entries (implement this in your accounting system)
        for (final entry in entries) {
          // await saveJournalEntry(entry);
          debugPrint('Journal Entry: ${entry.description}');
        }

        // Update customer balance if needed
        if (!isFullyPaid || totalPaid > finalAmount) {
          final newBalance = _invoice.customer!.balance + 
              (totalPaid > finalAmount ? finalAmount - totalPaid : finalAmount - totalPaid);
          
          await context.read<CustomersCubit>().updateCustomerBalance(
            _invoice.customer!.id,
            newBalance,
          );
        }
      }

      _showSuccessSnackBar(
        isQuotation 
            ? 'تم حفظ عرض السعر بنجاح'
            : 'تم حفظ الفاتورة بنجاح',
      );

      // Navigate back
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  double _calculateInventoryCost() {
    // This should calculate actual inventory cost
    // For now, return a dummy value
    return _invoice.subtotal * 0.7; // 70% cost assumption
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        endDrawer: const MainAppDrawer(),
        appBar: CustomAppBar(
          onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
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
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE5E7EB),
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
                                        : const Color(0xFF6B7280),
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
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE5E7EB),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            
            // Step Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    _getStepTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStepSubtitle(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            
            // Step Content
            Expanded(
              child: _buildStepContent(),
            ),
            
            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(16),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'السابق',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving 
                          ? null 
                          : (_currentStep == maxStep ? _saveInvoice : _handleNext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStep == maxStep 
                            ? const Color(0xFF10B981)
                            : const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentStep == maxStep 
                                      ? 'حفظ الفاتورة'
                                      : 'التالي',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentStep == maxStep 
                                      ? Icons.check
                                      : Icons.arrow_forward,
                                  size: 20,
                                ),
                              ],
                            ),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return ImprovedStep1Customer(
          invoice: _invoice,
          onInvoiceUpdate: _updateInvoice,
          onNext: _nextStep,
        );
      case 2:
        return _buildStep2Products();
      case 3:
        return _buildStep3Totals();
      case 4:
        return _buildStep4Payment();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep2Products() {
    // Implement products selection step
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          const Text(
            'إضافة المنتجات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'هذه الخطوة قيد التطوير',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Add dummy items for testing
              setState(() {
                _invoice = _invoice.copyWith(
                  items: [
                    InvoiceItem(
                      id: '1',
                      name: 'منتج تجريبي',
                      barcode: '123456',
                      price: 100,
                      unit: 'قطعة',
                      stock: 50,
                      quantity: 2,
                    ),
                  ],
                );
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج تجريبي'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Totals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Invoice Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملخص الفاتورة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildSummaryRow('المجموع الفرعي', _invoice.subtotal),
                  _buildSummaryRow('الخصم', _invoice.discountAmount),
                  _buildSummaryRow('الضريبة (15%)', _invoice.subtotal * 0.15),
                  const Divider(),
                  _buildSummaryRow(
                    'الإجمالي',
                    _invoice.total,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Payment() {
    final totalPaid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final remaining = _invoice.total - totalPaid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Payment Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow('الإجمالي المطلوب', _invoice.total),
                  _buildSummaryRow('المدفوع', totalPaid),
                  _buildSummaryRow(
                    'المتبقي',
                    remaining,
                    isTotal: true,
                    color: remaining > 0 ? Colors.orange : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Add Payment Button
          ElevatedButton.icon(
            onPressed: _showPaymentDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة طريقة دفع'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          
          // Payments List
          if (_payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._payments.map((payment) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  payment.method == PaymentMethod.cash
                      ? Icons.payments
                      : payment.method == PaymentMethod.bank
                          ? Icons.account_balance
                          : Icons.schedule,
                  color: const Color(0xFF2563EB),
                ),
                title: Text(_getPaymentMethodName(payment.method)),
                trailing: Text(
                  NumberFormatter.formatCurrency(payment.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? const Color(0xFF10B981) : null),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.bank:
        return 'بنكي';
      case PaymentMethod.deferred:
        return 'آجل';
    }
  }

  void _handleNext() {
    // Validate current step before moving to next
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
