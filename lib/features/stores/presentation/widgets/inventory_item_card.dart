import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPositive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
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
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
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
                  child: _buildQuantityColumn(
                    'الكمية المتوقعة',
                    item.quantity,
                    Colors.blue,
                    Icons.inventory_2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isCountMode
                      ? _buildEditableQuantity()
                      : _buildQuantityColumn(
                          'الكمية الفعلية',
                          item.actualQuantity,
                          Colors.orange,
                          Icons.fact_check,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDifferenceColumn(difference, percentageDiff),
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
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildQuantityColumn(String label, double quantity, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
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
          // Unit name is not available on InventoryLineEntity
        ],
      ),
    );
  }

  Widget _buildEditableQuantity() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
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
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0;
                onQuantityChanged?.call(qty);
              },
              controller: TextEditingController(text: item.actualQuantity.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferenceColumn(double difference, double percentageDiff) {
    final isPositive = difference >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
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
