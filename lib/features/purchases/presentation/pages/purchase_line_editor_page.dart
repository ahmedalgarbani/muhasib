import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';

/// صفحة إضافة/تعديل بند مشتريات - تصميم صفحة كاملة بدل Dialog
class PurchaseLineEditorPage extends StatefulWidget {
  final InvoiceLineEntity? line;
  final int? stockId;
  final int? supplierId;

  const PurchaseLineEditorPage({
    super.key,
    this.line,
    this.stockId,
    this.supplierId,
  });

  @override
  State<PurchaseLineEditorPage> createState() => _PurchaseLineEditorPageState();
}

class _PurchaseLineEditorPageState extends State<PurchaseLineEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _barcodeCtrl = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedGroupId;
  int? _selectedUnitId;

  List<ProductUnitOption> _units = [];
  ProductUnitOption? _selectedUnit;
  bool _loadingUnits = false;
  double _total = 0;
  double _baseCost = 0;

  @override
  void initState() {
    super.initState();
    if (widget.line != null) {
      _selectedCategoryId = widget.line!.categoryId;
      _selectedGroupId = widget.line!.groupId;
      _selectedUnitId = widget.line!.unitId;
      _quantityCtrl.text = widget.line!.quantity.toString();
      final unitPrice = widget.line!.quantity == 0 ? 0.0 : (widget.line!.amount / widget.line!.quantity);
      _priceCtrl.text = unitPrice.toStringAsFixed(2);
      _discountCtrl.text = (widget.line!.discountAmt ?? 0).toString();
      _calculateTotal();
      if (_selectedCategoryId != null) _loadUnits(_selectedCategoryId!);
    }
  }

  Future<void> _loadUnits(int productId) async {
    setState(() => _loadingUnits = true);
    try {
      final svc = getIt<UnitConversionService>();
      final units = await svc.getUnitsForProduct(productId);
      final def = await svc.getDefaultPurchaseUnit(productId).catchError((_) => null);
      if (!mounted) return;
      setState(() {
        _units = units;
        if (units.isNotEmpty) {
          if (_selectedUnitId != null) {
            _selectedUnit = units.firstWhere((u) => u.unitId == _selectedUnitId, orElse: () => def ?? units.first);
          } else {
            _selectedUnit = def ?? units.first;
            _selectedUnitId = _selectedUnit?.unitId;
          }
        }
        _loadingUnits = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingUnits = false);
    }
  }

  Future<void> _onProductSelected(ProductEntity p) async {
    setState(() {
      _selectedCategoryId = p.id;
      _selectedGroupId = p.groupId ?? 1;
      _selectedUnitId = p.unitId ?? 1;
      _baseCost = p.costAmount ?? p.sellAmount ?? 0;
    });
    await _loadUnits(p.id!);
    if (_selectedUnit != null) {
      final svc = getIt<UnitConversionService>();
      final resolved = _selectedUnit!.costPrice ?? svc.resolveUnitCost(baseCost: _baseCost, unit: _selectedUnit!);
      _priceCtrl.text = PrecisionHelper.roundCurrency(resolved).toStringAsFixed(2);
    } else {
      _priceCtrl.text = PrecisionHelper.roundCurrency(_baseCost).toStringAsFixed(2);
    }
    _calculateTotal();
  }

  void _onUnitChanged(ProductUnitOption? u) {
    if (u == null) return;
    setState(() {
      _selectedUnit = u;
      _selectedUnitId = u.unitId;
    });
    final svc = getIt<UnitConversionService>();
    final resolved = u.costPrice ?? svc.resolveUnitCost(baseCost: _baseCost, unit: u);
    _priceCtrl.text = PrecisionHelper.roundCurrency(resolved).toStringAsFixed(2);
    _calculateTotal();
  }

  void _calculateTotal() {
    final qty = double.tryParse(_quantityCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    setState(() => _total = PrecisionHelper.roundCurrency(qty * price - disc));
  }

  void _save(List<ProductEntity> products) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الصنف')));
      return;
    }
    final price = double.parse(_priceCtrl.text);
    final qty = double.parse(_quantityCtrl.text);
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    final amount = PrecisionHelper.roundCurrency(qty * price);
    final conv = _selectedUnit?.conversionRate ?? 1.0;
    final pack = _selectedUnit?.packaging ?? 1;
    final baseQty = PrecisionHelper.calcBaseQuantity(quantity: qty, packaging: pack, conversionRate: conv);
    final line = InvoiceLineEntity(
      id: widget.line?.id,
      invoiceId: widget.line?.invoiceId ?? 0,
      invoiceType: 2,
      categoryId: _selectedCategoryId,
      groupId: _selectedGroupId ?? 1,
      unitId: _selectedUnit?.unitId ?? _selectedUnitId ?? 1,
      categorySubUnitId: _selectedUnit?.subUnitId ?? widget.line?.categorySubUnitId ?? 1,
      stockId: widget.stockId ?? widget.line?.stockId ?? 1,
      customerId: widget.supplierId ?? widget.line?.customerId ?? 1,
      amount: amount,
      totalAmount: PrecisionHelper.roundCurrency(amount - disc),
      discountAmt: disc,
      taxAmt: 0,
      netRevenueAmt: PrecisionHelper.roundCurrency(amount - disc),
      quantity: qty,
      baseQuantity: baseQty,
      conversionRate: conv,
      packaging: pack,
      price: price,
      costPrice: price,
      costTotal: PrecisionHelper.roundCurrency(amount - disc),
      date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      invoiceTransType: 1,
    );
    Navigator.pop(context, line);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductsCubit>()..loadProducts(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(title: widget.line != null ? 'تعديل بند مشتريات' : 'إضافة بند مشتريات'),
        body: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            final products = state is ProductsLoaded ? state.products : <ProductEntity>[];
            final loading = state is ProductsLoading;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CustomCardContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          if (loading)
                            const LinearProgressIndicator()
                          else
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
                              ),
                              hint: const Text('اختر الصنف'),
                              items: products
                                  .map((p) => DropdownMenuItem<int>(
                                        value: p.id,
                                        child: Text(p.barcodeNo.isNotEmpty ? '${p.name} (${p.barcodeNo})' : p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  final sel = products.firstWhere((e) => e.id == v);
                                  _onProductSelected(sel);
                                }
                              },
                              validator: (v) => v == null ? 'يرجى اختيار الصنف' : null,
                            ),
                          const SizedBox(height: 12),
                          TextInputField(
                            label: 'باركود (للبحث الذكي)',
                            textEditingController: _barcodeCtrl,
                            prefixIcon: const Icon(Icons.qr_code_2, size: 18),
                            hint: 'امسح أو اكتب باركود الوحدة',
                            onChanged: (v) async {
                              if (v.trim().isEmpty) return;
                              try {
                                final svc = getIt<UnitConversionService>();
                                final lookup = await svc.lookupByBarcode(v.trim());
                                if (lookup != null && mounted) {
                                  final prod = products.firstWhere((e) => e.id == lookup.productId, orElse: () => products.first);
                                  if (lookup.unit != null) {
                                    setState(() {
                                      _selectedUnit = lookup.unit;
                                      _selectedUnitId = lookup.unit!.unitId;
                                    });
                                  }
                                  await _onProductSelected(prod);
                                  if (lookup.unit?.costPrice != null) {
                                    _priceCtrl.text = lookup.unit!.costPrice!.toStringAsFixed(2);
                                    _calculateTotal();
                                  }
                                }
                              } catch (_) {}
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_loadingUnits)
                            const LinearProgressIndicator()
                          else if (_units.isNotEmpty) ...[
                            CustomDropdownField<ProductUnitOption>(
                              value: _selectedUnit,
                              label: 'الوحدة',
                              prefixIcon: const Icon(Icons.straighten, size: 16),
                              items: _units
                                  .map((u) => DropdownMenuItem<ProductUnitOption>(
                                        value: u,
                                        child: Row(children: [
                                          Text(u.unitName, style: const TextStyle(fontSize: 13)),
                                          if (!u.isMainUnit) ...[
                                            const SizedBox(width: 6),
                                            Text('(${u.packaging}×)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          ],
                                          if (u.isDefaultPurchase) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.star, size: 12, color: Colors.amber),
                                          ],
                                        ]),
                                      ))
                                  .toList(),
                              onChanged: _onUnitChanged,
                            ),
                            const SizedBox(height: 6),
                            if (_selectedUnit != null)
                              Text(
                                'معامل التحويل: ${ _selectedUnit!.totalConversion.toStringAsFixed(_selectedUnit!.totalConversion % 1 == 0 ? 0 : 2)}  •  الكمية الأساسية = الكمية × ${ _selectedUnit!.totalConversion}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCardContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(
                              child: TextInputField(
                                label: 'الكمية',
                                textEditingController: _quantityCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                prefixIcon: const Icon(Icons.numbers, size: 16),
                                isRequired: true,
                                onChanged: (_) => _calculateTotal(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'مطلوبة';
                                  final q = double.tryParse(v);
                                  if (q == null || q <= 0) return 'كمية صحيحة';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextInputField(
                                label: 'سعر الشراء',
                                textEditingController: _priceCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                prefixIcon: const Icon(Icons.attach_money, size: 16),
                                isRequired: true,
                                onChanged: (_) => _calculateTotal(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'مطلوب';
                                  final p = double.tryParse(v);
                                  if (p == null || p < 0) return 'سعر صحيح';
                                  return null;
                                },
                              ),
                            ),
                          ]),
                          if (_selectedUnit != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الكمية الأساسية: ${PrecisionHelper.calcBaseQuantity(quantity: double.tryParse(_quantityCtrl.text) ?? 0, packaging: _selectedUnit!.packaging, conversionRate: _selectedUnit!.conversionRate).toStringAsFixed(2)} حبة',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextInputField(
                            label: 'الخصم',
                            textEditingController: _discountCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            prefixIcon: const Icon(Icons.discount_outlined, size: 16),
                            onChanged: (_) => _calculateTotal(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${_total.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HasibButton(
                        label: widget.line != null ? 'تحديث' : 'إضافة',
                        onPressed: () => _save(products),
                        variant: HasibButtonVariant.primary,
                      ),
                    ),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
