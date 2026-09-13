import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/item_movement_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/item_movements_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ItemMovementsHeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final int? selectedProductFilter;
  final int? selectedTypeFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSelectDateRange;
  final ValueChanged<int?> onProductFilterChanged;
  final ValueChanged<int?> onTypeFilterChanged;

  const ItemMovementsHeaderWidget({
    super.key,
    required this.searchController,
    required this.selectedProductFilter,
    required this.selectedTypeFilter,
    required this.onSearchChanged,
    required this.onSelectDateRange,
    required this.onProductFilterChanged,
    required this.onTypeFilterChanged,
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
            'حركات المخزون',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  controller: searchController,
                  hint: 'ابحث في الحركات...',
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
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: onSelectDateRange,
                tooltip: 'تصفية بالتاريخ',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, productsState) {
                  if (productsState is ProductsLoaded) {
                    return Expanded(
                      child: DropdownButton<int?>(
                        value: selectedProductFilter,
                        hint: const Text('كل المنتجات'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('كل المنتجات'),
                          ),
                          ...productsState.products.map(
                            (product) => DropdownMenuItem(
                              value: product.id,
                              child: Text(product.name),
                            ),
                          ),
                        ],
                        onChanged: onProductFilterChanged,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int?>(
                  value: selectedTypeFilter,
                  hint: const Text('نوع الحركة'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('كل الحركات')),
                    DropdownMenuItem(value: 1, child: Text('فاتورة مبيعات')),
                    DropdownMenuItem(value: 2, child: Text('فاتورة مشتريات')),
                    DropdownMenuItem(value: 3, child: Text('عرض سعر')),
                    DropdownMenuItem(value: 4, child: Text('مرتجع مبيعات')),
                    DropdownMenuItem(value: 5, child: Text('مرتجع مشتريات')),
                    DropdownMenuItem(value: 6, child: Text('تحويل مخزني')),
                    DropdownMenuItem(value: 7, child: Text('جرد مخزني')),
                  ],
                  onChanged: onTypeFilterChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ItemMovementsListWidget extends StatelessWidget {
  final List<ItemMovementEntity> movements;

  const ItemMovementsListWidget({
    super.key,
    required this.movements,
  });

  @override
  Widget build(BuildContext context) {
    double runningBalance = 0;
    final movementsWithBalance = movements.map((movement) {
      runningBalance += movement.netQuantity;
      return {'movement': movement, 'balance': runningBalance};
    }).toList();

    return ListView.builder(
      padding: AppConstant.defaultPadding,
      itemCount: movementsWithBalance.length,
      itemBuilder: (context, index) {
        final item = movementsWithBalance[index];
        final movement = item['movement'] as ItemMovementEntity;
        final balance = item['balance'] as double;
        final date = DateTime.fromMillisecondsSinceEpoch(
          movement.transDate * 1000,
        );

        return CustomCardContainer(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: movement.transInOut
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              movement.transInOut
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: movement.transInOut
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movement.movementTypeString,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'رقم المستند: ${movement.docNo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDate(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(movement.statement, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ItemMovementQuantityChipWidget(
                          label: 'دخول',
                          quantity: movement.quantityIn,
                          color: Colors.green,
                        ),
                        ItemMovementQuantityChipWidget(
                          label: 'خروج',
                          quantity: movement.quantityOut,
                          color: Colors.red,
                        ),
                        ItemMovementQuantityChipWidget(
                          label: 'الصافي',
                          quantity: movement.netQuantity,
                          color: movement.netQuantity >= 0
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('الرصيد:', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            balance.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (movement.sellAmount != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Text(
                        'السعر: ${movement.sellAmount?.toStringAsFixed(2) ?? '0'} ${movement.currencyCode ?? 'ر.س'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (movement.costAmount != null) ...[
                        Text(
                          'التكلفة: ${movement.costAmount?.toStringAsFixed(2)} ${movement.currencyCode ?? 'ر.س'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ItemMovementQuantityChipWidget extends StatelessWidget {
  final String label;
  final double quantity;
  final Color color;

  const ItemMovementQuantityChipWidget({
    super.key,
    required this.label,
    required this.quantity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          Text(
            quantity.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
