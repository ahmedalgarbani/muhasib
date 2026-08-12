part of 'purchase_form_page.dart';

class _PurchaseFormPageState extends State<PurchaseFormPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final _numberController = TextEditingController();
  final _dateController = TextEditingController();
  final _statementController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '15');
  final _shippingAddressController = TextEditingController();

  int? _selectedSupplierId;
  int? _selectedWarehouseId;
  int _paymentType = 0;
  DateTime _selectedDate = DateTime.now();
  List<InvoiceLineEntity> _invoiceLines = [];

  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _discountAmount = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.invoice != null) {
      _numberController.text = widget.invoice!.number;
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(
        widget.invoice!.date * 1000,
      );
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _statementController.text = widget.invoice!.statement ?? '';
      _selectedSupplierId = widget.invoice!.customerId;
      _selectedWarehouseId = widget.invoice!.stockId;
      _invoiceLines = List.from(widget.invoice!.lines);
      _discountController.text = widget.invoice!.discountAmt?.toString() ?? '0';
      _taxController.text = widget.invoice!.taxRatio?.toString() ?? '15';
      _shippingAddressController.text = widget.invoice!.shippingAddress ?? '';
      _calculateTotals();
    } else {
      _generateInvoiceNumber();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    }
  }

  void _generateInvoiceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _numberController.text = widget.invoiceType == 3
        ? 'PO-$timestamp'
        : 'PUR-$timestamp';
  }

  void _calculateTotals() {
    setState(() {
      _subtotal = _invoiceLines.fold(0, (sum, line) => sum + line.amount);

      final discountValue = double.tryParse(_discountController.text) ?? 0;
      _discountAmount = discountValue;

      final subtotalAfterDiscount = _subtotal - _discountAmount;

      final taxRate = double.tryParse(_taxController.text) ?? 0;
      _taxAmount = subtotalAfterDiscount * (taxRate / 100);

      _total = subtotalAfterDiscount + _taxAmount;
    });
  }

  void _addInvoiceLine() {
    showDialog(
      context: context,
      builder: (context) => AddLineDialog(
        onAdd: (line) {
          setState(() {
            _invoiceLines.add(line);
            _calculateTotals();
          });
        },
      ),
    );
  }

  void _editInvoiceLine(int index) {
    showDialog(
      context: context,
      builder: (context) => AddLineDialog(
        line: _invoiceLines[index],
        onAdd: (line) {
          setState(() {
            _invoiceLines[index] = line;
            _calculateTotals();
          });
        },
      ),
    );
  }

  void _deleteInvoiceLine(int index) {
    setState(() {
      _invoiceLines.removeAt(index);
      _calculateTotals();
    });
  }

  void _saveInvoice() {
    if (_formKey.currentState!.validate()) {
      if (_invoiceLines.isEmpty) {
        AppToast.showError(context, 'يجب إضافة منتج واحد على الأقل');
        return;
      }

      final invoice = InvoiceEntity(
        id: widget.invoice?.id,
        number: _numberController.text,
        date: _selectedDate.millisecondsSinceEpoch ~/ 1000,
        customerId: _selectedSupplierId!,
        stockId: _selectedWarehouseId!,
        statement: _statementController.text,
        lines: _invoiceLines,
        amount: _subtotal,
        discountAmt: _discountAmount,
        taxRatio: double.tryParse(_taxController.text) ?? 0,
        taxAmt: _taxAmount,
        totalAmount: _subtotal,
        finalAmt: _total,
        invoiceType: widget.invoiceType,
        invoiceTransType: widget.invoiceType == 3
            ? 1
            : (_paymentType == 0 ? 0 : 1),
        paymentStatus: widget.invoiceType == 3
            ? 0
            : (_paymentType == 0 ? 1 : 0),
        shippingAddress: _shippingAddressController.text,
      );

      if (widget.invoice != null) {
        context.read<PurchasesCubit>().updatePurchaseInvoice(invoice);
      } else {
        if (widget.invoiceType == 3) {
          context.read<PurchasesCubit>().createPurchaseOrder(invoice);
        } else {
          context.read<PurchasesCubit>().createPurchaseInvoice(invoice);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<PurchasesCubit>()),
        BlocProvider(create: (_) => getIt<CustomersCubit>()..loadSuppliers()),
        BlocProvider(create: (_) => getIt<WarehousesCubit>()..loadWarehouses()),
      ],
      child: BlocListener<PurchasesCubit, PurchasesState>(
        listener: (context, state) {
          if (state is PurchaseInvoiceCreated) {
            AppToast.showSuccess(context, 'تم إنشاء فاتورة المشتريات بنجاح');
            context.pop();
          } else if (state is PurchaseInvoiceUpdated) {
            AppToast.showSuccess(context, 'تم تحديث فاتورة المشتريات بنجاح');
            context.pop();
          } else if (state is PurchasesError) {
            AppToast.showError(context, state.message);
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.neutral100,
          appBar: CustomAppBar(
            title: widget.invoiceType == 3
                ? 'أمر شراء'
                : (widget.invoice != null
                      ? 'تعديل فاتورة مشتريات'
                      : 'فاتورة مشتريات جديدة'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildInvoiceInfoCard(),
                  const SizedBox(height: 16),
                  _buildSupplierWarehouseCard(),
                  const SizedBox(height: 16),
                  _buildProductsCard(),
                  const SizedBox(height: 16),
                  _buildTotalsCard(),
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.invoice != null
                      ? 'تعديل فاتورة مشتريات'
                      : 'فاتورة مشتريات جديدة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أدخل تفاصيل فاتورة المشتريات',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الفاتورة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    controller: _numberController,
                    decoration: InputDecoration(
                      labelText: 'رقم الفاتورة',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.tag, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'رقم الفاتورة مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    readOnly: true,
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
                          _dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'التاريخ مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'نوع الدفع:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('نقدي', style: TextStyle(fontSize: 12)),
                  selected: _paymentType == 0,
                  onSelected: (selected) {
                    if (selected) setState(() => _paymentType = 0);
                  },
                  selectedColor: AppColors.success.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('آجل', style: TextStyle(fontSize: 12)),
                  selected: _paymentType == 1,
                  onSelected: (selected) {
                    if (selected) setState(() => _paymentType = 1);
                  },
                  selectedColor: AppColors.success.withOpacity(0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierWarehouseCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المورد والمخزن',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<CustomersCubit, CustomersState>(
              builder: (context, state) {
                if (state is SuppliersLoaded) {
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedSupplierId,
                          decoration: InputDecoration(
                            labelText: 'المورد',
                            labelStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.business, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          items: state.suppliers.map((supplier) {
                            return DropdownMenuItem<int>(
                              value: int.parse(supplier.id),
                              child: Text(
                                supplier.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSupplierId = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'يجب اختيار المورد';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          tooltip: 'إضافة مورد جديد',
                          onPressed: () async {
                            final cubit = context.read<CustomersCubit>();
                            final newSupplier = await showDialog<Customer>(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: cubit,
                                child: const AddCustomerDialog(partyType: 2),
                              ),
                            );

                            if (newSupplier != null && mounted) {
                              setState(() {
                                _selectedSupplierId = int.tryParse(
                                  newSupplier.id,
                                );
                              });
                              cubit.loadSuppliers();
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
            const SizedBox(height: 12),
            BlocBuilder<WarehousesCubit, WarehousesState>(
              builder: (context, state) {
                if (state is WarehousesLoaded) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedWarehouseId,
                    decoration: InputDecoration(
                      labelText: 'المخزن',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.warehouse, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    items: state.warehouses.map((warehouse) {
                      return DropdownMenuItem(
                        value: warehouse.id,
                        child: Text(
                          warehouse.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedWarehouseId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'يجب اختيار المخزن';
                      }
                      return null;
                    },
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المنتجات',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addInvoiceLine,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'إضافة منتج',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_invoiceLines.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد منتجات',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط على "إضافة منتج" للبدء',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoiceLines.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final line = _invoiceLines[index];
                  final unitPrice = line.quantity == 0
                      ? 0
                      : (line.amount / line.quantity);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'المنتج #${line.groupId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'الكمية: ${line.quantity} × ${unitPrice.toStringAsFixed(2)} = ${line.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editInvoiceLine(index),
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => _deleteInvoiceLine(index),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإجماليات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    controller: _discountController,
                    decoration: InputDecoration(
                      labelText: 'الخصم',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.discount, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _calculateTotals(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    controller: _taxController,
                    decoration: InputDecoration(
                      labelText: 'الضريبة %',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.receipt_long, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _calculateTotals(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  _buildTotalRow('المجموع الفرعي', _subtotal),
                  const SizedBox(height: 8),
                  _buildTotalRow(
                    'الخصم',
                    -_discountAmount,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildTotalRow('الضريبة', _taxAmount, color: Colors.blue),
                  const Divider(height: 16),
                  _buildTotalRow('الإجمالي', _total, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? AppColors.gray900 : Colors.grey[700]),
          ),
        ),
        Text(
          '${NumberFormat('#,##0.00').format(amount)} ريال',
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? AppColors.success : Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات إضافية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              controller: _statementController,
              decoration: InputDecoration(
                labelText: 'البيان',
                labelStyle: const TextStyle(fontSize: 12),
                hintText: 'أدخل أي ملاحظات إضافية',
                hintStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextInputField(
              controller: _shippingAddressController,
              decoration: InputDecoration(
                labelText: 'عنوان الشحن',
                labelStyle: const TextStyle(fontSize: 12),
                hintText: 'أدخل عنوان الشحن إن وجد',
                hintStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<PurchasesCubit, PurchasesState>(
            builder: (context, state) {
              final isLoading = state is PurchasesLoading;
              return ElevatedButton.icon(
                onPressed: isLoading ? null : _saveInvoice,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  isLoading
                      ? 'جاري الحفظ...'
                      : (widget.invoice != null
                            ? 'تحديث الفاتورة'
                            : 'حفظ الفاتورة'),
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _dateController.dispose();
    _statementController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }
}
