import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';

class AddLineDialog extends StatefulWidget {
  final InvoiceLineEntity? line;
  final Function(InvoiceLineEntity) onAdd;
  final int? stockId;
  final int? supplierId;

  const AddLineDialog({
    super.key,
    this.line,
    required this.onAdd,
    this.stockId,
    this.supplierId,
  });

  @override
  State<AddLineDialog> createState() => _AddLineDialogState();
}

class _AddLineDialogState extends State<AddLineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _barcodeController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedGroupId;
  int? _selectedUnitId;
  bool _initializedFromLine = false;

  List<ProductUnitOption> _availableUnits = [];
  ProductUnitOption? _selectedUnitOption;
  bool _loadingUnits = false;
  double _total = 0.0;
  double _selectedProductBaseCost = 0.0;
  double _selectedProductBaseSell = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.line != null) {
      _selectedCategoryId = widget.line!.categoryId;
      _selectedGroupId = widget.line!.groupId;
      _selectedUnitId = widget.line!.unitId;
      _quantityController.text = widget.line!.quantity.toString();
      final unitPrice = widget.line!.quantity == 0
          ? 0.0
          : (widget.line!.amount / widget.line!.quantity);
      _priceController.text = unitPrice.toStringAsFixed(2);
      _discountController.text = (widget.line!.discountAmt ?? 0).toString();
      _initializedFromLine = true;
      _calculateTotal();
      if (_selectedCategoryId != null)
        _loadUnitsForProduct(_selectedCategoryId!);
    }
  }

  Future<void> _loadUnitsForProduct(int productId) async {
    setState(() => _loadingUnits = true);
    try {
      final svc = getIt<UnitConversionService>();
      final units = await svc.getUnitsForProduct(productId);
      ProductUnitOption? def;
      try {
        def = await svc.getDefaultPurchaseUnit(productId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _availableUnits = units;
        if (units.isNotEmpty) {
          if (_selectedUnitId != null) {
            _selectedUnitOption = units.firstWhere(
              (u) => u.unitId == _selectedUnitId,
              orElse: () => def ?? units.first,
            );
          } else {
            _selectedUnitOption = def ?? units.first;
            _selectedUnitId = _selectedUnitOption?.unitId;
          }
          // Auto-price if field empty
          if (_priceController.text.isEmpty ||
              _priceController.text == '0' ||
              _priceController.text == '0.00') {
            // Try to find product cost
            // Will be set via _onProductSelected caller
          }
        }
        _loadingUnits = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingUnits = false);
    }
  }

  Future<void> _onProductSelected(ProductEntity product) async {
    setState(() {
      _selectedCategoryId = product.id;
      _selectedGroupId = product.groupId ?? 1;
      _selectedUnitId = product.unitId ?? 1;
      _selectedProductBaseCost = product.costAmount ?? product.sellAmount ?? 0.0;
      _selectedProductBaseSell = product.sellAmount ?? product.costAmount ?? 0.0;
    });
    await _loadUnitsForProduct(product.id!);
    // Resolve price per selected unit - دائماً حدث السعر تلقائياً عند تغيير الصنف أو الوحدة
    if (_selectedUnitOption != null) {
      final svc = getIt<UnitConversionService>();
      final resolved = _selectedUnitOption!.costPrice ??
          svc.resolveUnitCost(
            baseCost: _selectedProductBaseCost,
            unit: _selectedUnitOption!,
          );
      _priceController.text = PrecisionHelper.roundCurrency(resolved)
          .toStringAsFixed(2);
    } else {
      _priceController.text = PrecisionHelper.roundCurrency(
        _selectedProductBaseCost,
      ).toStringAsFixed(2);
    }
    _calculateTotal();
  }

  void _onUnitChanged(ProductUnitOption? unit) {
    if (unit == null) return;
    setState(() {
      _selectedUnitOption = unit;
      _selectedUnitId = unit.unitId;
    });
    // التغيير التلقائي للسعر عند تغيير الوحدة - يعاد احتساب الإجمالي (الكمية × السعر)
    if (_selectedCategoryId != null) {
      final svc = getIt<UnitConversionService>();
      final resolved = unit.costPrice ??
          svc.resolveUnitCost(
            baseCost: _selectedProductBaseCost,
            unit: unit,
          );
      _priceController.text = PrecisionHelper.roundCurrency(resolved)
          .toStringAsFixed(2);
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    setState(() {
      _total = PrecisionHelper.roundCurrency((quantity * price) - discount);
    });
  }

  void _save(List<ProductEntity> products) {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null && products.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الصنف')));
        return;
      }

      final unitPrice = double.parse(_priceController.text);
      final quantity = double.parse(_quantityController.text);
      final discountAmount = double.tryParse(_discountController.text) ?? 0;
      final amount = PrecisionHelper.roundCurrency(quantity * unitPrice);

      final selectedUnit = _selectedUnitOption;
      final conversionRate = selectedUnit?.conversionRate ?? 1.0;
      final packaging = selectedUnit?.packaging ?? 1;
      final baseQty = PrecisionHelper.calcBaseQuantity(
        quantity: quantity,
        packaging: packaging,
        conversionRate: conversionRate,
      );
      final subUnitId =
          selectedUnit?.subUnitId ?? widget.line?.categorySubUnitId ?? 1;
      final unitIdToSave = selectedUnit?.unitId ?? _selectedUnitId ?? 1;

      final line = InvoiceLineEntity(
        id: widget.line?.id,
        invoiceId: widget.line?.invoiceId ?? 0,
        invoiceType: 2,
        categoryId: _selectedCategoryId,
        groupId: _selectedGroupId ?? 1,
        unitId: unitIdToSave,
        categorySubUnitId: subUnitId,
        stockId: widget.stockId ?? widget.line?.stockId ?? 1,
        customerId: widget.supplierId ?? widget.line?.customerId ?? 1,
        amount: amount,
        totalAmount: PrecisionHelper.roundCurrency(amount - discountAmount),
        discountAmt: discountAmount,
        taxAmt: 0,
        netRevenueAmt: PrecisionHelper.roundCurrency(amount - discountAmount),
        quantity: quantity,
        baseQuantity: baseQty,
        conversionRate: conversionRate,
        packaging: packaging,
        price: unitPrice,
        costPrice: unitPrice,
        costTotal: PrecisionHelper.roundCurrency(amount - discountAmount),
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        invoiceTransType: 1,
      );

      widget.onAdd(line);
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleBarcodeChanged(
    String code,
    List<ProductEntity> products,
  ) async {
    if (code.trim().isEmpty) return;
    try {
      final svc = getIt<UnitConversionService>();
      final lookup = await svc.lookupByBarcode(code.trim());
      if (lookup != null && mounted) {
        final prod = products.firstWhere(
          (p) => p.id == lookup.productId,
          orElse: () => products.first,
        );
        if (lookup.unit != null) {
          setState(() {
            _selectedUnitOption = lookup.unit;
            _selectedUnitId = lookup.unit!.unitId;
          });
        }
        await _onProductSelected(prod);
        if (lookup.unit?.sellPrice != null) {
          _priceController.text = lookup.unit!.sellPrice!.toStringAsFixed(2);
          _calculateTotal();
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductsCubit>()..loadProducts(),
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          final List<ProductEntity> products = switch (state) {
            ProductsLoaded(products: final p) => p,
            _ => const <ProductEntity>[],
          };
          final isLoading = state is ProductsLoading;

          if (products.isNotEmpty &&
              _selectedCategoryId == null &&
              !_initializedFromLine) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedCategoryId == null) {
                _onProductSelected(products.first);
              }
            });
          }

          return CustomDialog(
            title: widget.line != null ? 'تعديل الصنف' : 'إضافة صنف مشتريات',
            icon: Icons.add_shopping_cart,
            maxWidth: 500,
            content: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (products.isNotEmpty) ...[
                          const Text(
                            'الصنف',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.inventory_2_outlined,
                              ),
                            ),
                            items: products.map((prod) {
                              final id = prod.id!;
                              final name = prod.name;
                              final code = prod.barcodeNo;
                              final label = code.isNotEmpty
                                  ? '$name ($code)'
                                  : name;
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final selected = products.firstWhere(
                                  (p) => p.id == val,
                                );
                                _onProductSelected(selected);
                              }
                            },
                            validator: (val) =>
                                val == null ? 'يرجى اختيار الصنف' : null,
                          ),
                          const SizedBox(height: 12),
                          // Barcode quick entry for smart unit detection
                          TextInputField(
                            label: 'باركود (اختياري - للبحث الذكي)',
                            textEditingController: _barcodeController,
                            prefixIcon: const Icon(Icons.qr_code_2),
                            inputType: TextInputType.text,
                            onChanged: (v) =>
                                _handleBarcodeChanged(v, products),
                          ),
                          const SizedBox(height: 12),
                          // Unit selector dropdown
                          if (_loadingUnits)
                            const LinearProgressIndicator()
                          else if (_availableUnits.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'الوحدة',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<ProductUnitOption>(
                                  value: _selectedUnitOption,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    prefixIcon: const Icon(Icons.straighten),
                                  ),
                                  items: _availableUnits
                                      .map(
                                        (u) =>
                                            DropdownMenuItem<ProductUnitOption>(
                                              value: u,
                                              child: Row(
                                                children: [
                                                  Text(u.unitName),
                                                  const SizedBox(width: 6),
                                                  if (!u.isMainUnit)
                                                    Text(
                                                      '(${u.packaging} x)',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  if (u.barcode != null &&
                                                      u.barcode!.isNotEmpty)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 4,
                                                      ),
                                                      child: Icon(
                                                        Icons.qr_code,
                                                        size: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: _onUnitChanged,
                                ),
                                const SizedBox(height: 6),
                                if (_selectedUnitOption != null)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'معامل التحويل: ${_selectedUnitOption!.totalConversion.toStringAsFixed(2)} → الكمية الأساسية = الكمية × ${_selectedUnitOption!.totalConversion}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                              ],
                            ),
                        ] else if (!isLoading) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(30),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'لم يتم العثور على أصناف مسجلة. يرجى إضافة أصناف أولاً من إدارة المنتجات.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextInputField(
                                label: 'الكمية',
                                textEditingController: _quantityController,
                                inputType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                prefixIcon: const Icon(Icons.numbers),
                                isRequired: true,
                                onChanged: (_) => _calculateTotal(),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'الكمية مطلوبة';
                                  final q = double.tryParse(value);
                                  if (q == null || q <= 0)
                                    return 'أدخل كمية صحيحة';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextInputField(
                                label: 'سعر الشراء للوحدة',
                                textEditingController: _priceController,
                                inputType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                prefixIcon: const Icon(Icons.attach_money),
                                isRequired: true,
                                onChanged: (_) => _calculateTotal(),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'السعر مطلوب';
                                  final p = double.tryParse(value);
                                  if (p == null || p < 0)
                                    return 'أدخل سعر صحيح';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_selectedUnitOption != null)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'الكمية الأساسية: ${PrecisionHelper.calcBaseQuantity(quantity: double.tryParse(_quantityController.text) ?? 0, packaging: _selectedUnitOption!.packaging, conversionRate: _selectedUnitOption!.conversionRate).toStringAsFixed(2)} حبة',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextInputField(
                          label: 'الخصم على الصنف',
                          textEditingController: _discountController,
                          inputType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          prefixIcon: const Icon(Icons.discount_outlined),
                          onChanged: (_) => _calculateTotal(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'إجمالي الصنف:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_total.toStringAsFixed(2)} ريال',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: [
              HasibButton(
                label: 'إلغاء',
                onPressed: () => Navigator.of(context).pop(),
                variant: HasibButtonVariant.secondary,
              ),
              const SizedBox(width: 12),
              HasibButton(
                label: widget.line != null ? 'تحديث' : 'إضافة',
                onPressed: products.isEmpty ? null : () => _save(products),
                variant: HasibButtonVariant.primary,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}
