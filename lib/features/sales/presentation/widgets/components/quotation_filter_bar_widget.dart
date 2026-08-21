import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';

class QuotationFilterBarWidget extends StatelessWidget {
  final bool showOnlyOpen;
  final ValueChanged<bool> onFilterChanged;

  const QuotationFilterBarWidget({
    super.key,
    required this.showOnlyOpen,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text(
            'الفلتر:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('مفتوحة فقط'),
            selected: showOnlyOpen,
            onSelected: (value) => onFilterChanged(true),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            selectedColor: AppColors.blue100,
            checkmarkColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('الكل'),
            selected: !showOnlyOpen,
            onSelected: (value) => onFilterChanged(false),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            selectedColor: AppColors.blue100,
            checkmarkColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
