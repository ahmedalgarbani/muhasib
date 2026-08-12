import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryLineEntity item;
  final int index;
  final bool isCountMode;
  final ValueChanged<double>? onQuantityChanged;
  final VoidCallback? onDelete;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.index,
    this.isCountMode = false,
    this.onQuantityChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final difference = item.actualQuantity - item.quantity;
    final isPositive = difference >= 0;
    final percentageDiff = item.quantity > 0
        ? (difference / item.quantity * 100).abs()
        : 0.0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isPositive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صنف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCountMode && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Quantities
            Row(
              children: [
                Expanded(
                  child: QuantityColumnWidget(
                    label: 'الكمية المتوقعة',
                    quantity: item.quantity,
                    color: Colors.blue,
                    icon: Icons.inventory_2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isCountMode
                      ? EditableQuantityWidget(
                          actualQuantity: item.actualQuantity,
                          onQuantityChanged: onQuantityChanged,
                        )
                      : QuantityColumnWidget(
                          label: 'الكمية الفعلية',
                          quantity: item.actualQuantity,
                          color: Colors.orange,
                          icon: Icons.fact_check,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DifferenceColumnWidget(
                    difference: difference,
                    percentageDiff: percentageDiff,
                  ),
                ),
              ],
            ),

            // Cost Information
            if ((item.costAmount ?? 0) > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'التكلفة الإجمالية',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(((item.costAmount ?? 0) * item.actualQuantity).toStringAsFixed(2))} ر.س',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            // Statement
            if (item.statement.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.statement,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QuantityColumnWidget extends StatelessWidget {
  final String label;
  final double quantity;
  final Color color;
  final IconData icon;

  const QuantityColumnWidget({
    super.key,
    required this.label,
    required this.quantity,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            quantity.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class EditableQuantityWidget extends StatefulWidget {
  final double actualQuantity;
  final ValueChanged<double>? onQuantityChanged;

  const EditableQuantityWidget({
    super.key,
    required this.actualQuantity,
    this.onQuantityChanged,
  });

  @override
  State<EditableQuantityWidget> createState() => _EditableQuantityWidgetState();
}

class _EditableQuantityWidgetState extends State<EditableQuantityWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.actualQuantity.toString());
  }

  @override
  void didUpdateWidget(covariant EditableQuantityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actualQuantity != widget.actualQuantity) {
      _controller.text = widget.actualQuantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.edit, size: 20, color: Colors.orange),
          const SizedBox(height: 4),
          const Text(
            'الكمية الفعلية',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0;
                widget.onQuantityChanged?.call(qty);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DifferenceColumnWidget extends StatelessWidget {
  final double difference;
  final double percentageDiff;

  const DifferenceColumnWidget({
    super.key,
    required this.difference,
    required this.percentageDiff,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = difference >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 4),
          const Text(
            'الفرق',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${isPositive ? '+' : ''}${difference.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${percentageDiff.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
