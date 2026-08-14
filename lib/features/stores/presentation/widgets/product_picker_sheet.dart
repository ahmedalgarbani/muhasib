import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';

/// Bottom sheet listing products (search by name/barcode) for stores documents.
class ProductPickerSheet extends StatefulWidget {
  final Function(ProductEntity) onSelected;

  const ProductPickerSheet({super.key, required this.onSelected});

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductsCubit>().state;
    final products = state is ProductsLoaded ? state.products : <ProductEntity>[];

    final filtered = products.where((p) {
      if (_query.isEmpty) return true;
      return p.name.contains(_query) || p.barcodeNo.contains(_query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'اختيار المنتج',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextInputField(
                  hint: 'ابحث عن منتج بالاسم أو الباركود...',
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد منتجات مطابقة'))
                : ListView.builder(
                    padding: AppConstant.defaultPadding,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final product = filtered[i];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'الباركود: ${product.barcodeNo} | الكمية: ${NumberFormatter.formatNumber(product.quantity)}',
                        ),
                        trailing: Text(
                          'التكلفة: ${NumberFormatter.formatNumber(product.costAmount ?? 0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          widget.onSelected(product);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Opens the product picker as a modal bottom sheet.
/// The caller must have ProductsCubit available in the context.
Future<ProductEntity?> showProductPicker(BuildContext context) async {
  final productsCubit = context.read<ProductsCubit>();
  ProductEntity? selected;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlocProvider.value(
      value: productsCubit,
      child: ProductPickerSheet(
        onSelected: (p) => selected = p,
      ),
    ),
  );
  return selected;
}
