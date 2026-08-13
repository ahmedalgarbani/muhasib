import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                  subtitle: Text(
                    'السعر: ${product.sellAmount ?? product.sellLocalAmount ?? 0} | المتوفر: ${product.quantity}',
                  ),
                  trailing: isAdded
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            final newItem = InvoiceItem(
                              id: product.id.toString(),
                              name: product.name,
                              barcode: product.barcodeNo ?? '',
                              price:
                                  (product.sellAmount ??
                                          product.sellLocalAmount ??
                                          0)
                                      .toDouble(),
                              costPrice: product.costAmount,
                              unit: 'قطعة',
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
}
