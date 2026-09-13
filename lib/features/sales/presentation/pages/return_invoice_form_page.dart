import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/enums/invoice_type.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/payment_method_chip_widget.dart';
import 'package:muhasib/core/enums/account_connect_type.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_repository.dart';

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
  final Map<int, ProductUnitOption?> _selectedReturnUnits = {};
  final Map<int, List<ProductUnitOption>> _availableUnitsPerProduct = {};
  int? _selectedWarehouseId;

  final _returnNumberController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double _totalReturnAmount = 0.0;
  bool _refundByBank = false;

  @override
  void initState() {
    super.initState();
    _returnDateController.text = DateFormatter.formatDate(_selectedDate);
    _generateReturnNumber();
    if (widget.originalInvoiceId != null) {
      _loadOriginalInvoice();
    }
  }

  Future<void> _generateReturnNumber() async {
    final service = getIt<NumberSequenceService>();
    final number = await service.getNextNumberWithPrefix(
      'sales_return',
      SettingsCache.returnPrefix,
    );
    if (mounted) {
      setState(() => _returnNumberController.text = number);
    }
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

  double _unitPriceForLine(InvoiceLineEntity line) {
    if (line.quantity > 0) {
      return PrecisionHelper.roundCurrency(line.amount / line.quantity);
    }
    if (line.price != null && line.price! > 0) {
      return PrecisionHelper.roundCurrency(line.price!);
    }
    if (line.sellingPrice != null && line.sellingPrice! > 0) {
      return PrecisionHelper.roundCurrency(line.sellingPrice!);
    }
    // fallback: totalAmount / quantity if amount is zero?
    if (line.totalAmount > 0 && line.quantity > 0) {
      return PrecisionHelper.roundCurrency(line.totalAmount / line.quantity);
    }
    return PrecisionHelper.roundCurrency(line.amount);
  }

  void _calculateTotal() {
    double total = 0;
    for (int i = 0; i < _returnItems.length; i++) {
      final item = _returnItems[i];
      final key = item.id ?? i;
      final returnQty = _returnQuantities[key] ?? 0;
      final unitPrice = _unitPriceForLine(item);
      total = PrecisionHelper.roundCurrency(
        total + PrecisionHelper.roundCurrency(returnQty * unitPrice),
      );
    }
    _totalReturnAmount = PrecisionHelper.roundCurrency(total);
  }

  Future<bool> _hasSufficientFundBalance(double amount) async {
    if (!SettingsCache.checkFundAndBankBalanceInInvoice) return true;
    try {
      final config = getIt<AccountConfigService>();
      final type = _refundByBank
          ? AccountConnectType.banks
          : AccountConnectType.cashboxes;
      final cId = await config.getAccountIdOrNull(type);
      if (cId == null) return true;
      final result = await getIt<AccountRepository>().getAccountByCId(cId);
      return result.fold((_) => true, (account) => account.balance >= amount);
    } catch (_) {
      return true;
    }
  }

  Future<void> _saveReturn() async {
    if (_formKey.currentState!.validate()) {
      if (_originalInvoice == null &&
          !SettingsCache.allowReturnWithoutInvoice) {
        AppToast.showError(context, 'يرجى اختيار الفاتورة الأصلية');
        return;
      }

      final hasReturnItems = _returnQuantities.values.any((qty) => qty > 0);
      if (!hasReturnItems) {
        AppToast.showError(context, 'يرجى إدخال كمية مرتجعة واحدة على الأقل');
        return;
      }

      final returnLines = <InvoiceLineEntity>[];
      for (int i = 0; i < _returnItems.length; i++) {
        final item = _returnItems[i];
        final key = item.id ?? i;
        final returnQty = _returnQuantities[key] ?? 0;
        if (returnQty > 0) {
          // الوحدة الأصلية: نستخدم نفس معامل التحويل للحفاظ على دقة المخزون
          // baseQuantity = returnQty * packaging * conversionRate
          final pkg = item.packaging ?? 1;
          final conv = item.conversionRate ?? 1.0;
          final baseQty = PrecisionHelper.calcBaseQuantity(
            quantity: returnQty,
            packaging: pkg,
            conversionRate: conv,
          );
          final unitPrice = _unitPriceForLine(item);
          final lineAmount = PrecisionHelper.roundCurrency(
            unitPrice * returnQty,
          );
          // تكلفة الوحدة الأساسية -> إجمالي التكلفة للمرتجع
          final baseCostPerUnit = item.costPrice ?? item.price ?? unitPrice;
          final costTotal = PrecisionHelper.roundCurrency(
            baseCostPerUnit * baseQty,
          );
          // حصة الخصم والضريبة النسبية على هذا السطر (إن وجدت) - نحسب لاحقاً على الهيدر لكن نحفظ القيم إن احتجناها
          final origQty = item.quantity > 0 ? item.quantity : 1.0;
          final shareFactor = returnQty / origQty;
          final lineDiscount = PrecisionHelper.roundCurrency(
            (item.discountAmt ?? 0) * shareFactor,
          );
          final lineTax = PrecisionHelper.roundCurrency(
            (item.taxAmt ?? 0) * shareFactor,
          );

          returnLines.add(
            InvoiceLineEntity(
              // id: لا ننسخ id الأصلي لتجنب تعارض المفاتيح؛ سيُنشأ id جديد في DB
              id: null,
              invoiceId: 0,
              categoryId: item.categoryId,
              groupId: item.groupId,
              unitId: item.unitId,
              categorySubUnitId: item.categorySubUnitId,
              stockId: item.stockId,
              customerId: item.customerId,
              date: _selectedDate.millisecondsSinceEpoch ~/ 1000,
              invoiceType: InvoiceType.salesReturn.value,
              invoiceTransType: item.invoiceTransType,
              quantity: PrecisionHelper.roundQuantity(returnQty),
              amount: lineAmount,
              totalAmount: PrecisionHelper.roundCurrency(
                lineAmount - lineDiscount + lineTax,
              ),
              netRevenueAmt: lineAmount,
              taxAmt: lineTax,
              discountAmt: lineDiscount,
              // Multi-unit
              baseQuantity: baseQty,
              conversionRate: conv,
              packaging: pkg,
              // Cost
              costPrice: baseCostPerUnit,
              costTotal: costTotal,
              price: unitPrice,
              sellingPrice: unitPrice,
            ),
          );
        }
      }

      final originalGross = _originalInvoice?.amount ?? 0.0;
      final proportionalTax = (originalGross > 0 && _totalReturnAmount > 0)
          ? ((_originalInvoice!.taxAmt ?? 0) *
                _totalReturnAmount /
                originalGross)
          : 0.0;
      final proportionalDiscount = (originalGross > 0 && _totalReturnAmount > 0)
          ? ((_originalInvoice!.discountAmt ?? 0) *
                _totalReturnAmount /
                originalGross)
          : 0.0;

      final refundAmount = PrecisionHelper.roundCurrency(
        _totalReturnAmount + proportionalTax - proportionalDiscount,
      );
      if (refundAmount > 0 && !await _hasSufficientFundBalance(refundAmount)) {
        if (mounted) {
          AppToast.showError(
            context,
            'رصيد الصندوق أو البنك غير كافٍ لإتمام عملية الاسترداد',
          );
        }
        return;
      }

      final returnInvoice = InvoiceEntity(
        invoiceType: InvoiceType.salesReturn.value,
        invoiceTransType: _originalInvoice?.invoiceTransType ?? 0,
        number: _returnNumberController.text,
        date: _selectedDate.millisecondsSinceEpoch ~/ 1000,
        customerId: _originalInvoice?.customerId ?? 1,
        stockId: _originalInvoice?.stockId ?? SettingsCache.defaultWarehouse,
        parentInvoiceId: _originalInvoice?.id,
        parentInvoiceNumber: _originalInvoice?.number,
        amount: _totalReturnAmount,
        taxAmt: proportionalTax,
        discountAmt: proportionalDiscount,
        finalAmt: _totalReturnAmount + proportionalTax - proportionalDiscount,
        bankPaidAmount: _refundByBank
            ? (_totalReturnAmount + proportionalTax - proportionalDiscount)
            : null,
        statement: _reasonController.text,
        lines: returnLines,
        paymentStatus: 0,
      );

      String customerName = 'Unknown';
      if (_originalInvoice != null) {
        try {
          final customersState = context.read<CustomersCubit>().state;
          if (customersState is CustomersLoaded) {
            final customer = customersState.customers.firstWhere(
              (c) => c.id == _originalInvoice!.customerId.toString(),
              orElse: () => Customer(id: '0', name: 'Unknown'),
            );
            customerName = customer.name;
          }
        } catch (_) {
          customerName = 'Unknown';
        }
      }

      context.read<SalesCubit>().createReturn(
        returnInvoice,
        _originalInvoice?.id ?? 0,
        customerName,
      );
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormatter.formatDate(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormatter.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            if (widget.originalInvoiceId != null && _originalInvoice == null) {
              try {
                final invoice = state.invoices.firstWhere(
                  (inv) => inv.id == widget.originalInvoiceId,
                );
                setState(() {
                  _originalInvoice = invoice;
                  _returnItems = List.from(invoice.lines);
                  for (int i = 0; i < _returnItems.length; i++) {
                    final key = _returnItems[i].id ?? i;
                    _returnQuantities[key] = 0;
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
                    side: BorderSide(color: Theme.of(context).dividerColor),
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
                                textEditingController: _returnNumberController,
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
                                      _returnDateController.text =
                                          DateFormatter.formatDate(picked);
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
                            if (value == null || value.trim().isEmpty) {
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
                      side: BorderSide(color: Theme.of(context).dividerColor),
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
                                              InvoiceType.salesInvoice.value ||
                                          inv.invoiceType ==
                                              InvoiceType.quickInvoice.value,
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
                                          for (
                                            int i = 0;
                                            i < _returnItems.length;
                                            i++
                                          ) {
                                            final key = _returnItems[i].id ?? i;
                                            _returnQuantities[key] = 0;
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<ProductsCubit, ProductsState>(
                    builder: (context, prodState) {
                      final products = prodState is ProductsLoaded
                          ? prodState.products
                          : <ProductEntity>[];
                      final prodMap = {
                        for (final p in products)
                          if (p.id != null) p.id!: p,
                      };

                      return Column(
                        children: List.generate(_returnItems.length, (index) {
                          final item = _returnItems[index];
                          final itemId = item.id ?? index;
                          final returnQty = _returnQuantities[itemId] ?? 0;
                          final prodName =
                              prodMap[item.categoryId]?.name ??
                              'صنف #${item.categoryId ?? item.groupId}';
                          final unitPrice = _unitPriceForLine(item);
                          final factor =
                              (item.packaging ?? 1) *
                              (item.conversionRate ?? 1.0);
                          final baseOrig =
                              item.baseQuantity ??
                              PrecisionHelper.calcBaseQuantity(
                                quantity: item.quantity,
                                packaging: item.packaging ?? 1,
                                conversionRate: item.conversionRate ?? 1.0,
                              );
                          final isCarton = factor > 1.001;

                          return CustomCardContainer(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
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
                                              prodName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'الكمية الأصلية: ${item.quantity} ${isCarton ? "(= ${baseOrig % 1 == 0 ? baseOrig.toInt() : baseOrig} حبة أساس)" : ""}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (isCarton)
                                              Text(
                                                'الوحدة: ${item.packaging} × ${item.conversionRate} = ${factor.toStringAsFixed(factor % 1 == 0 ? 0 : 2)} حبة/وحدة',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      Colors.blueGrey.shade600,
                                                ),
                                              ),
                                            Text(
                                              'سعر الوحدة: ${_formatCurrency(unitPrice)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (returnQty > 0)
                                              Text(
                                                'الأساس المرتجع: ${PrecisionHelper.calcBaseQuantity(quantity: returnQty, packaging: item.packaging ?? 1, conversionRate: item.conversionRate ?? 1.0)} حبة',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.bold,
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
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.sm,
                                                  ),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            final qty =
                                                double.tryParse(value) ?? 0;
                                            setState(() {
                                              _returnQuantities[itemId] = qty;
                                              _calculateTotal();
                                            });
                                          },
                                          validator: (value) {
                                            final qty =
                                                double.tryParse(value ?? '0') ??
                                                0;
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
                      );
                    },
                  ),
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

                // Refund method (only for cash sales)
                if (_originalInvoice != null &&
                    _originalInvoice!.invoiceTransType == 0) ...[
                  const SizedBox(height: 16),
                  CustomCardContainer(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Padding(
                      padding: AppConstant.defaultPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'طريقة الإرجاع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              PaymentMethodChipWidget(
                                method: PaymentMethod.cash,
                                label: 'نقدي',
                                icon: Icons.payments,
                                isSelected: !_refundByBank,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _refundByBank = false);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              PaymentMethodChipWidget(
                                method: PaymentMethod.bank,
                                label: 'بنكي',
                                icon: Icons.account_balance,
                                isSelected: _refundByBank,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _refundByBank = true);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
