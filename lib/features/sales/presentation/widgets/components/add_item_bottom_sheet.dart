import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/quantity_button_widget.dart';

class AddItemBottomSheet extends StatefulWidget {
  final InvoiceItem item;
  final Function(InvoiceItem) onAdd;

  const AddItemBottomSheet({
    super.key,
    required this.item,
    required this.onAdd,
  });

  static Future<void> show(
    BuildContext context, {
    required InvoiceItem item,
    required Function(InvoiceItem) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddItemBottomSheet(item: item, onAdd: onAdd),
      ),
    );
  }

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  late int _quantity;
  late double _price;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _price = widget.item.price;
    _priceController.text = _price.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تعديل الصنف',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                  height: 1.4,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'السعر: ${NumberFormatter.formatCurrency(widget.item.price)} | المتوفر: ${widget.item.stock} ${widget.item.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الكمية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.gray900,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              QuantityButtonWidget(
                icon: Icons.remove,
                onPressed: () {
                  if (_quantity > 1) setState(() => _quantity--);
                },
                isPrimary: false,
              ),
              Expanded(
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              QuantityButtonWidget(
                icon: Icons.add,
                onPressed: () => setState(() => _quantity++),
                isPrimary: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextInputField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            label: 'السعر',
            onChanged: (value) =>
                setState(() => _price = double.tryParse(value) ?? _price),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.gray900,
                    height: 1.5,
                  ),
                ),
                Text(
                  NumberFormatter.formatCurrency(_price * _quantity),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                    height: 1.4,
                  ).copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          HasibButton(
            label: 'إضافة الصنف',
            onPressed: () {
              widget.onAdd(
                widget.item.copyWith(quantity: _quantity, price: _price),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
