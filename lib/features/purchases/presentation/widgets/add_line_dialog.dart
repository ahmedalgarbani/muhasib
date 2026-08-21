import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
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

  int? _selectedCategoryId;
  int? _selectedGroupId;
  int? _selectedUnitId;
  bool _initializedFromLine = false;

  double _total = 0.0;

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
    }
  }

  void _onProductSelected(ProductEntity product) {
    setState(() {
      _selectedCategoryId = product.id;
      _selectedGroupId = product.groupId ?? 1;
      _selectedUnitId = product.unitId ?? 1;

      final cost = product.costAmount ?? product.sellAmount ?? 0.0;
      if (_priceController.text.isEmpty || _priceController.text == '0') {
        _priceController.text = cost.toStringAsFixed(2);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;

    setState(() {
      _total = (quantity * price) - discount;
    });
  }

  void _save(List<ProductEntity> products) {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null && products.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار الصنف')),
        );
        return;
      }

      final unitPrice = double.parse(_priceController.text);
      final quantity = double.parse(_quantityController.text);
      final discountAmount = double.tryParse(_discountController.text) ?? 0;
      final amount = quantity * unitPrice;

      final line = InvoiceLineEntity(
        id: widget.line?.id,
        invoiceId: widget.line?.invoiceId ?? 0,
        invoiceType: 2, // Purchase invoice
        categoryId: _selectedCategoryId,
        groupId: _selectedGroupId ?? 1,
        unitId: _selectedUnitId ?? 1,
        categorySubUnitId: widget.line?.categorySubUnitId ?? 1,
        stockId: widget.stockId ?? widget.line?.stockId ?? 1,
        customerId: widget.supplierId ?? widget.line?.customerId ?? 1,
        amount: amount,
        totalAmount: amount - discountAmount,
        discountAmt: discountAmount,
        taxAmt: 0,
        netRevenueAmt: amount - discountAmount,
        quantity: quantity,
        price: unitPrice,
        costPrice: unitPrice,
        costTotal: amount - discountAmount,
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        invoiceTransType: 1,
      );

      widget.onAdd(line);
      Navigator.of(context).pop();
    }
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
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon:
                                  const Icon(Icons.inventory_2_outlined),
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
                          const SizedBox(height: 16),
                        ] else if (!isLoading) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(30),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.amber),
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
                                  if (value == null || value.isEmpty) {
                                    return 'الكمية مطلوبة';
                                  }
                                  final q = double.tryParse(value);
                                  if (q == null || q <= 0) {
                                    return 'أدخل كمية صحيحة';
                                  }
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
                                  if (value == null || value.isEmpty) {
                                    return 'السعر مطلوب';
                                  }
                                  final p = double.tryParse(value);
                                  if (p == null || p < 0) {
                                    return 'أدخل سعر صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
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
    super.dispose();
  }
}
