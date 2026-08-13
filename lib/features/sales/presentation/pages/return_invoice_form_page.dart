import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ReturnInvoiceFormPage extends StatefulWidget {
  final int? originalInvoiceId;

  const ReturnInvoiceFormPage({super.key, this.originalInvoiceId});

  @override
  State<ReturnInvoiceFormPage> createState() => _ReturnInvoiceFormPageState();
}

class _ReturnInvoiceFormPageState extends State<ReturnInvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();

  InvoiceEntity? _originalInvoice;
  List<InvoiceLineEntity> _returnItems = [];
  final Map<int, double> _returnQuantities = {};

  final _returnNumberController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double _totalReturnAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _returnDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _generateReturnNumber();
    if (widget.originalInvoiceId != null) {
      _loadOriginalInvoice();
    }
    // Load customers to get names
    context.read<CustomersCubit>().loadCustomers();
  }

  void _generateReturnNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _returnNumberController.text = 'RET-${timestamp.toString().substring(7)}';
  }

  void _loadOriginalInvoice() {
    context.read<SalesCubit>().loadInvoices();
  }

  @override
  void dispose() {
    _returnNumberController.dispose();
    _returnDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
        BlocProvider(create: (context) => getIt<CustomersCubit>()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: CustomAppBar(
          title: 'إنشاء مرتجع مبيعات',
          actions: [
            TextButton(
              onPressed: _saveReturn,
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: BlocListener<SalesCubit, SalesState>(
          listener: (context, state) {
            if (state is SalesLoaded) {
              if (widget.originalInvoiceId != null) {
                try {
                  final invoice = state.invoices.firstWhere(
                    (inv) => inv.id == widget.originalInvoiceId,
                  );
                  setState(() {
                    _originalInvoice = invoice;
                    _returnItems = List.from(invoice.lines);
                    for (var item in _returnItems) {
                      _returnQuantities[item.id ?? 0] = 0;
                    }
                  });
                } catch (e) {
                  AppToast.showError(context, 'الفاتورة الأصلية غير موجودة');
                }
              }
            } else if (state is ReturnInvoiceCreated) {
              AppToast.showSuccess(context, 'تم إنشاء المرتجع بنجاح');
              Navigator.pop(context);
            } else if (state is SalesError) {
              AppToast.showError(context, state.message);
            }
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: AppConstant.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Return Info Card
                  CustomCardContainer(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: AppConstant.defaultPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معلومات المرتجع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextInputField(
                                  label: 'رقم المرتجع',
                                  textEditingController:
                                      _returnNumberController,
                                  readOnly: true,
                                  prefixIcon: const Icon(Icons.tag),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextInputField(
                                  label: 'التاريخ',
                                  textEditingController: _returnDateController,
                                  readOnly: true,
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedDate = picked;
                                        _returnDateController.text = DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(picked);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextInputField(
                            label: 'سبب المرتجع',
                            textEditingController: _reasonController,
                            maxLines: 2,
                            hint: 'اكتب سبب إرجاع البضاعة...',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال سبب المرتجع';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Original Invoice Selection
                  if (_originalInvoice == null)
                    CustomCardContainer(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: AppConstant.defaultPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'اختر الفاتورة الأصلية',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<SalesCubit, SalesState>(
                              builder: (context, state) {
                                if (state is SalesLoaded) {
                                  final salesInvoices = state.invoices
                                      .where(
                                        (inv) =>
                                            inv.invoiceType ==
                                            InvoiceType.salesInvoice.value,
                                      )
                                      .toList();

                                  return CustomDropdownField<int>(
                                    label: 'الفاتورة الأصلية',
                                    prefixIcon: const Icon(Icons.receipt),
                                    value: null,
                                    items: salesInvoices.map((invoice) {
                                      return DropdownMenuItem(
                                        value: invoice.id,
                                        child: Text(
                                          '${invoice.number} - ${_formatDate(invoice.date)}',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        try {
                                          final invoice = state.invoices
                                              .firstWhere(
                                                (inv) => inv.id == value,
                                              );
                                          setState(() {
                                            _originalInvoice = invoice;
                                            _returnItems = List.from(
                                              invoice.lines,
                                            );
                                            for (var item in _returnItems) {
                                              _returnQuantities[item.id ?? 0] =
                                                  0;
                                            }
                                          });
                                        } catch (e) {
                                          AppToast.showError(
                                            context,
                                            'الفاتورة غير موجودة',
                                          );
                                        }
                                      }
                                    },
                                    errorText: null,
                                  );
                                }
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Original Invoice Info
                  if (_originalInvoice != null)
                    CustomCardContainer(
                      elevation: 0,
                      color: AppColors.amber100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(color: AppColors.amber400),
                      ),
                      child: Padding(
                        padding: AppConstant.defaultPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: AppColors.amber800,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'الفاتورة الأصلية',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.amber800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'رقم: ${_originalInvoice!.number}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'التاريخ: ${_formatDate(_originalInvoice!.date)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'المبلغ الإجمالي: ${_formatCurrency(_originalInvoice!.finalAmt ?? _originalInvoice!.amount)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Return Items
                  if (_returnItems.isNotEmpty) ...[
                    const Text(
                      'الأصناف المرتجعة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_returnItems.length, (index) {
                      final item = _returnItems[index];
                      final itemId = item.id ?? index;
                      final returnQty = _returnQuantities[itemId] ?? 0;

                      return CustomCardContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'صنف #${item.categoryId ?? item.groupId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'الكمية الأصلية: ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          'السعر: ${_formatCurrency(item.amount)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextInputField(
                                      label: 'كمية المرتجع',
                                      initialValue: returnQty.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final qty = double.tryParse(value) ?? 0;
                                        setState(() {
                                          _returnQuantities[itemId] = qty;
                                          _calculateTotal();
                                        });
                                      },
                                      validator: (value) {
                                        final qty =
                                            double.tryParse(value ?? '0') ?? 0;
                                        if (qty < 0) {
                                          return 'كمية غير صحيحة';
                                        }
                                        if (qty > item.quantity) {
                                          return 'تجاوزت الكمية الأصلية';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // Total
                  const SizedBox(height: 16),
                  CustomCardContainer(
                    elevation: 0,
                    color: AppColors.red100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Padding(
                      padding: AppConstant.defaultPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إجمالي المرتجع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.red800,
                            ),
                          ),
                          Text(
                            _formatCurrency(_totalReturnAmount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.red800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _returnItems) {
      final itemId = item.id ?? 0;
      final returnQty = _returnQuantities[itemId] ?? 0;
      total += returnQty * item.amount;
    }
    setState(() {
      _totalReturnAmount = total;
    });
  }

  void _saveReturn() {
    if (_formKey.currentState!.validate()) {
      if (_originalInvoice == null) {
        AppToast.showError(context, 'يرجى اختيار الفاتورة الأصلية');
        return;
      }

      final hasReturnItems = _returnQuantities.values.any((qty) => qty > 0);
      if (!hasReturnItems) {
        AppToast.showError(context, 'يرجى إدخال كمية مرتجعة واحدة على الأقل');
        return;
      }

      final returnLines = <InvoiceLineEntity>[];
      for (var item in _returnItems) {
        final itemId = item.id ?? 0;
        final returnQty = _returnQuantities[itemId] ?? 0;
        if (returnQty > 0) {
          returnLines.add(
            InvoiceLineEntity(
              id: item.id,
              invoiceId: item.invoiceId,
              categoryId: item.categoryId,
              groupId: item.groupId,
              unitId: item.unitId,
              categorySubUnitId: item.categorySubUnitId,
              stockId: item.stockId,
              customerId: item.customerId,
              date: item.date,
              invoiceType: item.invoiceType,
              invoiceTransType: item.invoiceTransType,
              quantity: returnQty,
              amount: item.amount,
              totalAmount: returnQty * item.amount,
              netRevenueAmt: returnQty * item.amount,
            ),
          );
        }
      }

      final returnInvoice = InvoiceEntity(
        invoiceType: InvoiceType.salesReturn.value,
        invoiceTransType: 0,
        number: _returnNumberController.text,
        date: _selectedDate.millisecondsSinceEpoch ~/ 1000,
        customerId: _originalInvoice!.customerId,
        stockId: _originalInvoice!.stockId,
        parentInvoiceId: _originalInvoice!.id,
        parentInvoiceNumber: _originalInvoice!.number,
        amount: _totalReturnAmount,
        finalAmt: _totalReturnAmount,
        statement: _reasonController.text,
        lines: returnLines,
        paymentStatus: 0,
      );

      String customerName = 'Unknown';
      final customersState = context.read<CustomersCubit>().state;
      if (customersState is CustomersLoaded) {
        final customer = customersState.customers.firstWhere(
          (c) => c.id == _originalInvoice!.customerId.toString(),
          orElse: () => Customer(id: '0', name: 'Unknown'),
        );
        customerName = customer.name;
      }

      context.read<SalesCubit>().createReturn(
        returnInvoice,
        _originalInvoice!.id!,
        customerName,
      );
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} ريال';
  }
}
