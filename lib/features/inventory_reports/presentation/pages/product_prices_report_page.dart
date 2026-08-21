import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/product_price_report_entity.dart';
import 'package:muhasib/features/inventory_reports/presentation/cubit/product_price_report_cubit.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';

class ProductPricesReportPage extends StatefulWidget {
  const ProductPricesReportPage({super.key});

  @override
  State<ProductPricesReportPage> createState() => _ProductPricesReportPageState();
}

class _ProductPricesReportPageState extends State<ProductPricesReportPage> {
  List<int> _selectedIds = [];
  String _selectedLabel = '';
  List<ProductPriceReportEntity> _lastPrices = [];

  @override
  void initState() {
    super.initState();
    // Defer loading to BlocProvider create
  }

  Future<void> _openProductPicker() async {
    final productsCubit = getIt<ProductsCubit>();
    // Ensure products loaded
    if (productsCubit.state is! ProductsLoaded) {
      productsCubit.loadProducts();
    }
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(
        initialSelected: _selectedIds,
        productsCubit: productsCubit,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedIds = result;
        if (result.isEmpty) {
          _selectedLabel = '';
        } else if (result.length == 1) {
          // Find name
          final state = productsCubit.state;
          if (state is ProductsLoaded) {
            final p = state.products.firstWhere((e) => e.id == result.first,
                orElse: () => state.products.first);
            _selectedLabel = p.name;
          } else {
            _selectedLabel = '${result.length} صنف محدد';
          }
        } else {
          _selectedLabel = '${result.length} أصناف محددة';
        }
      });
      if (mounted) {
        context.read<ProductPriceReportCubit>().loadPrices(productIds: _selectedIds.isEmpty ? null : _selectedIds);
      }
    }
  }

  Future<void> _printPrices() async {
    final cubit = context.read<ProductPriceReportCubit>();
    final state = cubit.state;
    List<ProductPriceReportEntity> list;
    if (state is ProductPriceReportLoaded) {
      list = state.prices;
    } else if (_lastPrices.isNotEmpty) {
      list = _lastPrices;
    } else {
      // Load all if empty selection
      list = [];
    }
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للطباعة')));
      return;
    }
    final headers = ['اسم الصنف', 'الباركود', 'الوحدة', 'سعر البيع', 'سعر الجملة', 'أدنى سعر بيع'];
    final data = list
        .map((e) => [
              e.productName,
              e.barcodeNo,
              e.unitName,
              e.retailPrice.toStringAsFixed(2),
              e.wholesalePrice.toStringAsFixed(2),
              e.minPrice.toStringAsFixed(2),
            ])
        .toList();
    await ExportService.printData(
      title: 'اسعار الاصناف الحالية',
      headers: headers,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProductPriceReportCubit>()..loadPrices()),
        BlocProvider(create: (_) => getIt<ProductsCubit>()..loadProducts()),
      ],
      child: Builder(
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.neutral100,
            appBar: const CustomAppBar(title: 'اسعار الاصناف الحالية'),
            body: BlocConsumer<ProductPriceReportCubit, ProductPriceReportState>(
              listener: (context, state) {
                if (state is ProductPriceReportLoaded) _lastPrices = state.prices;
              },
              builder: (context, state) {
                return Padding(
                  padding: AppConstant.defaultPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dropdown field
                      InkWell(
                        onTap: _openProductPicker,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedIds.isEmpty
                                      ? 'اختر الأصناف (الكل افتراضياً)'
                                      : _selectedLabel.isEmpty
                                          ? '${_selectedIds.length} أصناف'
                                          : _selectedLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedIds.isEmpty ? Colors.grey[600] : Colors.black87,
                                    fontWeight: _selectedIds.isEmpty ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اذا لم يتم اختيار اي صنف، يتم طباعة الاسعار لجميع الاصناف.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      // Preview table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('الصنف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                            Expanded(child: Text('الباركود', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10))),
                            Expanded(child: Text('البيع', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10))),
                            Expanded(child: Text('الجملة', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10))),
                            Expanded(child: Text('الأدنى', textAlign: TextAlign.end, style: TextStyle(color: Colors.white, fontSize: 10))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildContent(state),
                      ),
                      const SizedBox(height: 12),
                      HasibButton(
                        label: 'طباعة',
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        onPressed: () => _printPrices(),
                        variant: HasibButtonVariant.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ProductPriceReportState state) {
    if (state is ProductPriceReportLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ProductPriceReportError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 8),
            Text(state.message),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.read<ProductPriceReportCubit>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (state is ProductPriceReportEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.price_check_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد أسعار', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    if (state is ProductPriceReportLoaded) {
      final list = state.prices;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
          itemBuilder: (context, i) {
            final e = list[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(e.unitName, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Expanded(child: Text(e.barcodeNo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                  Expanded(child: Text(e.retailPrice.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(child: Text(e.wholesalePrice.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                  Expanded(child: Text(e.minPrice.toStringAsFixed(2), textAlign: TextAlign.end, style: const TextStyle(fontSize: 11))),
                ],
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<int> initialSelected;
  final ProductsCubit productsCubit;
  const _ProductPickerSheet({required this.initialSelected, required this.productsCubit});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  late Set<int> _selected;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.toSet();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('اختر الاصناف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextInputField(
                controller: _searchCtrl,
                hint: 'بحث سريع للأصناف...',
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _query = '';
                            _searchCtrl.clear();
                          }),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(height: 8),
            // Select all
            BlocBuilder<ProductsCubit, ProductsState>(
              bloc: widget.productsCubit,
              builder: (context, state) {
                if (state is! ProductsLoaded) return const SizedBox.shrink();
                final products = _filteredProducts(state.products);
                final allSelected = products.isNotEmpty && products.every((p) => _selected.contains(p.id));
                return Container(
                  color: Colors.grey[50],
                  child: CheckboxListTile(
                    value: allSelected,
                    title: const Text('تحديد الكل', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_selected.length} محدد'),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selected.addAll(products.map((e) => e.id!));
                        } else {
                          for (var p in products) _selected.remove(p.id);
                        }
                      });
                    },
                  ),
                );
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ProductsCubit, ProductsState>(
                bloc: widget.productsCubit,
                builder: (context, state) {
                  if (state is ProductsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ProductsError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is ProductsLoaded) {
                    final products = _filteredProducts(state.products);
                    if (products.isEmpty) {
                      return const Center(child: Text('لا توجد أصناف مطابقة'));
                    }
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final p = products[i];
                        final isSel = _selected.contains(p.id);
                        return CheckboxListTile(
                          value: isSel,
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('${p.barcodeNo} - ${p.quantity.toInt()} حبة', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selected.add(p.id!);
                              } else {
                                _selected.remove(p.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: HasibButton(
                  label: 'تم',
                  onPressed: () => Navigator.pop(context, _selected.toList()),
                  variant: HasibButtonVariant.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ProductEntity> _filteredProducts(List<ProductEntity> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(q) || p.barcodeNo.toLowerCase().contains(q)).toList();
  }
}
