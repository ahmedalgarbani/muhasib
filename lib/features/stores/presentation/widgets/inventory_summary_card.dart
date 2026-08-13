import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class InventorySummaryCard extends StatelessWidget {
  final List<InventoryLineEntity> inventoryLines;

  const InventorySummaryCard({
    super.key,
    required this.inventoryLines,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final totalExpected = inventoryLines.fold<double>(
      0,
      (sum, line) => sum + line.quantity,
    );
    final totalActual = inventoryLines.fold<double>(
      0,
      (sum, line) => sum + line.actualQuantity,
    );
    final totalDifference = totalActual - totalExpected;

    return CustomCardContainer(
      elevation: 2,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InventorySummaryItemWidget(
                  label: 'المتوقع',
                  value: totalExpected.toString(),
                  color: Colors.blue,
                ),
                InventorySummaryItemWidget(
                  label: 'الفعلي',
                  value: totalActual.toString(),
                  color: Colors.green,
                ),
                InventorySummaryItemWidget(
                  label: 'الفرق',
                  value: '${totalDifference > 0 ? '+' : ''}$totalDifference',
                  color: totalDifference >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InventorySummaryItemWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const InventorySummaryItemWidget({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
