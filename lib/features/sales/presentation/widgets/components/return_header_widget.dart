import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ReturnHeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onChanged;
  final VoidCallback onRefresh;

  const ReturnHeaderWidget({
    super.key,
    required this.searchController,
    this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: AppConstant.defaultPadding,
      child: Row(
        children: [
          Expanded(
            child: TextInputField(
              controller: searchController,
              hint: 'ابحث برقم المرتجع أو الفاتورة الأصلية...',
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
