import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ProductGroupsHeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const ProductGroupsHeaderWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مجموعات المنتجات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          TextInputField(
            controller: searchController,
            hint: 'ابحث في المجموعات...',
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}

class ProductGroupsListWidget extends StatelessWidget {
  final List<ProductGroupEntity> groups;
  final ValueChanged<ProductGroupEntity> onEditGroup;
  final ValueChanged<ProductGroupEntity> onDeleteGroup;

  const ProductGroupsListWidget({
    super.key,
    required this.groups,
    required this.onEditGroup,
    required this.onDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppConstant.defaultPadding,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return CustomCardContainer(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.category, color: AppColors.primary),
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: group.statement != null
                ? Text(
                    group.statement!,
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group.parentGroupId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const Text(
                      'فرعية',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('تعديل'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditGroup(group);
                    } else if (value == 'delete') {
                      onDeleteGroup(group);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
