import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

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
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextInputField(
              controller: searchController,
              hint: 'ابحث برقم المرتجع أو الفاتورة الأصلية...',
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
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
              backgroundColor: Colors.grey.shade100,
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
