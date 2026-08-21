import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class InventoryLinesCard extends StatelessWidget {
  final List<InventoryLineEntity> inventoryLines;
  final bool isCountMode;
  final Function(int index, double actualQuantity) onQuantityChanged;
  final Function(int index) onDeleteLine;

  const InventoryLinesCard({
    super.key,
    required this.inventoryLines,
    required this.isCountMode,
    required this.onQuantityChanged,
    required this.onDeleteLine,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomCardContainer(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'قائمة الجرد',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (inventoryLines.isNotEmpty)
                  Text(
                    '${inventoryLines.length} صنف',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (inventoryLines.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد أصناف للجرد',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (!isCountMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'انتقل لوضع الجرد لبدء العد',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inventoryLines.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return InventoryLineItemWidget(
                    index: index,
                    line: inventoryLines[index],
                    isCountMode: isCountMode,
                    onQuantityChanged: (qty) => onQuantityChanged(index, qty),
                    onDelete: () => onDeleteLine(index),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class InventoryLineItemWidget extends StatelessWidget {
  final int index;
  final InventoryLineEntity line;
  final bool isCountMode;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onDelete;

  const InventoryLineItemWidget({
    super.key,
    required this.index,
    required this.line,
    required this.isCountMode,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final difference = line.actualQuantity - line.quantity;
    final isPositive = difference >= 0;

    return ListTile(
      leading: CircleAvatar(
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
      title: Text(
        line.statement.isNotEmpty ? line.statement : 'صنف ${index + 1}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'متوقع: ${line.quantity} | فعلي: ${line.actualQuantity}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'الفرق: ${difference > 0 ? '+' : ''}$difference',
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: isCountMode
          ? SizedBox(
              width: 100,
              child: TextInputField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                hint: '0',
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final qty = double.tryParse(value) ?? 0;
                  onQuantityChanged(qty);
                },
                controller: TextEditingController(
                  text: line.actualQuantity.toString(),
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
    );
  }
}
