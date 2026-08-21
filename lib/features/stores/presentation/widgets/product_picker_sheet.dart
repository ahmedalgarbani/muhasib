import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<ProductsCubit>();
        if (cubit.state is! ProductsLoaded && cubit.state is! ProductsLoading) {
          cubit.loadProducts();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        List<ProductEntity> products = [];
        final isLoading = state is ProductsLoading || state is ProductsInitial;
        final errorMessage = state is ProductsError ? state.message : null;

        if (state is ProductsLoaded) {
          products = state.products;
        }

        final filtered = products.where((p) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return p.name.toLowerCase().contains(q) ||
              p.barcodeNo.toLowerCase().contains(q);
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      'اختيار المنتج',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      hint: 'ابحث عن منتج بالاسم أو الباركود...',
                      onChanged: (v) => setState(() => _query = v.trim()),
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
                child: _buildListBody(
                  context: context,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  filtered: filtered,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListBody({
    required BuildContext context,
    required bool isLoading,
    required String? errorMessage,
    required List<ProductEntity> filtered,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.read<ProductsCubit>().loadProducts(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty
              ? 'لا توجد منتجات مسجلة'
              : 'لا توجد منتجات مطابقة للبحث',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
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
    );
  }
}

/// Opens the product picker as a modal bottom sheet.
/// Can optionally accept an existing [cubit]. If none provided, reads from [context] or falls back to [getIt].
Future<ProductEntity?> showProductPicker(
  BuildContext context, {
  ProductsCubit? cubit,
}) async {
  ProductsCubit productsCubit;
  try {
    productsCubit = cubit ?? context.read<ProductsCubit>();
  } catch (_) {
    productsCubit = getIt<ProductsCubit>();
  }

  if (productsCubit.state is! ProductsLoaded &&
      productsCubit.state is! ProductsLoading) {
    productsCubit.loadProducts();
  }

  ProductEntity? selected;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => BlocProvider.value(
      value: productsCubit,
      child: ProductPickerSheet(
        onSelected: (p) => selected = p,
      ),
    ),
  );
  return selected;
}
