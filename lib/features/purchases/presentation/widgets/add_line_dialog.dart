import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

class AddLineDialog extends StatefulWidget {
  final InvoiceLineEntity? line;
  final Function(InvoiceLineEntity) onAdd;

  const AddLineDialog({
    super.key,
    this.line,
    required this.onAdd,
  });

  @override
  State<AddLineDialog> createState() => _AddLineDialogState();
}

class _AddLineDialogState extends State<AddLineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.line != null) {
      _itemCodeController.text = widget.line!.groupId.toString();
      _quantityController.text = widget.line!.quantity.toString();
      final unitPrice = widget.line!.quantity == 0
          ? 0
          : (widget.line!.amount / widget.line!.quantity);
      _priceController.text = unitPrice.toStringAsFixed(2);
      _discountController.text = (widget.line!.discountAmt ?? 0).toString();
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    
    setState(() {
      _total = (quantity * price) - discount;
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final unitPrice = double.parse(_priceController.text);
      final quantity = double.parse(_quantityController.text);
      final discountAmount = double.tryParse(_discountController.text) ?? 0;
      final amount = quantity * unitPrice;
      final groupId = int.tryParse(_itemCodeController.text) ?? (widget.line?.groupId ?? 1);

      final line = InvoiceLineEntity(
        id: widget.line?.id,
        invoiceId: widget.line?.invoiceId ?? 0,
        invoiceType: 2, // Purchase invoice
        amount: amount,
        totalAmount: amount - discountAmount,
        discountAmt: discountAmount,
        taxAmt: 0,
        netRevenueAmt: amount - discountAmount,
        quantity: quantity,
        groupId: groupId,
        unitId: 1,
        categorySubUnitId: 1,
        stockId: 1,
        customerId: 1,
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        invoiceTransType: 1,
      );

      widget.onAdd(line);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: widget.line != null ? 'تعديل المنتج' : 'إضافة منتج',
      icon: Icons.add_shopping_cart,
      maxWidth: 500,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextInputField(
              label: 'رقم الصنف',
              textEditingController: _itemCodeController,
              inputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              prefixIcon: const Icon(Icons.qr_code_2),
              isRequired: widget.line == null,
              validator: (value) {
                if ((value == null || value.isEmpty) && widget.line == null) {
                  return 'رقم الصنف مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    label: 'الكمية',
                    textEditingController: _quantityController,
                    inputType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    prefixIcon: const Icon(Icons.numbers),
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الكمية مطلوبة';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'أدخل كمية صحيحة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    label: 'السعر',
                    textEditingController: _priceController,
                    inputType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    prefixIcon: const Icon(Icons.attach_money),
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'السعر مطلوب';
                      }
                      if (double.tryParse(value) == null || double.parse(value) < 0) {
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
              label: 'الخصم',
              textEditingController: _discountController,
              inputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              prefixIcon: const Icon(Icons.discount),
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
                    'الإجمالي:',
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
          onPressed: _save,
          variant: HasibButtonVariant.primary,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }
}
