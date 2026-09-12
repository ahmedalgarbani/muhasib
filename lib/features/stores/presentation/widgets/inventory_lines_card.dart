import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';

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
                    key: ValueKey(inventoryLines[index].categoryId ?? index),
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

class InventoryLineItemWidget extends StatefulWidget {
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
  State<InventoryLineItemWidget> createState() => _InventoryLineItemWidgetState();
}

class _InventoryLineItemWidgetState extends State<InventoryLineItemWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  static String _formatQty(double qty) {
    if (qty == 0) return '';
    if (qty % 1 == 0) return qty.toInt().toString();
    return qty.toString();
  }

  static String _formatDisplayQty(double qty) {
    if (qty % 1 == 0) return qty.toInt().toString();
    return qty.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatQty(widget.line.actualQuantity),
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant InventoryLineItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only synchronize text if not focused and the value truly changed externally
    if (!_focusNode.hasFocus &&
        oldWidget.line.actualQuantity != widget.line.actualQuantity) {
      final currentParsed = double.tryParse(_controller.text) ?? 0;
      if (currentParsed != widget.line.actualQuantity) {
        _controller.text = _formatQty(widget.line.actualQuantity);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difference = widget.line.actualQuantity - widget.line.quantity;
    final isPositive = difference >= 0;
    final formattedDiff = difference > 0
        ? '+${_formatDisplayQty(difference)}'
        : _formatDisplayQty(difference);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPositive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        child: Text(
          '${widget.index + 1}',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        widget.line.statement.isNotEmpty
            ? widget.line.statement
            : 'صنف ${widget.index + 1}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'متوقع: ${_formatDisplayQty(widget.line.quantity)} | فعلي: ${_formatDisplayQty(widget.line.actualQuantity)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'الفرق: $formattedDiff',
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: widget.isCountMode
          ? SizedBox(
              width: 100,
              child: TextInputField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  DecimalTextInputFormatter(),
                ],
                textAlign: TextAlign.center,
                hint: '0',
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final qty = double.tryParse(value.trim()) ?? 0.0;
                  widget.onQuantityChanged(qty);
                },
              ),
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: widget.onDelete,
            ),
    );
  }
}
