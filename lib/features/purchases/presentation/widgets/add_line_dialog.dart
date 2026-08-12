import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';


class AddLineDialog extends StatefulWidget {
  final InvoiceLineEntity? line;
  final Function(InvoiceLineEntity) onAdd;

  const AddLineDialog({
    Key? key,
    this.line,
    required this.onAdd,
  }) : super(key: key);

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
        taxAmt: 0, // Calculated at invoice level
        netRevenueAmt: amount - discountAmount,
        quantity: quantity,
        groupId: groupId,
        unitId: 1, // Default unit
        categorySubUnitId: 1, // Default sub unit
        stockId: 1, // To be set at persistence layer if needed
        customerId: 1, // To be set at persistence layer if needed
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        invoiceTransType: 1, // Purchase transaction
      );

      widget.onAdd(line);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.line != null ? 'تعديل المنتج' : 'إضافة منتج',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Item code (groupId)
              TextFormField(
                controller: _itemCodeController,
                decoration: InputDecoration(
                  labelText: 'رقم الصنف',
                  labelStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.qr_code_2, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if ((value == null || value.isEmpty) && widget.line == null) {
                    return 'رقم الصنف مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              
              // Quantity and Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'الكمية',
                        labelStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.numbers, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (value) => _calculateTotal(),
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
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'السعر',
                        labelStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.attach_money, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (value) => _calculateTotal(),
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
              
              // Discount
              TextFormField(
                controller: _discountController,
                decoration: InputDecoration(
                  labelText: 'الخصم',
                  labelStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.discount, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (value) => _calculateTotal(),
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 8),
              
              // Total
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
              const SizedBox(height: 20),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        widget.line != null ? 'تحديث' : 'إضافة',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
