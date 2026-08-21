import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/precision_helper.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ImprovedStep2Products extends StatelessWidget {
  final Invoice invoice;
  final ValueChanged<Invoice> onInvoiceUpdate;

  const ImprovedStep2Products({
    super.key,
    required this.invoice,
    required this.onInvoiceUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is ProductsInitial) {
          context.read<ProductsCubit>().loadProducts();
          return const Center(child: CircularProgressIndicator());
        } else if (state is ProductsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ProductsError) {
          return Center(child: Text('خطأ في تحميل المنتجات: ${state.message}'));
        } else if (state is ProductsLoaded) {
          final products = state.products.where((p) => p.isActive).toList();
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد منتجات متاحة',
                style: TextStyle(fontSize: 16, color: AppColors.gray500),
              ),
            );
          }
          return ListView.separated(
            padding: AppConstant.defaultPadding,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              final isAdded = invoice.items.any(
                (item) => item.id == product.id.toString(),
              );
              return CustomCardContainer(
                elevation: 1,
                child: ListTile(
                  title: Text(product.name),
                  subtitle: FutureBuilder<List<ProductUnitOption>>(
                    future: getIt<UnitConversionService>().getUnitsForProduct(product.id!),
                    builder: (context, snapshot) {
                      final basePrice = (product.sellAmount ?? product.sellLocalAmount ?? 0).toDouble();
                      final availQty = PrecisionHelper.roundQuantity(product.quantity);
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('السعر: $basePrice | المتوفر: $availQty حبة');
                      }
                      final units = snapshot.data!;
                      if (units.length == 1) {
                        return Text('السعر: $basePrice | المتوفر: $availQty ${units.first.unitName}');
                      }
                      // Multi-unit info: show prices for available packages
                      final priceInfo = units.map((u) {
                        final p = getIt<UnitConversionService>().resolveUnitPrice(baseSellPrice: basePrice, unit: u);
                        return '${u.unitName}:${p.toStringAsFixed(2)}';
                      }).join(' | ');
                      return Text('المتوفر: $availQty حبة | أسعار: $priceInfo', style: TextStyle(fontSize: 11));
                    },
                  ),
                  trailing: isAdded
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primary,
                          ),
                          onPressed: () async {
                            // Multi-unit unit picker
                            final svc = getIt<UnitConversionService>();
                            final units = await svc.getUnitsForProduct(product.id!);
                            ProductUnitOption? selected = units.isNotEmpty ? await svc.getDefaultSaleUnit(product.id!) ?? units.first : null;
                            double price = (product.sellAmount ?? product.sellLocalAmount ?? 0).toDouble();
                            if (selected != null) {
                              price = svc.resolveUnitPrice(baseSellPrice: price, unit: selected);
                            }
                            // If multiple units, show picker bottom sheet
                            if (units.length > 1 && context.mounted) {
                              selected = await _showUnitPicker(context, product, units, price);
                              if (selected == null) return;
                              price = svc.resolveUnitPrice(baseSellPrice: (product.sellAmount ?? 0).toDouble(), unit: selected);
                            }
                            if (!context.mounted) return;
                            final newItem = InvoiceItem(
                              id: product.id.toString(),
                              name: product.name,
                              barcode: selected?.barcode ?? product.barcodeNo ?? '',
                              price: price,
                              costPrice: product.costAmount,
                              unit: selected?.unitName ?? selected?.unitShort ?? 'قطعة',
                              unitId: selected?.unitId ?? product.unitId,
                              subUnitId: selected?.subUnitId,
                              groupId: product.groupId,
                              conversionRate: selected?.conversionRate ?? 1.0,
                              packaging: selected?.packaging ?? 1,
                              stock: product.quantity.toInt(),
                              quantity: 1,
                            );
                            onInvoiceUpdate(
                              invoice.copyWith(
                                items: [...invoice.items, newItem],
                              ),
                            );
                          },
                        ),
                ),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Future<ProductUnitOption?> _showUnitPicker(BuildContext context, dynamic product, List<ProductUnitOption> units, double basePrice) async {
    final svc = getIt<UnitConversionService>();
    return showModalBottomSheet<ProductUnitOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر الوحدة لـ ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...units.map((u) {
                final price = svc.resolveUnitPrice(baseSellPrice: basePrice, unit: u);
                final factor = u.totalConversion;
                return ListTile(
                  title: Text('${u.unitName} ${u.isMainUnit ? "(أساسية)" : "($factor حبة)"}'),
                  subtitle: Text('السعر: ${price.toStringAsFixed(2)} ${u.hasBarcode ? "| باركود: ${u.barcode}" : ""}'),
                  trailing: u.isDefaultSale ? const Icon(Icons.star, color: Colors.amber, size: 16) : null,
                  onTap: () => Navigator.pop(ctx, u),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
