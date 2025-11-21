import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

class AddItemBottomSheet extends StatefulWidget {
  final InvoiceItem item;
  final Function(InvoiceItem) onAdd;

  const AddItemBottomSheet({Key? key, required this.item, required this.onAdd})
    : super(key: key);

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('�?�?�?�?�? ���?�?', style: AppTextStyles.title),
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
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                  '�?�?�?�?�?: ${NumberFormatter.formatCurrency(widget.item.price)} | �?�?�?�?�?: ${widget.item.stock} ${widget.item.unit}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('�?�?�?�?�?�?', style: AppTextStyles.body),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildQuantityButton(Icons.remove, () {
                if (_quantity > 1) setState(() => _quantity--);
              }, false),
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
              _buildQuantityButton(
                Icons.add,
                () => setState(() => _quantity++),
                true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '�?�?�?�?�?'),
            onChanged: (value) =>
                setState(() => _price = double.tryParse(value) ?? _price),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('�?�?�?�?�?�?�?�?:', style: AppTextStyles.body),
                Text(
                  NumberFormatter.formatCurrency(_price * _quantity),
                  style: AppTextStyles.title.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: '�?�?�?�?�? �?�?�? �?�?�?�?�?�?�?�?',
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

  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback onPressed,
    bool isPrimary,
  ) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.grey200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.grey900,
          size: 28,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
