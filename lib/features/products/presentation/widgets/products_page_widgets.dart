import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ProductsHeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final bool isGridView;
  final int? selectedGroupFilter;
  final VoidCallback onToggleViewMode;
  final ValueChanged<int?> onGroupFilterChanged;
  final ValueChanged<String> onSearchChanged;

  const ProductsHeaderWidget({
    super.key,
    required this.searchController,
    required this.isGridView,
    required this.selectedGroupFilter,
    required this.onToggleViewMode,
    required this.onGroupFilterChanged,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إدارة المنتجات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(isGridView ? Icons.list : Icons.grid_view),
                    onPressed: onToggleViewMode,
                  ),
                  BlocBuilder<ProductGroupsCubit, ProductGroupsState>(
                    builder: (context, groupsState) {
                      if (groupsState is ProductGroupsLoaded) {
                        return DropdownButton<int?>(
                          value: selectedGroupFilter,
                          hint: const Text('كل المجموعات'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('كل المجموعات'),
                            ),
                            ...groupsState.groups.map(
                              (group) => DropdownMenuItem(
                                value: group.id,
                                child: Text(group.name),
                              ),
                            ),
                          ],
                          onChanged: onGroupFilterChanged,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextInputField(
            controller: searchController,
            hint: 'ابحث بالاسم أو الباركود...',
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

class ProductsGridWidget extends StatelessWidget {
  final List<ProductEntity> products;
  final ValueChanged<ProductEntity> onProductTap;

  const ProductsGridWidget({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppConstant.defaultPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return CustomCardContainer(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: InkWell(
            onTap: () => onProductTap(product),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.md),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.inventory,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.barcodeNo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${product.sellAmount?.toStringAsFixed(0) ?? '0'} ر.س',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: product.quantity > 0
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: Text(
                                product.quantity.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: product.quantity > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductsListWidget extends StatelessWidget {
  final List<ProductEntity> products;
  final ValueChanged<ProductEntity> onProductTap;
  final ValueChanged<ProductEntity> onProductEdit;
  final ValueChanged<ProductEntity> onProductDelete;

  const ProductsListWidget({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onProductEdit,
    required this.onProductDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppConstant.defaultPadding,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return CustomCardContainer(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            onTap: () => onProductTap(product),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.inventory, color: Colors.grey.shade400),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الباركود: ${product.barcodeNo}'),
                Text(
                  'السعر: ${product.sellAmount?.toStringAsFixed(2) ?? '0'} ر.س',
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.quantity > 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'المخزون: ${product.quantity.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.quantity > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
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
                      onProductEdit(product);
                    } else if (value == 'delete') {
                      onProductDelete(product);
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
