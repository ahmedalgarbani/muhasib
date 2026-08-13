import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class InventoryTypeSelector extends StatelessWidget {
  final String selectedType;
  final List<Map<String, dynamic>> inventoryTypes;
  final ValueChanged<String> onTypeSelected;

  const InventoryTypeSelector({
    super.key,
    required this.selectedType,
    required this.inventoryTypes,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: inventoryTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = inventoryTypes[index];
          final isSelected = selectedType == type['value'];
          return GestureDetector(
            onTap: () => onTypeSelected(type['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              decoration: BoxDecoration(
                color: isSelected
                    ? (type['color'] as Color).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected
                      ? type['color'] as Color
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: isSelected
                        ? type['color'] as Color
                        : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? type['color'] as Color
                          : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
