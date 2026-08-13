import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_item_bottom_sheet.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/expandable_section.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/item_card.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class Step2Items extends StatefulWidget {
  final Invoice invoice;
  final List<InvoiceItem> availableItems;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step2Items({
    super.key,
    required this.invoice,
    required this.availableItems,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step2Items> createState() => _Step2ItemsState();
}

class _Step2ItemsState extends State<Step2Items> {
  final _searchController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addItem(InvoiceItem item) {
    final existingIndex = widget.invoice.items.indexWhere(
      (i) => i.id == item.id,
    );
    List<InvoiceItem> updatedItems;

    if (existingIndex >= 0) {
      updatedItems = List.from(widget.invoice.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + item.quantity,
      );
    } else {
      updatedItems = [...widget.invoice.items, item];
    }

    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updatedItems));
    _searchController.clear();
  }

  void _updateItemQuantity(int index, int delta) {
    final updatedItems = List<InvoiceItem>.from(widget.invoice.items);
    updatedItems[index] = updatedItems[index].copyWith(
      quantity: (updatedItems[index].quantity + delta).clamp(1, 999),
    );
    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updatedItems));
  }

  void _removeItem(int index) {
    final updatedItems = List<InvoiceItem>.from(widget.invoice.items);
    updatedItems.removeAt(index);
    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updatedItems));
  }

  void _simulateScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 1), () {
      final randomItem =
          widget.availableItems[DateTime.now().millisecond %
              widget.availableItems.length];
      _addItem(randomItem);
      setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.availableItems
        .where(
          (item) =>
              item.name.contains(_searchController.text) ||
              item.barcode.contains(_searchController.text),
        )
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextInputField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صنف أو امسح البار كود...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isScanning ? AppColors.warning : AppColors.success,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconButton(
                  onPressed: _isScanning ? null : _simulateScan,
                  icon: Icon(
                    _isScanning ? Icons.hourglass_empty : Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_searchController.text.isNotEmpty && filteredItems.isNotEmpty)
          Container(
            color: Colors.white,
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${NumberFormatter.formatCurrency(item.price)} | متوفر: ${item.stock}',
                  ),
                  onTap: () {
                    AddItemBottomSheet.show(
                      context,
                      item: item,
                      onAdd: _addItem,
                    );
                  },
                );
              },
            ),
          ),
        Expanded(
          child: widget.invoice.items.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'لم تتم إضافة أصناف بعد',
                  subtitle: 'ابحث أو امسح باركود لإضافة صنف',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      ...List.generate(widget.invoice.items.length, (index) {
                        final item = widget.invoice.items[index];
                        return ItemCard(
                          item: item,
                          onIncrement: () => _updateItemQuantity(index, 1),
                          onDecrement: () => _updateItemQuantity(index, -1),
                          onDelete: () => _removeItem(index),
                        );
                      }),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'المجموع الفرعي:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray900,
                                    height: 1.4,
                                  ),
                                ),
                                Text(
                                  NumberFormatter.formatCurrency(
                                    widget.invoice.subtotal,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray900,
                                    height: 1.4,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ExpandableSection(
                              title: 'خصومات ورسوم',
                              child: Column(
                                children: [
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            DropdownButtonFormField<
                                              DiscountType
                                            >(
                                              initialValue:
                                                  widget.invoice.discount.type,
                                              items: const [
                                                DropdownMenuItem(
                                                  value: DiscountType.amount,
                                                  child: Text('مبلغ'),
                                                ),
                                                DropdownMenuItem(
                                                  value: DiscountType.percent,
                                                  child: Text('نسبة %'),
                                                ),
                                              ],
                                              onChanged: (type) {
                                                if (type != null) {
                                                  widget.onInvoiceUpdate(
                                                    widget.invoice.copyWith(
                                                      discount: widget
                                                          .invoice
                                                          .discount
                                                          .copyWith(type: type),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        flex: 2,
                                        child: TextInputField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'الخصم',
                                          ),
                                          onChanged: (value) {
                                            widget.onInvoiceUpdate(
                                              widget.invoice.copyWith(
                                                discount: widget
                                                    .invoice
                                                    .discount
                                                    .copyWith(
                                                      value:
                                                          double.tryParse(
                                                            value,
                                                          ) ??
                                                          0,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextInputField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'رسوم أخرى',
                                    ),
                                    onChanged: (value) {
                                      widget.onInvoiceUpdate(
                                        widget.invoice.copyWith(
                                          otherCharges:
                                              double.tryParse(value) ?? 0,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (widget.invoice.discountAmount > 0 ||
                                widget.invoice.otherCharges > 0) ...[
                              const Divider(height: AppSpacing.lg),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'الإجمالي النهائي:',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray900,
                                      height: 1.3,
                                    ),
                                  ),
                                  Text(
                                    NumberFormatter.formatCurrency(
                                      widget.invoice.total,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray900,
                                      height: 1.3,
                                    ).copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: HasibButton(
                  label: 'رجوع',
                  onPressed: widget.onPrevious,
                  variant: HasibButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: HasibButton(
                  label: 'التالي: الدفع',
                  onPressed: widget.invoice.items.isNotEmpty
                      ? widget.onNext
                      : null,
                  variant: HasibButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
