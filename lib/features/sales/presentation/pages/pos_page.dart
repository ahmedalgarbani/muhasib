import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/bank_repository.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/cashbox_repository.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/core/widgets/unit_picker_page.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  // Workflow Step: 0 = Product Selection, 1 = Cart & Customer Review, 2 = Payment & Checkout
  int _currentStep = 0;

  final _searchController = TextEditingController();
  final _discountController = TextEditingController();
  final _statementController = TextEditingController();
  final _cashReceivedController = TextEditingController();
  final _bankRefController = TextEditingController();
  final _transferNumberController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _splitCashController = TextEditingController();
  final _splitBankController = TextEditingController();
  final _scannerController = MobileScannerController();

  final Map<int, _PosLine> _cart = {};
  String _query = '';
  int? _selectedGroupId;
  Customer? _selectedCustomer; // null means Cash Walk-in Customer
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSplitPayment = false;
  DiscountType _discountType = DiscountType.amount;
  bool _saving = false;
  // pending invoice for success dialog after Bloc confirm
  String? _pendingNumber;
  double? _pendingFinalAmount;
  double? _pendingChange;

  // Banks & Funds (Cashboxes)
  List<BankEntity> _banks = [];
  List<CashboxEntity> _funds = [];
  int? _selectedBankId;
  String? _selectedBankName;
  int? _selectedFundId;
  String? _selectedFundName;
  bool _isLoadingBanksAndFunds = false;

  // Warehouse (محاسبي)
  int? _selectedWarehouseId;
  List<WarehouseEntity> _warehouses = [];
  bool _isLoadingWarehouses = false;

  // Due Date for Deferred Payment
  DateTime? _dueDate;

  DateTime get _effectiveDueDate =>
      _dueDate ??
      DateTime.now().add(Duration(days: SettingsCache.paymentDueDays));

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadProducts();
    context.read<CustomersCubit>().loadCustomers();
    context.read<ProductGroupsCubit>().loadAllGroups();
    context.read<CurrenciesCubit>().loadAllCurrencies();
    final customerState = context.read<CustomersCubit>().state;
    if (customerState is CustomersLoaded &&
        customerState.customers.isNotEmpty) {
      _selectedCustomer = customerState.customers.first;
    }
    _loadBanksAndFunds();
    _loadWarehouses();
    _initDefaultPaymentMethod();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoadingWarehouses = true);
    try {
      // حاول عبر Cubit أولاً
      final whCubit = getIt<WarehousesCubit>();
      await whCubit.loadWarehouses();
      final state = whCubit.state;
      if (state is WarehousesLoaded && mounted) {
        setState(() {
          _warehouses = state.warehouses;
          if (_warehouses.isNotEmpty) {
            // افتراضي: المخزن الافتراضي من الإعدادات أو الرئيسي
            WarehouseEntity? target;
            final defId = SettingsCache.defaultWarehouse;
            for (final w in _warehouses) {
              if (w.id == defId) {
                target = w;
                break;
              }
            }
            target ??= _warehouses.firstWhere(
              (w) => w.isMainStock == true,
              orElse: () => _warehouses.first,
            );
            _selectedWarehouseId = target.id;
          }
          _isLoadingWarehouses = false;
        });
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingWarehouses = false);
    }
    if (mounted && _warehouses.isEmpty) {
      setState(() => _isLoadingWarehouses = false);
    }
  }

  void _initDefaultPaymentMethod() {
    switch (SettingsCache.defaultPaymentMethod) {
      case 'bank':
        _paymentMethod = PaymentMethod.bank;
        break;
      case 'deferred':
        _paymentMethod = PaymentMethod.deferred;
        break;
      default:
        _paymentMethod = PaymentMethod.cash;
    }
  }

  Future<void> _loadBanksAndFunds() async {
    setState(() => _isLoadingBanksAndFunds = true);
    try {
      final bankRepo = getIt<BankRepository>();
      final cashboxRepo = getIt<CashboxRepository>();

      final banksRes = await bankRepo.getActiveBanks();
      final fundsRes = await cashboxRepo.getActiveCashboxes();

      final loadedBanks = banksRes.fold((_) => <BankEntity>[], (list) => list);
      final loadedFunds = fundsRes.fold(
        (_) => <CashboxEntity>[],
        (list) => list,
      );

      if (mounted) {
        setState(() {
          _banks = loadedBanks;
          _funds = loadedFunds;
          if (_banks.isNotEmpty) {
            _selectedBankId = _banks.first.id;
            _selectedBankName = _banks.first.name;
          }
          if (_funds.isNotEmpty) {
            final mainFund =
                _funds.where((f) => f.isMainFund).firstOrNull ?? _funds.first;
            _selectedFundId = mainFund.id;
            _selectedFundName = mainFund.name;
          }
          _isLoadingBanksAndFunds = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBanksAndFunds = false);
    }
  }

  String _getCurrencyCode() {
    final state = context.read<CurrenciesCubit>().state;
    if (state is CurrenciesLoaded && state.currencies.isNotEmpty) {
      final local =
          state.currencies.where((c) => c.isLocalCurrency).firstOrNull ??
          state.currencies.first;
      return local.code;
    }
    return 'SAR';
  }

  String _getCurrencySymbol() {
    final state = context.read<CurrenciesCubit>().state;
    if (state is CurrenciesLoaded && state.currencies.isNotEmpty) {
      final local =
          state.currencies.where((c) => c.isLocalCurrency).firstOrNull ??
          state.currencies.first;
      return (local.symbol != null && local.symbol!.isNotEmpty)
          ? local.symbol!
          : local.code;
    }
    return 'ر.س';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _statementController.dispose();
    _cashReceivedController.dispose();
    _bankRefController.dispose();
    _transferNumberController.dispose();
    _senderNameController.dispose();
    _splitCashController.dispose();
    _splitBankController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ==================== Calculations ====================

  double get _subtotal =>
      _cart.values.fold(0.0, (sum, line) => sum + line.total);

  double get _discountAmount {
    final raw = double.tryParse(_discountController.text.trim()) ?? 0.0;
    if (raw <= 0) return 0.0;
    if (_discountType == DiscountType.percent) {
      return (_subtotal * (raw / 100)).clamp(0.0, _subtotal);
    }
    return raw.clamp(0.0, _subtotal);
  }

  double get _taxableAmount =>
      (_subtotal - _discountAmount).clamp(0.0, double.infinity);

  double get _taxRate =>
      SettingsCache.taxEnabled ? SettingsCache.defaultTaxRate : 0.0;

  double get _taxAmount =>
      SettingsCache.taxEnabled ? _taxableAmount * (_taxRate / 100) : 0.0;

  double get _grandTotal {
    final raw = _taxableAmount + _taxAmount;
    if (!SettingsCache.posCashRoundingEnabled) return raw;
    final precision = SettingsCache.posCashRoundingPrecision;
    if (precision <= 0) return raw;
    return (raw / precision).round() * precision;
  }

  double get _cashReceived {
    final val = double.tryParse(_cashReceivedController.text.trim());
    return val ?? _grandTotal;
  }

  double get _changeAmount =>
      (_cashReceived - _grandTotal).clamp(0.0, double.infinity);

  int get _totalItemUnits =>
      _cart.values.fold(0, (sum, line) => sum + line.quantity.round());

  // ==================== Cart Operations ====================

  Future<void> _addProduct(
    ProductEntity product, {
    ProductUnitOption? forcedUnit,
  }) async {
    final id = product.id;
    if (id == null) return;
    // If already in cart and same unit, just increase quantity
    final existing = _cart[id];
    if (existing != null && forcedUnit == null) {
      setState(
        () => _cart[id] = existing.copyWith(quantity: existing.quantity + 1),
      );
      _maybeShowStockAlert(
        product,
        existing.quantity,
        existing.quantity + 1,
      );
      return;
    }
    // Resolve unit: forcedUnit or default sale unit or base
    ProductUnitOption? unit;
    double price = product.sellAmount ?? 0;
    try {
      final svc = getIt<UnitConversionService>();
      if (forcedUnit != null) {
        unit = forcedUnit;
        price = svc.resolveUnitPrice(baseSellPrice: price, unit: unit);
      } else {
        unit = await svc.getDefaultSaleUnit(product.id!);
        if (unit != null) {
          price = svc.resolveUnitPrice(baseSellPrice: price, unit: unit);
        }
      }
    } catch (_) {}
    setState(() {
      if (existing != null &&
          forcedUnit != null &&
          existing.unitOption?.unitId == forcedUnit.unitId) {
        _cart[id] = existing.copyWith(quantity: existing.quantity + 1);
      } else if (existing == null) {
        _cart[id] = _PosLine(
          product: product,
          quantity: 1,
          unitOption: unit,
          unitPrice: price,
        );
      } else if (forcedUnit != null) {
        // Different unit selected for same product: treat as separate? For simplicity increase qty with new unit
        // Use composite key: replace with forced unit
        _cart[id] = _PosLine(
          product: product,
          quantity: existing.quantity + 1,
          unitOption: unit,
          unitPrice: price,
        );
      } else {
        _cart[id] = existing.copyWith(quantity: existing.quantity + 1);
      }
    });
  }

  void _changeQuantity(int id, double delta) {
    final line = _cart[id];
    if (line == null) return;
    setState(() {
      final quantity = line.quantity + delta;
      if (quantity <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = line.copyWith(quantity: quantity);
      }
    });
    if (delta > 0) {
      _maybeShowStockAlert(line.product, line.quantity, line.quantity + delta);
    }
  }

  /// Warns when a cart quantity crosses the available stock level
  /// (controlled by the POS stock-alerts setting).
  void _maybeShowStockAlert(
    ProductEntity product,
    double oldQuantity,
    double newQuantity,
  ) {
    if (!SettingsCache.posEnableStockAlerts) return;
    if (!product.trackInventory) return;
    if (SettingsCache.allowNegativeStock) return;
    if (newQuantity <= product.quantity) return;
    if (oldQuantity > product.quantity) return;
    AppToast.showWarning(
      context,
      'الكمية تتجاوز المتوفر (${NumberFormatter.formatNumber(product.quantity)})',
    );
  }

  Future<void> _changeLineUnit(int productId, ProductUnitOption newUnit) async {
    final line = _cart[productId];
    if (line == null) return;
    final svc = getIt<UnitConversionService>();
    final newPrice = svc.resolveUnitPrice(
      baseSellPrice: line.product.sellAmount ?? 0,
      unit: newUnit,
    );
    setState(() {
      _cart[productId] = line.copyWith(
        unitOption: newUnit,
        unitPrice: newPrice,
      );
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      final customerState = context.read<CustomersCubit>().state;
      if (customerState is CustomersLoaded &&
          customerState.customers.isNotEmpty) {
        _selectedCustomer = customerState.customers.first;
      } else {
        _selectedCustomer = null;
      }
      _discountController.clear();
      _statementController.clear();
      _cashReceivedController.clear();
      _bankRefController.clear();
      _transferNumberController.clear();
      _senderNameController.clear();
      _splitCashController.clear();
      _splitBankController.clear();
      _isSplitPayment = false;
      _dueDate = null;
      _initDefaultPaymentMethod();
      _currentStep = 0;
    });
  }

  // ==================== Barcode Scanner ====================

  Future<void> _scanBarcode(List<ProductEntity> products) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                String? value;
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue;
                  if (raw != null && raw.isNotEmpty) {
                    value = raw;
                    break;
                  }
                }
                if (value != null && context.mounted) {
                  Navigator.of(context).pop(value);
                }
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),

            Positioned(
              left: 24,
              right: 24,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: AppColors.saudiEmerald,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'وجّه الكاميرا إلى باركود المنتج',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || code == null) return;

    // Multi-unit smart barcode: يحاول حل الباركود عبر خدمة الوحدات أولاً
    try {
      final svc = getIt<UnitConversionService>();
      final lookup = await svc.lookupByBarcode(code);
      if (lookup != null) {
        ProductEntity? product;
        for (final item in products) {
          if (item.id == lookup.productId) {
            product = item;
            break;
          }
        }
        if (product != null) {
          await _addProduct(product, forcedUnit: lookup.unit);
          if (!mounted) return;
          final unitLabel = lookup.unit != null
              ? ' (${lookup.unit!.unitName})'
              : '';
          AppToast.showSuccess(context, 'تمت إضافة: ${product.name}$unitLabel');
          return;
        }
      }
    } catch (_) {}
    // Fallback legacy exact match
    ProductEntity? product;
    for (final item in products) {
      if (item.barcodeNo == code || item.id.toString() == code) {
        product = item;
        break;
      }
    }
    if (product == null) {
      AppToast.showError(
        context,
        'لم يتم العثور على منتج بهذا الباركود: $code',
      );
      return;
    }
    await _addProduct(product);
    if (!mounted) return;
    AppToast.showSuccess(context, 'تمت إضافة: ${product.name}');
  }

  Future<ProductUnitOption?> _showPosUnitPicker(
    BuildContext context,
    ProductEntity product,
    List<ProductUnitOption> units,
    double basePrice,
  ) async {
    return Navigator.of(context).push<ProductUnitOption>(
      MaterialPageRoute(
        builder: (_) => UnitPickerPage(
          productName: product.name,
          units: units,
          basePrice: basePrice,
          currencySymbol: _getCurrencySymbol(),
        ),
      ),
    );
  }

  // ==================== Customer Picker Bottom Sheet ====================

  Future<void> _openCustomerPicker() async {
    final customersCubit = context.read<CustomersCubit>();
    final result = await showModalBottomSheet<Customer?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: customersCubit,
        child: _CustomerPickerSheet(
          selectedCustomer: _selectedCustomer,
          currencySymbol: _getCurrencySymbol(),
          onAddNewCustomer: () async {
            final newCustomer = await showDialog<Customer?>(
              context: modalContext,
              builder: (dialogContext) => BlocProvider.value(
                value: customersCubit,
                child: const AddCustomerDialog(partyType: 1),
              ),
            );
            if (newCustomer != null && modalContext.mounted) {
              Navigator.of(modalContext).pop(newCustomer);
            }
          },
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedCustomer = result.id == '0' ? null : result);
    }
  }

  // ==================== Save & Submit Invoice ====================

  Future<void> _saveInvoice() async {
    if (_cart.isEmpty || _saving) return;

    final finalAmount = _grandTotal;

    // Check deferred payment requirement
    if (!_isSplitPayment &&
        _paymentMethod == PaymentMethod.deferred &&
        _selectedCustomer == null) {
      AppToast.showError(
        context,
        'البيع الآجل يتطلب اختيار عميل مسجل من القائمة',
      );
      setState(() => _currentStep = 1);
      return;
    }

    // Split payment calculations and customer check
    double splitCash = 0.0;
    double splitBank = 0.0;
    double splitDeferred = 0.0;

    if (_isSplitPayment) {
      splitCash = double.tryParse(_splitCashController.text.trim()) ?? 0.0;
      splitBank = double.tryParse(_splitBankController.text.trim()) ?? 0.0;
      splitDeferred = (finalAmount - splitCash - splitBank).clamp(
        0.0,
        double.infinity,
      );

      if (splitDeferred > 0.001 && _selectedCustomer == null) {
        AppToast.showError(
          context,
          'وجود متبقي آجل في الدفع المقسم (${NumberFormatter.formatNumber(splitDeferred)} ${_getCurrencySymbol()}) يتطلب اختيار عميل مسجل',
        );
        setState(() => _currentStep = 1);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final sequence = getIt<NumberSequenceService>();
      final number = await sequence.getNextNumberWithPrefix(
        'sales_invoice',
        SettingsCache.invoicePrefix,
      );
      final now = DateTime.now().millisecondsSinceEpoch;

      double paidAmt = 0.0;
      double bankPaidAmt = 0.0;
      int paymentStatus = 2; // 2 = Paid, 1 = Partial, 0 = Unpaid
      int invoiceTransType = 0; // 0 = Cash/Bank, 1 = Deferred/Credit

      if (_isSplitPayment) {
        paidAmt = splitCash;
        bankPaidAmt = splitBank;
        if (splitDeferred > 0.001) {
          invoiceTransType = 1;
          paymentStatus = (splitCash + splitBank > 0) ? 1 : 0;
        } else {
          invoiceTransType = 0;
          paymentStatus = 2;
        }
      } else {
        if (_paymentMethod == PaymentMethod.cash) {
          paidAmt = finalAmount;
          bankPaidAmt = 0.0;
          paymentStatus = 2;
          invoiceTransType = 0;
        } else if (_paymentMethod == PaymentMethod.bank) {
          paidAmt = 0.0;
          bankPaidAmt = finalAmount;
          paymentStatus = 2;
          invoiceTransType = 0;
        } else if (_paymentMethod == PaymentMethod.deferred) {
          paidAmt = 0.0;
          bankPaidAmt = 0.0;
          paymentStatus = 0;
          invoiceTransType = 1;
        }
      }

      String statementText = _statementController.text.trim();
      if (statementText.isEmpty) {
        if (_isSplitPayment) {
          statementText =
              'مبيعات مقسمة (نقدي: ${NumberFormatter.formatNumber(splitCash)} - بنك: ${NumberFormatter.formatNumber(splitBank)} - آجل: ${NumberFormatter.formatNumber(splitDeferred)})';
        } else {
          switch (_paymentMethod) {
            case PaymentMethod.cash:
              statementText =
                  'مبيعات نقدية - ${_selectedFundName ?? "الصندوق"}';
              break;
            case PaymentMethod.bank:
              final bankName = _selectedBankName ?? 'البنك';
              final ref = _bankRefController.text.trim();
              final transfer = _transferNumberController.text.trim();
              final sender = _senderNameController.text.trim();
              final extra = [
                if (ref.isNotEmpty) 'مرجع: $ref',
                if (transfer.isNotEmpty) 'حوالة: $transfer',
                if (sender.isNotEmpty) 'المرسل: $sender',
              ].join(' - ');
              statementText =
                  'مبيعات شبكة/بنك - $bankName ${extra.isNotEmpty ? "($extra)" : ""}';
              break;
            case PaymentMethod.deferred:
              statementText =
                  'مبيعات آجلة - حساب: ${_selectedCustomer?.name ?? "عميل"} (استحقاق: ${DateFormatter.formatDate(_effectiveDueDate)})';
              break;
          }
        }
      }

      final customerId = _selectedCustomer != null
          ? (int.tryParse(_selectedCustomer!.id) ?? 1)
          : 1;

      final isCreditInvoice = invoiceTransType == 1;

      final invoice = InvoiceEntity(
        invoiceType: 1,
        number: number,
        date: now,
        statement: statementText,
        amount: _subtotal,
        totalAmount: finalAmount,
        taxAmt: _taxAmount,
        taxRatio: _taxRate,
        discountAmt: _discountAmount,
        discountRatio: _discountType == DiscountType.percent
            ? (double.tryParse(_discountController.text.trim()) ?? 0.0)
            : 0.0,
        netRevenueAmt: _subtotal - _discountAmount,
        totalAmountAfterDiscount: _subtotal - _discountAmount,
        finalAmt: finalAmount,
        currencyCode: _getCurrencyCode(),
        exchangeRate: 1,
        stockId: _selectedWarehouseId ?? SettingsCache.defaultWarehouse,
        customerId: customerId,
        invoiceTransType: invoiceTransType,
        paymentStatus: paymentStatus,
        paidAmount: paidAmt,
        bankPaidAmount: bankPaidAmt,
        dueDate: isCreditInvoice
            ? _effectiveDueDate.millisecondsSinceEpoch
            : null,
        creatorId: 1,
        lastModifierId: 1,
        creationTime: now,
        lastModificationTime: now,
        lines: _cart.values
            .map((line) => _toInvoiceLine(line, now, invoiceTransType))
            .toList(),
      );

      if (!mounted) return;
      // خزن بيانات النجاح مؤقتاً واعتمد على BlocListener للتأكيد (يظهر النجاح فقط إذا نجح القيد فعلاً)
      setState(() {
        _pendingNumber = number;
        _pendingFinalAmount = finalAmount;
        _pendingChange = _isSplitPayment ? 0.0 : _changeAmount;
      });
      await context.read<SalesCubit>().addInvoice(invoice);
      // لا نظهر النجاح هنا مباشرة؛ الـ listener سيظهره عند InvoiceCreated
      // في حال فشل الحفظ سيظهر SalesError ويعيد _saving=false
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _pendingNumber = null;
          _pendingFinalAmount = null;
          _pendingChange = null;
        });
        AppToast.showError(context, 'تعذر إنشاء الفاتورة: $error');
      }
    }
  }

  InvoiceLineEntity _toInvoiceLine(
    _PosLine line,
    int now,
    int invoiceTransType,
  ) {
    final product = line.product;
    final unit = line.unitOption;
    final price = line.unitPrice;
    final qty = line.quantity;
    final baseQty = line.baseQuantity;
    final convRate = unit?.conversionRate ?? 1.0;
    final packaging = unit?.packaging ?? 1;
    final unitId = unit?.unitId ?? product.unitId ?? 1;
    final subUnitId = unit?.subUnitId ?? 1;
    // COGS per base unit; ملاحظة: يتم إعادة حساب COGS الحقيقي عبر متوسط المخزون في الـ datasource
    final baseCostPerUnit = product.costAmount ?? 0;
    final costTotal = PrecisionHelper.roundCurrency(baseCostPerUnit * baseQty);
    return InvoiceLineEntity(
      invoiceType: 1,
      amount: price * qty,
      totalAmount: line.total,
      taxAmt: 0,
      taxRatio: 0,
      discountAmt: 0,
      discountRatio: 0,
      netRevenueAmt: line.total,
      currencyCode: _getCurrencyCode(),
      exchangeRate: 1,
      quantity: qty,
      categoryId: product.id,
      groupId: product.groupId ?? 1,
      unitId: unitId,
      categorySubUnitId: subUnitId,
      stockId: _selectedWarehouseId ?? product.stockId,
      invoiceId: 0,
      customerId: _selectedCustomer != null
          ? (int.tryParse(_selectedCustomer!.id) ?? 1)
          : 1,
      date: now,
      invoiceTransType: invoiceTransType,
      baseQuantity: baseQty,
      conversionRate: convRate,
      packaging: packaging,
      costPrice: baseCostPerUnit,
      costTotal: costTotal,
      price: price,
      sellingPrice: price,
      creatorId: 1,
      lastModifierId: 1,
      creationTime: now,
      lastModificationTime: now,
    );
  }

  void _showSuccessDialog(
    String invoiceNumber,
    double finalAmount,
    double change,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg20),
          ),
          contentPadding: const EdgeInsets.all(12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.saudiMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.saudiEmerald,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تمت عملية البيع بنجاح!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'فاتورة رقم: $invoiceNumber',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardSurfaceDark
                      : AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي المدفوع:',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          '${NumberFormatter.formatNumber(finalAmount)} ${_getCurrencySymbol()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_paymentMethod == PaymentMethod.cash && change > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المتبقي للعميل (الفكة):',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.saudiEmerald,
                            ),
                          ),
                          Text(
                            '${NumberFormatter.formatNumber(change)} ${_getCurrencySymbol()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.saudiEmerald,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearCart();
                        context.go('/sales/list');
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('قائمة الفواتير'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearCart();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.saudiEmerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('فاتورة جديدة ➕'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Filtering ====================

  List<ProductEntity> _filteredProducts(List<ProductEntity> products) {
    final query = _query.trim().toLowerCase();
    final active = products.where(
      (product) => product.isActive && !product.isDeleted,
    );

    return active.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.barcodeNo.toLowerCase().contains(query);

      final matchesGroup =
          _selectedGroupId == null || product.groupId == _selectedGroupId;

      return matchesQuery && matchesGroup;
    }).toList();
  }

  // ==================== Main Build ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<SalesCubit, SalesState>(
          listener: (context, state) {
            if (state is InvoiceCreated) {
              final number = _pendingNumber ?? state.id.toString();
              final amount = _pendingFinalAmount ?? _grandTotal;
              final change = _pendingChange ?? 0.0;
              setState(() {
                _saving = false;
                _pendingNumber = null;
                _pendingFinalAmount = null;
                _pendingChange = null;
              });
              _showSuccessDialog(number, amount, change);
            } else if (state is SalesError) {
              setState(() {
                _saving = false;
                _pendingNumber = null;
                _pendingFinalAmount = null;
                _pendingChange = null;
              });
              AppToast.showError(context, state.message);
            }
          },
        ),
        BlocListener<CustomersCubit, CustomersState>(
          listener: (context, state) {
            if (state is CustomersLoaded && state.customers.isNotEmpty) {
              if (_selectedCustomer == null) {
                setState(() {
                  _selectedCustomer = state.customers.first;
                });
              }
            }
          },
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme, isDark),
          body: SafeArea(
            child: Column(
              children: [
                _buildStepperHeader(theme, isDark),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_currentStep) {
                      0 => _buildStep0ProductSelection(theme, isDark),
                      1 => _buildStep1CartAndCustomer(theme, isDark),
                      2 => _buildStep2PaymentAndFinalize(theme, isDark),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== App Bar ====================

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _currentStep > 0
          ? IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              onPressed: () => setState(() => _currentStep--),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.4)
                  : AppColors.saudiMint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.point_of_sale_rounded,
                  size: 18,
                  color: AppColors.saudiEmerald,
                ),
                const SizedBox(width: 6),
                Text(
                  'نقطة البيع (POS)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.emerald300 : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_cart.isNotEmpty)
          IconButton(
            tooltip: 'مسح السلة',
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: AppColors.error,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد مسح السلة'),
                  content: const Text(
                    'هل أنت متأكد من تفريغ كافة الأصناف في السلة الحالية؟',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearCart();
                      },
                      child: const Text('مسح السلة'),
                    ),
                  ],
                ),
              );
            },
          ),
        IconButton(
          tooltip: 'قائمة الفواتير',
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () => context.go('/sales/list'),
        ),
      ],
    );
  }

  // ==================== Stepper Header ====================

  Widget _buildStepperHeader(ThemeData theme, bool isDark) {
    final steps = [
      {'title': '١. الأصناف', 'icon': Icons.inventory_2_outlined},
      {'title': '٢. السلة والعميل', 'icon': Icons.shopping_bag_outlined},
      {'title': '٣. الدفع والإنهاء', 'icon': Icons.payments_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = _currentStep == index;
          final isCompleted = _currentStep > index;

          return Expanded(
            child: InkWell(
              onTap: () {
                if (index <= _currentStep || _cart.isNotEmpty) {
                  setState(() => _currentStep = index);
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.saudiEmerald
                            : isActive
                            ? (isDark
                                  ? AppColors.emerald400
                                  : AppColors.primary)
                            : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.slate200),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        steps[index]['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive
                              ? (isDark
                                    ? AppColors.emerald300
                                    : AppColors.primary)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==================== Step 0: Product Selection ====================

  Widget _buildWarehouseSelector(ThemeData theme, bool isDark) {
    if (_isLoadingWarehouses) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_warehouses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: CustomDropdownField<int>(
        value: _selectedWarehouseId,
        label: 'المخزن',
        prefixIcon: const Icon(Icons.warehouse_outlined, size: 18),
        items: _warehouses.map((w) {
          return DropdownMenuItem<int>(
            value: w.id,
            child: Text(
              '${w.name}${w.isMainStock == true ? " (الرئيسي)" : ""}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val == null || val == _selectedWarehouseId) return;
          if (_cart.isNotEmpty) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('تغيير المخزن'),
                content: const Text('تغيير المخزن سيفرغ السلة الحالية لأن الأصناف مرتبطة بالمخزن محاسبياً. هل تريد المتابعة؟'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedWarehouseId = val;
                        _cart.clear();
                      });
                      AppToast.showSuccess(context, 'تم تغيير المخزن، يرجى إعادة إضافة الأصناف');
                    },
                    child: const Text('متابعة ومسح السلة'),
                  ),
                ],
              ),
            );
          } else {
            setState(() => _selectedWarehouseId = val);
          }
        },
      ),
    );
  }

  Widget _buildStep0ProductSelection(ThemeData theme, bool isDark) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final products = state is ProductsLoaded
            ? state.products
            : <ProductEntity>[];
        final filtered = _filteredProducts(products);

        return Column(
          children: [
            // Warehouse Selector (محاسبي)
            _buildWarehouseSelector(theme, isDark),
            // Search & Barcode Scan Bar
            _buildSearchBar(theme, isDark, products),

            // Product Groups Filter Chips
            _buildGroupChips(theme, isDark),

            // Products Grid
            Expanded(
              child: state is ProductsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? _buildEmptyProductsState(theme)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisExtent: 175,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final id = product.id ?? 0;
                        final inCart = _cart.containsKey(id);
                        final line = _cart[id];

                        return _buildProductCard(
                          theme,
                          isDark,
                          product,
                          inCart,
                          line,
                        );
                      },
                    ),
            ),

            // Sticky Bottom Cart Bar
            if (_cart.isNotEmpty) _buildBottomCartBar(theme, isDark),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(
    ThemeData theme,
    bool isDark,
    List<ProductEntity> products,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم المنتج أو رقم الباركود...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.saudiEmerald,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: () => _scanBarcode(products),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChips(ThemeData theme, bool isDark) {
    return BlocBuilder<ProductGroupsCubit, ProductGroupsState>(
      builder: (context, groupState) {
        final groups = groupState is ProductGroupsLoaded
            ? groupState.groups
            : <ProductGroupEntity>[];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _buildCategoryChip('الكل', _selectedGroupId == null, () {
                setState(() => _selectedGroupId = null);
              }, isDark),
              ...groups.map((g) {
                final isSelected = _selectedGroupId == g.id;
                return _buildCategoryChip(g.name, isSelected, () {
                  setState(() => _selectedGroupId = isSelected ? null : g.id);
                }, isDark);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String title,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(title),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: isDark ? AppColors.primaryLight : AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl28),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.borderDark : AppColors.slate200),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildProductCard(
    ThemeData theme,
    bool isDark,
    ProductEntity product,
    bool inCart,
    _PosLine? line,
  ) {
    final price = product.sellAmount ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: inCart ? AppColors.saudiEmerald : theme.dividerColor,
          width: inCart ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: inCart
                ? AppColors.saudiEmerald.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: inCart ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          // إذا كان للصنف وحدات متعددة، اعرض اختيار الوحدة قبل الإضافة (المبيعات يتطلب تحديد الوحدة)
          try {
            final svc = getIt<UnitConversionService>();
            final units = await svc.getUnitsForProduct(product.id!);
            if (units.length > 1 && context.mounted) {
              final basePrice = product.sellAmount ?? 0.0;
              final picked = await _showPosUnitPicker(
                context,
                product,
                units,
                basePrice,
              );
              if (picked != null && context.mounted) {
                await _addProduct(product, forcedUnit: picked);
                return;
              }
              // إذا أغلق بدون اختيار، لا تضف
              return;
            }
          } catch (_) {}
          await _addProduct(product);
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.3)
                          : AppColors.saudiMint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.saudiEmerald,
                      size: 18,
                    ),
                  ),
                  if (inCart)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.saudiEmerald,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${line?.quantity.toInt() ?? 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${NumberFormatter.formatNumber(price)} ${_getCurrencySymbol()}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.emerald300
                              : AppColors.primary,
                        ),
                      ),
                      if (product.trackInventory)
                        Text(
                          'المتاح: ${NumberFormatter.formatNumber(product.quantity)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: product.quantity > 0
                                ? theme.colorScheme.onSurfaceVariant
                                : AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCartBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.4)
                  : AppColors.saudiMint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.saudiEmerald,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_totalItemUnits قطعة ($_totalItemCount صنف)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${NumberFormatter.formatNumber(_subtotal)} ${_getCurrencySymbol()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.emerald300 : AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => setState(() => _currentStep = 1),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.saudiEmerald,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'مراجعة الطلب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  int get _totalItemCount => _cart.length;

  Widget _buildEmptyProductsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: theme.dividerColor),
          const SizedBox(height: 12),
          Text(
            'لا توجد أصناف مطابقة للبحث',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Step 1: Cart & Customer Review ====================

  Widget _buildStep1CartAndCustomer(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Customer Selection Card
          _buildCustomerSection(theme, isDark),

          const SizedBox(height: 16),

          // 2. Cart Items Table
          _buildCartItemsList(theme, isDark),

          const SizedBox(height: 16),

          // 3. Discount & Notes Section
          _buildDiscountAndNotesSection(theme, isDark),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('إضافة أصناف'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _cart.isEmpty
                      ? null
                      : () => setState(() => _currentStep = 2),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.saudiEmerald,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'متابعة للدفع',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.3)
                          : AppColors.saudiMint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.saudiEmerald,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'بيانات العميل',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _openCustomerPicker,
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: Text(
                  _selectedCustomer == null ? 'اختيار عميل' : 'تغيير',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardSurfaceDark : AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedCustomer == null
                      ? Icons.storefront_outlined
                      : Icons.account_circle_outlined,
                  color: AppColors.saudiEmerald,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer?.name ?? 'عميل نقدي عام (كاش)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      if (_selectedCustomer?.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'هاتف: ${_selectedCustomer!.phone}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_selectedCustomer != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'الرصيد الحالي',
                        style: TextStyle(fontSize: 10.5),
                      ),
                      Text(
                        '${NumberFormatter.formatNumber(_selectedCustomer!.balance)} ${_getCurrencySymbol()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedCustomer!.balance > 0
                              ? AppColors.error
                              : AppColors.saudiEmerald,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أصناف الفاتورة ($_totalItemCount صنف)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'الإجمالي: ${NumberFormatter.formatNumber(_subtotal)} ${_getCurrencySymbol()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.emerald300 : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._cart.values.map((line) {
            final id = line.product.id!;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardSurfaceDark : AppColors.slate50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () async {
                            try {
                              final svc = getIt<UnitConversionService>();
                              final units = await svc.getUnitsForProduct(
                                line.product.id!,
                              );
                              if (units.length <= 1) return;
                              if (!context.mounted) return;
                              final picked = await _showPosUnitPicker(
                                context,
                                line.product,
                                units,
                                line.product.sellAmount ?? 0,
                              );
                              if (picked != null) {
                                await _changeLineUnit(line.product.id!, picked);
                              }
                            } catch (_) {}
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${NumberFormatter.formatNumber(line.unitPrice)} ${_getCurrencySymbol()} / ${line.unitDisplay}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.swap_horiz,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                        if (line.unitOption != null &&
                            line.unitOption!.totalConversion > 1)
                          Text(
                            'الأساس: ${PrecisionHelper.roundQuantity(line.baseQuantity).toStringAsFixed(line.baseQuantity % 1 == 0 ? 0 : 2)} حبة',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blueGrey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                        onPressed: () => _changeQuantity(id, -1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          '${line.quantity.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: AppColors.saudiEmerald,
                        ),
                        onPressed: () => _changeQuantity(id, 1),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      NumberFormatter.formatNumber(line.total),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDiscountAndNotesSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الخصم والملاحظات',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'قيمة الخصم',
                    hintText: '0.0',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.cardSurfaceDark
                        : AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SegmentedButton<DiscountType>(
                segments: const [
                  ButtonSegment(
                    value: DiscountType.amount,
                    label: Text('مبلغ'),
                  ),
                  ButtonSegment(value: DiscountType.percent, label: Text('%')),
                ],
                selected: {_discountType},
                onSelectionChanged: (val) {
                  setState(() => _discountType = val.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _statementController,
            decoration: InputDecoration(
              labelText: 'ملاحظات الفاتورة (اختياري)',
              hintText: 'مثال: خصم خاص، دفعة أولى...',
              filled: true,
              fillColor: isDark ? AppColors.cardSurfaceDark : AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Step 2: Payment & Finalize ====================

  Widget _buildStep2PaymentAndFinalize(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Card
          _buildFinancialSummaryCard(theme, isDark),

          const SizedBox(height: 16),

          // Payment Methods Cards
          _buildPaymentMethodsSection(theme, isDark),

          const SizedBox(height: 12),

          // Submit / Finalize Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveInvoice,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.saudiEmerald,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 22),
              label: Text(
                _saving
                    ? 'جاري الحفظ والتسجيل...'
                    : 'تأكيد وإتمام الفاتورة (${NumberFormatter.formatNumber(_grandTotal)} ${_getCurrencySymbol()})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الحساب والفاتورة',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'إجمالي الأصناف ($_totalItemUnits قطعة):',
            '${NumberFormatter.formatNumber(_subtotal)} ${_getCurrencySymbol()}',
            theme,
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow(
              'الخصم:',
              '- ${NumberFormatter.formatNumber(_discountAmount)} ${_getCurrencySymbol()}',
              theme,
              color: AppColors.error,
            ),
          ],
          if (SettingsCache.taxEnabled) ...[
            const SizedBox(height: 6),
            _buildSummaryRow(
              'ضريبة القيمة المضافة ($_taxRate%):',
              '+ ${NumberFormatter.formatNumber(_taxAmount)} ${_getCurrencySymbol()}',
              theme,
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي المستحق:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${NumberFormatter.formatNumber(_grandTotal)} ${_getCurrencySymbol()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.emerald300 : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'طريقة الدفع والتسديد',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              if (_isLoadingBanksAndFunds)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPaymentTile(
                  isSplit: false,
                  method: PaymentMethod.cash,
                  title: 'نقدي',
                  icon: Icons.payments_outlined,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildPaymentTile(
                  isSplit: false,
                  method: PaymentMethod.bank,
                  title: 'شبكة / بنك',
                  icon: Icons.credit_card_rounded,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildPaymentTile(
                  isSplit: false,
                  method: PaymentMethod.deferred,
                  title: 'آجل',
                  icon: Icons.schedule_rounded,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildPaymentTile(
                  isSplit: true,
                  method: PaymentMethod.cash,
                  title: 'دفع مقسم',
                  icon: Icons.call_split_rounded,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic fields depending on payment mode
          if (_isSplitPayment) ...[
            _buildSplitPaymentSection(theme, isDark),
          ] else if (_paymentMethod == PaymentMethod.cash) ...[
            _buildCashboxSelector(theme, isDark),
            const SizedBox(height: 12),
            _buildCashTenderHelper(theme, isDark),
          ] else if (_paymentMethod == PaymentMethod.bank) ...[
            _buildBankDetailsSection(theme, isDark),
          ] else if (_paymentMethod == PaymentMethod.deferred) ...[
            _buildDeferredDetailsSection(theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required bool isSplit,
    required PaymentMethod method,
    required String title,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = isSplit
        ? _isSplitPayment
        : (!_isSplitPayment && _paymentMethod == method);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSplit) {
            _isSplitPayment = true;
            if (_splitCashController.text.isEmpty &&
                _splitBankController.text.isEmpty) {
              final half = _grandTotal / 2;
              _splitCashController.text = (half % 1 == 0)
                  ? half.toStringAsFixed(0)
                  : half.toStringAsFixed(2);
              final remaining = _grandTotal - half;
              _splitBankController.text = (remaining % 1 == 0)
                  ? remaining.toStringAsFixed(0)
                  : remaining.toStringAsFixed(2);
            }
          } else {
            _isSplitPayment = false;
            _paymentMethod = method;
          }
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.3)
                    : AppColors.saudiMint)
              : (isDark ? AppColors.cardSurfaceDark : AppColors.slate50),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.saudiEmerald : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.saudiEmerald
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.emerald300 : AppColors.primary)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashboxSelector(ThemeData theme, bool isDark) {
    if (_funds.isEmpty) return const SizedBox.shrink();

    return CustomDropdownField<int>(
      label: 'الصندوق المودع فيه',
      value: _selectedFundId ?? (_funds.firstOrNull?.id),
      items: _funds
          .map((f) => DropdownMenuItem<int>(value: f.id, child: Text(f.name)))
          .toList(),
      onChanged: (id) {
        setState(() {
          _selectedFundId = id;
          _selectedFundName = _funds.where((f) => f.id == id).firstOrNull?.name;
        });
      },
    );
  }

  Widget _buildBankDetailsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_banks.isNotEmpty) ...[
          CustomDropdownField<int>(
            label: 'الحساب البنكي / جهة التحويل',
            value: _selectedBankId ?? (_banks.firstOrNull?.id),
            items: _banks
                .map(
                  (b) =>
                      DropdownMenuItem<int>(value: b.id, child: Text(b.name)),
                )
                .toList(),
            onChanged: (id) {
              setState(() {
                _selectedBankId = id;
                _selectedBankName = _banks
                    .where((b) => b.id == id)
                    .firstOrNull
                    ?.name;
              });
            },
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bankRefController,
                decoration: InputDecoration(
                  labelText: 'رقم الإيصال / التفويض',
                  hintText: 'مثال: 987654',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardSurfaceDark
                      : AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _transferNumberController,
                decoration: InputDecoration(
                  labelText: 'رقم الحوالة (اختياري)',
                  hintText: 'رقم العملية',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardSurfaceDark
                      : AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _senderNameController,
          decoration: InputDecoration(
            labelText: 'اسم المحوّل / المستلم (اختياري)',
            hintText: 'اسم صاحب الحساب أو المرسل',
            filled: true,
            fillColor: isDark ? AppColors.cardSurfaceDark : AppColors.slate50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeferredDetailsSection(ThemeData theme, bool isDark) {
    final dueDateFormatted = DateFormatter.formatDate(_effectiveDueDate);
    final daysRemaining = _effectiveDueDate.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryDark.withValues(alpha: 0.2)
                : AppColors.saudiMint,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.saudiEmerald.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.saudiEmerald,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCustomer != null
                      ? 'سيتم ترحيل الفاتورة لحساب العميل: ${_selectedCustomer!.name}'
                      : 'تنبيه: يجب اختيار عميل مسجل لإتمام البيع الآجل.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _effectiveDueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (picked != null) {
              setState(() => _dueDate = picked);
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardSurfaceDark : AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.saudiEmerald,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تاريخ الاستحقاق',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueDateFormatted,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.saudiEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysRemaining >= 0 ? '$daysRemaining يوم' : 'مستحق اليوم',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.saudiEmerald,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_calendar_outlined, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitPaymentSection(ThemeData theme, bool isDark) {
    final splitCash = double.tryParse(_splitCashController.text.trim()) ?? 0.0;
    final splitBank = double.tryParse(_splitBankController.text.trim()) ?? 0.0;
    final splitDeferred = (_grandTotal - splitCash - splitBank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cash portion
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardSurfaceDark : AppColors.slate50,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.saudiEmerald,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'الدفعة النقدية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  if (_funds.isNotEmpty)
                    DropdownButton<int>(
                      value: _selectedFundId ?? _funds.firstOrNull?.id,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                      items: _funds
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(() {
                        _selectedFundId = id;
                        _selectedFundName = _funds
                            .where((f) => f.id == id)
                            .firstOrNull
                            ?.name;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _splitCashController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: _getCurrencySymbol(),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Bank portion
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardSurfaceDark : AppColors.slate50,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.credit_card_rounded,
                    size: 18,
                    color: AppColors.saudiEmerald,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'الدفعة البنكية / شبكة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  if (_banks.isNotEmpty)
                    DropdownButton<int>(
                      value: _selectedBankId ?? _banks.firstOrNull?.id,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                      items: _banks
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(() {
                        _selectedBankId = id;
                        _selectedBankName = _banks
                            .where((b) => b.id == id)
                            .firstOrNull
                            ?.name;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _splitBankController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: _getCurrencySymbol(),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bankRefController,
                decoration: InputDecoration(
                  labelText: 'رقم المرجع / التفويض البنكي (اختياري)',
                  hintText: 'المرجع البنكي',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Split Summary & Deferred Breakdown
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: splitDeferred > 0.001
                ? (isDark
                      ? AppColors.saudiGold.withValues(alpha: 0.2)
                      : AppColors.warningLight)
                : (splitDeferred < -0.001
                      ? (isDark
                            ? AppColors.error.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.1))
                      : (isDark
                            ? AppColors.saudiEmerald.withValues(alpha: 0.2)
                            : AppColors.saudiMint)),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: splitDeferred > 0.001
                  ? AppColors.warning
                  : (splitDeferred < -0.001
                        ? AppColors.error
                        : AppColors.saudiEmerald),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    splitDeferred > 0.001
                        ? 'المتبقي آجل على العميل:'
                        : (splitDeferred < -0.001
                              ? 'تجاوز في المبلغ المدفوع:'
                              : 'حالة التسديد:'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    splitDeferred > 0.001
                        ? '${NumberFormatter.formatNumber(splitDeferred)} ${_getCurrencySymbol()}'
                        : (splitDeferred < -0.001
                              ? '${NumberFormatter.formatNumber(-splitDeferred)} ${_getCurrencySymbol()}'
                              : 'مسدد بالكامل ✓'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: splitDeferred > 0.001
                          ? (isDark ? AppColors.warning : AppColors.saudiGold)
                          : (splitDeferred < -0.001
                                ? AppColors.error
                                : AppColors.saudiEmerald),
                    ),
                  ),
                ],
              ),
              if (splitDeferred > 0.001) ...[
                const SizedBox(height: 8),
                Text(
                  _selectedCustomer != null
                      ? 'سيتم تسجيل المبلغ المتبقي كدين على العميل: ${_selectedCustomer!.name}'
                      : 'تنبيه: وجود متبقي آجل يتطلب تحديد عميل مسجل.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _selectedCustomer != null
                        ? AppColors.gray800
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _effectiveDueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: AppColors.saudiEmerald,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'استحقاق الأجل: ${DateFormatter.formatDate(_effectiveDueDate)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'تغيير',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.saudiEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashTenderHelper(ThemeData theme, bool isDark) {
    final quickAmounts = [_grandTotal, 50.0, 100.0, 200.0, 500.0, 1000.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cashReceivedController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'المبلغ المستلم من العميل',
                  hintText: NumberFormatter.formatNumber(_grandTotal),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardSurfaceDark
                      : AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.3)
                    : AppColors.saudiMint,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.saudiEmerald.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المتبقي (الفكة)',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.saudiEmerald,
                    ),
                  ),
                  Text(
                    '${NumberFormatter.formatNumber(_changeAmount)} ${_getCurrencySymbol()}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.saudiEmerald,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: quickAmounts.map((amt) {
              final isExact = (amt - _grandTotal).abs() < 0.01;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ActionChip(
                  label: Text(
                    isExact
                        ? 'المبلغ بالضبط'
                        : (amt % 1 == 0
                              ? '${amt.toInt()}'
                              : NumberFormatter.formatNumber(amt)),
                  ),
                  onPressed: () {
                    _cashReceivedController.text = (amt % 1 == 0)
                        ? amt.toStringAsFixed(0)
                        : amt.toStringAsFixed(2);
                    setState(() {});
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PosLine {
  final ProductEntity product;
  final double quantity;
  final ProductUnitOption? unitOption;
  final double unitPrice;

  _PosLine({
    required this.product,
    this.quantity = 1,
    this.unitOption,
    double? unitPrice,
  }) : unitPrice = unitPrice ?? (product.sellAmount ?? 0);

  double get total => PrecisionHelper.roundCurrency(unitPrice * quantity);
  double get baseQuantity => unitOption != null
      ? PrecisionHelper.calcBaseQuantity(
          quantity: quantity,
          packaging: unitOption!.packaging,
          conversionRate: unitOption!.conversionRate,
        )
      : quantity;

  String get unitDisplay => unitOption?.unitShort ?? 'حبة';

  _PosLine copyWith({
    double? quantity,
    ProductUnitOption? unitOption,
    double? unitPrice,
  }) => _PosLine(
    product: product,
    quantity: quantity ?? this.quantity,
    unitOption: unitOption ?? this.unitOption,
    unitPrice: unitPrice ?? this.unitPrice,
  );
}

// ==================== Customer Picker Sheet ====================

class _CustomerPickerSheet extends StatefulWidget {
  final Customer? selectedCustomer;
  final String currencySymbol;
  final VoidCallback onAddNewCustomer;

  const _CustomerPickerSheet({
    required this.selectedCustomer,
    required this.currencySymbol,
    required this.onAddNewCustomer,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تحديد العميل',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onAddNewCustomer,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saudiEmerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'عميل جديد',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _q = val),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم العميل أو رقم الهاتف...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardSurfaceDark
                      : AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Default Walk-in option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.saudiMint,
                child: Icon(
                  Icons.storefront_outlined,
                  color: AppColors.saudiEmerald,
                ),
              ),
              title: const Text(
                'عميل نقدي عام (كاش)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('مبيعات نقدية سريعة بدون حساب'),
              trailing: widget.selectedCustomer == null
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.saudiEmerald,
                    )
                  : null,
              onTap: () => Navigator.of(
                context,
              ).pop(Customer(id: '0', name: 'عميل نقدي عام (كاش)')),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) {
                  if (state is CustomersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CustomersLoaded) {
                    final query = _q.trim().toLowerCase();
                    final customers = state.customers.where((c) {
                      if (query.isEmpty) return true;
                      return c.name.toLowerCase().contains(query) ||
                          (c.phone?.toLowerCase().contains(query) ?? false);
                    }).toList();

                    if (customers.isEmpty) {
                      return const Center(
                        child: Text('لا يوجد عملاء مطابقين للبحث'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: customers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = customers[index];
                        final isSelected = widget.selectedCustomer?.id == c.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.saudiEmerald
                                : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.slate100),
                            child: Text(
                              c.name.isNotEmpty ? c.name.characters.first : 'ع',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: c.phone != null ? Text(c.phone!) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'الرصيد',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Text(
                                    '${NumberFormatter.formatNumber(c.balance)} ${widget.currencySymbol}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: c.balance > 0
                                          ? AppColors.error
                                          : AppColors.saudiEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.saudiEmerald,
                                ),
                              ],
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
