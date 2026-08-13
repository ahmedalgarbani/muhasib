import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/products/presentation/cubit/product_prices_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ProductPricingHeaderWidget extends StatelessWidget {
  final int? selectedProductFilter;
  final ValueChanged<int?> onProductFilterChanged;

  const ProductPricingHeaderWidget({
    super.key,
    required this.selectedProductFilter,
    required this.onProductFilterChanged,
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
            'تسعير المنتجات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, productsState) {
              if (productsState is ProductsLoaded) {
                return DropdownButton<int?>(
                  value: selectedProductFilter,
                  hint: const Text('اختر المنتج'),
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
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
}

class ProductPricingContentWidget extends StatelessWidget {
  final Function(int? subUnitId) onAddPricing;
  final Function(int? subUnitId, int priceLevel, double? existingPrice, double? existingMinQty) onEditPricing;
  final Function(int priceId) onDeletePricing;

  const ProductPricingContentWidget({
    super.key,
    required this.onAddPricing,
    required this.onEditPricing,
    required this.onDeletePricing,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductPricesCubit, ProductPricesState>(
      listener: (context, state) {
        if (state is ProductPricesSaved) {
          AppToast.showSuccess(context, state.message);
        } else if (state is ProductPricesError) {
          AppToast.showError(context, state.message);
        }
      },
      builder: (context, pricesState) {
        return BlocBuilder<ProductSubUnitsCubit, ProductSubUnitsState>(
          builder: (context, state) {
            if (state is ProductSubUnitsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductSubUnitsError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (state is ProductSubUnitsLoaded) {
              if (state.subUnits.isEmpty) {
                return const EmptyStateWidget(
                  title: 'لا توجد وحدات فرعية للتسعير',
                  subtitle: 'يجب إضافة وحدات فرعية للمنتجات أولاً',
                  icon: Icons.price_change_outlined,
                );
              }
              return ProductPricingListWidget(
                subUnitsState: state,
                pricesState: pricesState,
                onAddPricing: onAddPricing,
                onEditPricing: onEditPricing,
                onDeletePricing: onDeletePricing,
              );
            }
            return const Center(child: Text('ابدأ بإضافة أسعار للمنتجات'));
          },
        );
      },
    );
  }
}

class ProductPricingListWidget extends StatelessWidget {
  final ProductSubUnitsLoaded subUnitsState;
  final ProductPricesState pricesState;
  final Function(int? subUnitId) onAddPricing;
  final Function(int? subUnitId, int priceLevel, double? existingPrice, double? existingMinQty) onEditPricing;
  final Function(int priceId) onDeletePricing;

  const ProductPricingListWidget({
    super.key,
    required this.subUnitsState,
    required this.pricesState,
    required this.onAddPricing,
    required this.onEditPricing,
    required this.onDeletePricing,
  });

  @override
  Widget build(BuildContext context) {
    final prices = pricesState is ProductPricesLoaded ? (pricesState as ProductPricesLoaded).prices : [];

    return ListView.builder(
      padding: AppConstant.defaultPadding,
      itemCount: subUnitsState.subUnits.length,
      itemBuilder: (context, index) {
        final subUnit = subUnitsState.subUnits[index];
        final subUnitPrices = prices
            .where((p) => p.categorySubUnitId == subUnit.id)
            .toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ExpansionTile(
            title: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, productsState) {
                String productName = 'منتج ${subUnit.categoryId}';
                if (productsState is ProductsLoaded &&
                    subUnit.categoryId != null) {
                  try {
                    final product = productsState.products.firstWhere(
                      (p) => p.id == subUnit.categoryId,
                    );
                    productName = product.name;
                  } catch (e) {
                    productName = 'منتج غير معروف';
                  }
                }
                return Text(
                  '$productName - ${subUnit.packaging} وحدة',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                );
              },
            ),
            children: [
              ProductPriceLevelItemWidget(
                levelName: 'سعر التجزئة',
                priceLevel: 1,
                subUnitId: subUnit.id,
                prices: subUnitPrices,
                onEditPricing: onEditPricing,
                onDeletePricing: onDeletePricing,
              ),
              ProductPriceLevelItemWidget(
                levelName: 'سعر الجملة',
                priceLevel: 2,
                subUnitId: subUnit.id,
                prices: subUnitPrices,
                onEditPricing: onEditPricing,
                onDeletePricing: onDeletePricing,
              ),
              ProductPriceLevelItemWidget(
                levelName: 'سعر خاص',
                priceLevel: 3,
                subUnitId: subUnit.id,
                prices: subUnitPrices,
                onEditPricing: onEditPricing,
                onDeletePricing: onDeletePricing,
              ),
              ProductPriceLevelItemWidget(
                levelName: 'سعر الموزع',
                priceLevel: 4,
                subUnitId: subUnit.id,
                prices: subUnitPrices,
                onEditPricing: onEditPricing,
                onDeletePricing: onDeletePricing,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: HasibButton(
                  label: 'إضافة مستوى سعر',
                  onPressed: () => onAddPricing(subUnit.id),
                  leading: const Icon(Icons.add),
                  variant: HasibButtonVariant.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductPriceLevelItemWidget extends StatelessWidget {
  final String levelName;
  final int priceLevel;
  final int? subUnitId;
  final List prices;
  final Function(int? subUnitId, int priceLevel, double? existingPrice, double? existingMinQty) onEditPricing;
  final Function(int priceId) onDeletePricing;

  const ProductPriceLevelItemWidget({
    super.key,
    required this.levelName,
    required this.priceLevel,
    required this.subUnitId,
    required this.prices,
    required this.onEditPricing,
    required this.onDeletePricing,
  });

  @override
  Widget build(BuildContext context) {
    final price = prices.where((p) => p.priceLevel == priceLevel).firstOrNull;
    final hasPrice =
        price != null && price.bidAmount != null && price.bidAmount > 0;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasPrice
              ? Colors.green.shade50
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.attach_money,
          color: hasPrice ? Colors.green.shade700 : Colors.grey.shade400,
        ),
      ),
      title: Text(levelName),
      subtitle: Text(
        hasPrice ? 'الحد الأدنى: ${price.minQuantity ?? 1} وحدة' : 'غير محدد',
      ),
      trailing: SizedBox(
        width: 140,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                hasPrice
                    ? '${price.bidAmount?.toStringAsFixed(2)} ر.س'
                    : '0.00 ر.س',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasPrice
                      ? Colors.green.shade700
                      : Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => onEditPricing(
                subUnitId,
                priceLevel,
                hasPrice ? price.bidAmount : null,
                hasPrice ? price.minQuantity : null,
              ),
            ),
            if (hasPrice)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => onDeletePricing(price.id),
              ),
          ],
        ),
      ),
    );
  }
}
