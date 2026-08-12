import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/settings_entities/domain/entities/other_fee_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/other_fee_card_widget.dart';

/// Standalone Other Fees List Widget with search and fee cards list.
class OtherFeesListWidget extends StatelessWidget {
  final List<OtherFeeEntity> otherFees;
  final List<String> toolTypes;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(OtherFeeEntity) onOtherFeeTap;
  final Function(OtherFeeEntity) onOtherFeeEdit;
  final Function(OtherFeeEntity) onOtherFeeDelete;

  const OtherFeesListWidget({
    super.key,
    required this.otherFees,
    required this.toolTypes,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOtherFeeTap,
    required this.onOtherFeeEdit,
    required this.onOtherFeeDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'بحث في الأدوات...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: otherFees.length,
            itemBuilder: (context, index) {
              final fee = otherFees[index];
              return OtherFeeCardWidget(
                otherFee: fee,
                toolTypes: toolTypes,
                onTap: () => onOtherFeeTap(fee),
                onEdit: () => onOtherFeeEdit(fee),
                onDelete: () => onOtherFeeDelete(fee),
              );
            },
          ),
        ),
      ],
    );
  }
}
