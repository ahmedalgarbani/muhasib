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
              padding: AppConstant.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PurchaseFormHeader(isEdit: widget.invoice != null),
                  const SizedBox(height: 20),
                  PurchaseFormInfoCard(
                    numberController: _numberController,
                    dateController: _dateController,
                    paymentType: _paymentType,
                    onPaymentTypeChanged: (type) =>
                        setState(() => _paymentType = type),
                    onSelectDate: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _dateController.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  PurchaseFormSupplierWarehouseCard(
                    selectedSupplierId: _selectedSupplierId,
                    selectedWarehouseId: _selectedWarehouseId,
                    onSupplierChanged: (id) =>
                        setState(() => _selectedSupplierId = id),
                    onWarehouseChanged: (id) =>
                        setState(() => _selectedWarehouseId = id),
                  ),
                  const SizedBox(height: 16),
                  PurchaseFormProductsCard(
                    invoiceLines: _invoiceLines,
                    onAddLine: _addInvoiceLine,
                    onEditLine: _editInvoiceLine,
                    onDeleteLine: _deleteInvoiceLine,
                  ),
                  const SizedBox(height: 16),
                  PurchaseFormTotalsCard(
                    subtotal: _subtotal,
                    discountAmount: _discountAmount,
                    discountController: _discountController,
                    taxController: _taxController,
                    taxAmount: _taxAmount,
                    total: _total,
                    onCalculateTotals: _calculateTotals,
                  ),
                  const SizedBox(height: 16),
                  PurchaseFormNotesCard(
                    statementController: _statementController,
                    shippingAddressController: _shippingAddressController,
                  ),
                  const SizedBox(height: 24),
                  PurchaseFormActionButtons(
                    invoice: widget.invoice,
                    onSaveInvoice: _saveInvoice,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
