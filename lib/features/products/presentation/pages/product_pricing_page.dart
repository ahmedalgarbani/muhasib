import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/main_drawer/main_app_drawer.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';

class ProductPricingPage extends StatefulWidget {
  const ProductPricingPage({Key? key}) : super(key: key);

  @override
  State<ProductPricingPage> createState() => _ProductPricingPageState();
}

class _ProductPricingPageState extends State<ProductPricingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _selectedProductFilter;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductSubUnitsCubit>()..loadAllSubUnits(),
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (innerContext) => Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF9FAFB),
            endDrawer: const MainAppDrawer(),
            appBar: CustomAppBar(
              onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            body: Column(
              children: [
                _buildHeader(innerContext),
                Expanded(
                  child: _buildPricingContent(innerContext),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showPricingDialog(innerContext),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.add),
              label: const Text('سعر جديد'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext innerContext) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تسعير المنتجات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, productsState) {
              if (productsState is ProductsLoaded) {
                return DropdownButton<int?>
(
                  value: _selectedProductFilter,
                  hint: const Text('اختر المنتج'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('كل المنتجات'),
                    ),
                    ...productsState.products.map((product) =>
                        DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedProductFilter = value);
                    if (value != null) {
                      innerContext.read<ProductSubUnitsCubit>().loadSubUnitsByProduct(value);
                    } else {
                      innerContext.read<ProductSubUnitsCubit>().loadAllSubUnits();
                    }
                  },
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingContent(BuildContext innerContext) {
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
            return _buildEmptyState();
          }
          return _buildPricingList(innerContext, state);
        }
        return const Center(
          child: Text('ابدأ بإضافة أسعار للمنتجات'),
        );
      },
    );
  }

  Widget _buildPricingList(BuildContext innerContext, ProductSubUnitsLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.subUnits.length,
      itemBuilder: (context, index) {
        final subUnit = state.subUnits[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            title: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, productsState) {
                String productName = 'منتج ${subUnit.categoryId}';
                if (productsState is ProductsLoaded && subUnit.categoryId != null) {
                  try {
                    final product = productsState.products.firstWhere(
                      (p) => p.id == subUnit.categoryId,
                    );
                    productName = product.name;
                  } catch (e) {
                    // Product not found, keep default name
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
              _buildPriceLevelItem('سعر التجزئة', 1, subUnit.id),
              _buildPriceLevelItem('سعر الجملة', 2, subUnit.id),
              _buildPriceLevelItem('سعر خاص', 3, subUnit.id),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showPricingDialog(innerContext, subUnitId: subUnit.id),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مستوى سعر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceLevelItem(String levelName, int priceLevel, int? subUnitId) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.attach_money,
          color: Colors.green.shade700,
        ),
      ),
      title: Text(levelName),
      subtitle: const Text('غير محدد'),
      trailing: SizedBox(
        width: 120,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '0.00 ر.س',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showPricingDialog(
                context,
                subUnitId: subUnitId,
                priceLevel: priceLevel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.price_change_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد وحدات فرعية للتسعير',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يجب إضافة وحدات فرعية للمنتجات أولاً',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPricingDialog(BuildContext context, {int? subUnitId, int? priceLevel}) {
    final priceController = TextEditingController();
    final minQuantityController = TextEditingController(text: '1');
    int selectedPriceLevel = priceLevel ?? 1;
    final subUnitsCubit = context.read<ProductSubUnitsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider.value(
          value: subUnitsCubit,
          child: StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('إضافة سعر'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subUnitId == null)
                      BlocBuilder<ProductSubUnitsCubit, ProductSubUnitsState>(
                        builder: (context, state) {
                          if (state is ProductSubUnitsLoaded) {
                            return DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'الوحدة الفرعية',
                                border: OutlineInputBorder(),
                              ),
                              items: state.subUnits.map((subUnit) =>
                                  DropdownMenuItem(
                                    value: subUnit.id,
                                    child: Text('وحدة ${subUnit.packaging}'),
                                  )).toList(),
                              onChanged: (value) {
                                // Update subUnitId
                              },
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedPriceLevel,
                      decoration: const InputDecoration(
                        labelText: 'مستوى السعر',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('سعر التجزئة')),
                        DropdownMenuItem(value: 2, child: Text('سعر الجملة')),
                        DropdownMenuItem(value: 3, child: Text('سعر خاص')),
                        DropdownMenuItem(value: 4, child: Text('سعر الموزع')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedPriceLevel = value ?? 1);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'السعر',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        suffixText: 'ر.س',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: minQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الكمية الدنيا',
                        hintText: '1',
                        border: OutlineInputBorder(),
                        helperText: 'الحد الأدنى للكمية لتطبيق هذا السعر',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement price saving logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('سيتم حفظ السعر قريباً'),
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
