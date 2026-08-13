import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/pages/product_form_page.dart';
import 'package:muhasib/features/products/presentation/widgets/products_page_widgets.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isGridView = true;
  int? _selectedGroupFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductGroupsCubit>()..loadAllGroups(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductUnitsCubit>()..loadAllUnits(),
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              ProductsHeaderWidget(
                searchController: _searchController,
                isGridView: _isGridView,
                selectedGroupFilter: _selectedGroupFilter,
                onToggleViewMode: () {
                  setState(() => _isGridView = !_isGridView);
                },
                onGroupFilterChanged: (value) {
                  setState(() => _selectedGroupFilter = value);
                  if (value != null) {
                    context.read<ProductsCubit>().loadProductsByGroup(value);
                  } else {
                    context.read<ProductsCubit>().loadProducts();
                  }
                },
                onSearchChanged: (value) {
                  if (value.isNotEmpty) {
                    context.read<ProductsCubit>().searchProducts(value);
                  } else {
                    context.read<ProductsCubit>().loadProducts();
                  }
                },
              ),
              Expanded(
                child: BlocBuilder<ProductsCubit, ProductsState>(
                  builder: (context, state) {
                    if (state is ProductsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProductsError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is ProductsLoaded) {
                      if (state.products.isEmpty) {
                        return const EmptyStateWidget(
                          title: 'لا توجد منتجات',
                          subtitle: 'ابدأ بإضافة منتج جديد',
                          icon: Icons.inventory_2_outlined,
                        );
                      }
                      return _isGridView
                          ? ProductsGridWidget(
                              products: state.products,
                              onProductTap: (product) =>
                                  _showProductDialog(context, product: product),
                            )
                          : ProductsListWidget(
                              products: state.products,
                              onProductTap: (product) =>
                                  _showProductDialog(context, product: product),
                              onProductEdit: (product) =>
                                  _showProductDialog(context, product: product),
                              onProductDelete: (product) =>
                                  _showDeleteConfirmation(context, product),
                            );
                    }
                    return const Center(child: Text('ابدأ بإضافة منتجات'));
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showProductDialog(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('منتج جديد'),
          ),
        ),
      ),
    );
  }

  void _showProductDialog(BuildContext context, {ProductEntity? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ProductsCubit>(),
          child: ProductFormPage(product: product),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductEntity product) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: CustomDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف منتج "${product.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (product.id != null) {
                  context.read<ProductsCubit>().deleteProduct(product.id!);
                }
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}
