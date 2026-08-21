import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/widgets/unit_picker_page.dart';

class ImprovedStep2Products extends StatefulWidget {
  final Invoice invoice;
  final ValueChanged<Invoice> onInvoiceUpdate;

  const ImprovedStep2Products({
    super.key,
    required this.invoice,
    required this.onInvoiceUpdate,
  });

  @override
  State<ImprovedStep2Products> createState() => _ImprovedStep2ProductsState();
}

class _ImprovedStep2ProductsState extends State<ImprovedStep2Products> {
  final _searchCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _discountCtrl.text = widget.invoice.discount.value.toStringAsFixed(widget.invoice.discount.value % 1 == 0 ? 0 : 2);
    _discountCtrl.addListener(_onDiscountChanged);
  }

  @override
  void didUpdateWidget(covariant ImprovedStep2Products oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice.discount.value != widget.invoice.discount.value ||
        oldWidget.invoice.discount.type != widget.invoice.discount.type) {
      _discountCtrl.text = widget.invoice.discount.value.toStringAsFixed(widget.invoice.discount.value % 1 == 0 ? 0 : 2);
    }
  }

  void _onDiscountChanged() {
    final v = double.tryParse(_discountCtrl.text) ?? 0;
    final max = SettingsCache.maxDiscountPercent;
    double clamped = v;
    if (widget.invoice.discount.type == DiscountType.percent && max != null && v > max) {
      clamped = max;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _discountCtrl.text = max.toStringAsFixed(max % 1 == 0 ? 0 : 2);
        _discountCtrl.selection = TextSelection.collapsed(offset: _discountCtrl.text.length);
      });
      AppToast.showWarning(context, 'الحد الأقصى لنسبة الخصم هو $max%');
    }
    widget.onInvoiceUpdate(widget.invoice.copyWith(discount: widget.invoice.discount.copyWith(value: clamped)));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAddProduct(dynamic product) async {
    final svc = getIt<UnitConversionService>();
    final units = await svc.getUnitsForProduct(product.id!);
    ProductUnitOption? selected;
    double basePrice = (product.sellAmount ?? product.sellLocalAmount ?? 0).toDouble();
    double price = basePrice;
    if (units.isNotEmpty) {
      selected = await svc.getDefaultSaleUnit(product.id!) ?? units.first;
      price = svc.resolveUnitPrice(baseSellPrice: basePrice, unit: selected);
      if (units.length > 1 && mounted) {
        final picked = await _showUnitPicker(context, product, units, basePrice);
        if (picked == null) return;
        selected = picked;
        price = svc.resolveUnitPrice(baseSellPrice: basePrice, unit: selected);
      }
    }

    if (SettingsCache.preventSaleLessThanCost && selected != null) {
      final costPerUnit = svc.resolveUnitCost(baseCost: product.costAmount ?? 0, unit: selected);
      if (price < costPerUnit) {
        if (mounted) AppToast.showError(context, 'لا يمكن البيع بسعر أقل من التكلفة');
        return;
      }
    }

    final existingIdx = widget.invoice.items.indexWhere((i) => i.id == product.id.toString() && i.unitId == (selected?.unitId ?? product.unitId));
    final stock = product.quantity.toInt();
    final track = product.trackInventory;
    final existingQty = existingIdx >= 0 ? widget.invoice.items[existingIdx].quantity : 0;
    if (!SettingsCache.allowNegativeStock && track && existingQty + 1 > stock) {
      if (mounted) AppToast.showError(context, 'الكمية المطلوبة تتجاوز المخزون المتوفر ($stock)');
      return;
    }

    List<InvoiceItem> updated;
    if (existingIdx >= 0) {
      updated = List.from(widget.invoice.items);
      final old = updated[existingIdx];
      updated[existingIdx] = old.copyWith(quantity: old.quantity + 1, baseQuantity: null);
      // fix baseQuantity after copy (quantity changed, need recalc)
      final newItem = updated[existingIdx];
      updated[existingIdx] = newItem.copyWith(baseQuantity: newItem.quantity * newItem.packaging * newItem.conversionRate);
    } else {
      final newItem = InvoiceItem(
        id: product.id.toString(),
        name: product.name,
        barcode: selected?.barcode ?? product.barcodeNo ?? '',
        price: price,
        costPrice: product.costAmount,
        unit: selected?.unitName ?? selected?.unitShort ?? 'حبة',
        unitId: selected?.unitId ?? product.unitId,
        subUnitId: selected?.subUnitId,
        groupId: product.groupId,
        conversionRate: selected?.conversionRate ?? 1.0,
        packaging: selected?.packaging ?? 1,
        stock: stock,
        quantity: 1,
        trackInventory: product.trackInventory,
      );
      updated = [...widget.invoice.items, newItem];
    }
    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updated));
  }

  void _updateQty(int index, int delta) {
    final updated = List<InvoiceItem>.from(widget.invoice.items);
    final item = updated[index];
    final newQty = (item.quantity + delta).clamp(1, 999);
    if (delta > 0 && !SettingsCache.allowNegativeStock && item.trackInventory && newQty > item.stock) {
      AppToast.showError(context, 'الكمية تتجاوز المخزون (${item.stock})');
      return;
    }
    updated[index] = item.copyWith(quantity: newQty, baseQuantity: newQty * item.packaging * item.conversionRate);
    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updated));
  }

  void _removeItem(int index) {
    final updated = List<InvoiceItem>.from(widget.invoice.items);
    updated.removeAt(index);
    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updated));
  }

  Future<ProductUnitOption?> _showUnitPicker(BuildContext context, dynamic product, List<ProductUnitOption> units, double basePrice) async {
    return Navigator.of(context).push<ProductUnitOption>(
      MaterialPageRoute(
        builder: (_) => UnitPickerPage(
          productName: product.name,
          units: units,
          basePrice: basePrice,
          currencySymbol: 'ر.س',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is ProductsInitial) {
          context.read<ProductsCubit>().loadProducts();
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProductsLoading) return const Center(child: CircularProgressIndicator());
        if (state is ProductsError) return Center(child: Text('خطأ: ${state.message}'));
        if (state is ProductsLoaded) {
          final allProducts = state.products.where((p) => p.isActive).toList();
          final filtered = _query.isEmpty
              ? allProducts
              : allProducts.where((p) => p.name.contains(_query) || p.barcodeNo.contains(_query)).toList();
          return Column(
            children: [
              // Search
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: TextInputField(
                      controller: _searchCtrl,
                      hint: 'ابحث بالاسم أو الباركود…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20), onPressed: () {}),
                  ),
                ]),
              ),
              // Products
              SizedBox(
                height: 200,
                child: filtered.isEmpty
                    ? const EmptyStateWidget(icon: Icons.inventory_2_outlined, title: 'لا توجد أصناف مطابقة', subtitle: 'جرب كلمات أخرى')
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final isAdded = widget.invoice.items.any((e) => e.id == p.id.toString());
                          return CustomCardContainer(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).dividerColor)),
                            child: ListTile(
                              dense: true,
                              title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: FutureBuilder<List<ProductUnitOption>>(
                                future: getIt<UnitConversionService>().getUnitsForProduct(p.id!),
                                builder: (context, snap) {
                                  final base = (p.sellAmount ?? 0).toDouble();
                                  if (!snap.hasData || snap.data!.isEmpty) return Text('السعر: ${NumberFormatter.formatNumber(base)} • المتاح: ${p.quantity.toInt()}', style: const TextStyle(fontSize: 11));
                                  final units = snap.data!;
                                  final info = units.length == 1
                                      ? 'السعر: ${NumberFormatter.formatNumber(base)}'
                                      : units.map((u) => '${u.unitName}:${NumberFormatter.formatNumber(getIt<UnitConversionService>().resolveUnitPrice(baseSellPrice: base, unit: u))}').join(' • ');
                                  return Text('$info • المتاح: ${p.quantity.toInt()}', style: const TextStyle(fontSize: 11));
                                },
                              ),
                              trailing: isAdded
                                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                                  : IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () => _handleAddProduct(p)),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              // Cart
              Expanded(
                child: widget.invoice.items.isEmpty
                    ? const EmptyStateWidget(icon: Icons.shopping_cart_outlined, title: 'السلة فارغة', subtitle: 'أضف أصنافاً من الأعلى')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ...List.generate(widget.invoice.items.length, (idx) {
                              final item = widget.invoice.items[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('${NumberFormatter.formatNumber(item.price)} × ${item.quantity} ${item.unit} = ${NumberFormatter.formatNumber(item.total)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                        if (item.packaging * item.conversionRate > 1)
                                          Text('الأساس: ${item.baseQuantity?.toStringAsFixed(item.baseQuantity! % 1 == 0 ? 0 : 2)} حبة', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                      ]),
                                    ),
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.error), onPressed: () => _updateQty(idx, -1)),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.success), onPressed: () => _updateQty(idx, 1)),
                                    ]),
                                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _removeItem(idx)),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            // Totals + Discount
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('المجموع الفرعي'), Text(NumberFormatter.formatCurrency(widget.invoice.subtotal))]),
                                  if (SettingsCache.taxEnabled) ...[
                                    const SizedBox(height: 6),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(SettingsCache.taxName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), Text(NumberFormatter.formatCurrency(widget.invoice.taxAmount), style: const TextStyle(fontSize: 12))]),
                                  ],
                                  const Divider(height: 16),
                                  Row(children: [
                                    Expanded(
                                      child: CustomDropdownField<DiscountType>(
                                        value: widget.invoice.discount.type,
                                        label: 'نوع الخصم',
                                        items: const [DropdownMenuItem(value: DiscountType.amount, child: Text('مبلغ')), DropdownMenuItem(value: DiscountType.percent, child: Text('نسبة %'))],
                                        onChanged: (v) {
                                          if (v != null) widget.onInvoiceUpdate(widget.invoice.copyWith(discount: widget.invoice.discount.copyWith(type: v)));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextInputField(
                                        controller: _discountCtrl,
                                        hint: 'قيمة الخصم',
                                        keyboardType: TextInputType.number,
                                        prefixIcon: const Icon(Icons.discount_outlined, size: 16),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  TextInputField(
                                    hint: 'رسوم أخرى',
                                    initialValue: widget.invoice.otherCharges.toStringAsFixed(widget.invoice.otherCharges % 1 == 0 ? 0 : 2),
                                    keyboardType: TextInputType.number,
                                    prefixIcon: const Icon(Icons.receipt_long_outlined, size: 16),
                                    onChanged: (v) => widget.onInvoiceUpdate(widget.invoice.copyWith(otherCharges: double.tryParse(v) ?? 0)),
                                  ),
                                  const Divider(height: 16),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)), Text(NumberFormatter.formatCurrency(widget.invoice.total), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
