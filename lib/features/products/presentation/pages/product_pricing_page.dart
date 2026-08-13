import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/presentation/cubit/product_prices_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/widgets/product_pricing_widgets.dart';

class ProductPricingPage extends StatefulWidget {
  const ProductPricingPage({super.key});

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
        BlocProvider(
          create: (context) => getIt<ProductPricesCubit>()..loadAllPrices(),
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (innerContext) => Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.gray50,
            appBar: const CustomAppBar(),
            body: Column(
              children: [
                ProductPricingHeaderWidget(
                  selectedProductFilter: _selectedProductFilter,
                  onProductFilterChanged: (value) {
                    setState(() => _selectedProductFilter = value);
                    if (value != null) {
                      innerContext
                          .read<ProductSubUnitsCubit>()
                          .loadSubUnitsByProduct(value);
                    } else {
                      innerContext
                          .read<ProductSubUnitsCubit>()
                          .loadAllSubUnits();
                    }
                  },
                ),
                Expanded(
                  child: ProductPricingContentWidget(
                    onAddPricing: (subUnitId) => _showPricingDialog(
                      innerContext,
                      subUnitId: subUnitId,
                    ),
                    onEditPricing: (subUnitId, priceLevel, existingPrice, existingMinQty) =>
                        _showPricingDialog(
                      innerContext,
                      subUnitId: subUnitId,
                      priceLevel: priceLevel,
                      existingPrice: existingPrice,
                      existingMinQty: existingMinQty,
                    ),
                    onDeletePricing: (priceId) =>
                        _confirmDeletePrice(innerContext, priceId),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showPricingDialog(innerContext),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('سعر جديد'),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeletePrice(BuildContext context, int priceId) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: CustomDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا السعر؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            HasibButton(
              label: 'حذف',
              onPressed: () {
                context.read<ProductPricesCubit>().deletePrice(priceId);
                Navigator.pop(dialogContext);
              },
              variant: HasibButtonVariant.danger,
            ),
          ],
        ),
      ),
    );
  }

  void _showPricingDialog(
    BuildContext context, {
    int? subUnitId,
    int? priceLevel,
    double? existingPrice,
    double? existingMinQty,
  }) {
    final priceController = TextEditingController(
      text: existingPrice?.toString() ?? '',
    );
    final minQuantityController = TextEditingController(
      text: (existingMinQty ?? 1.0).toString(),
    );
    int selectedPriceLevel = priceLevel ?? 1;
    int? selectedSubUnitId = subUnitId;
    final pricesCubit = context.read<ProductPricesCubit>();
    final subUnitsCubit = context.read<ProductSubUnitsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: pricesCubit),
            BlocProvider.value(value: subUnitsCubit),
          ],
          child: StatefulBuilder(
            builder: (context, setState) => CustomDialog(
              title: Text(existingPrice != null ? 'تعديل السعر' : 'إضافة سعر'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subUnitId == null)
                      BlocBuilder<ProductSubUnitsCubit, ProductSubUnitsState>(
                        builder: (context, state) {
                          if (state is ProductSubUnitsLoaded) {
                            return CustomDropdownField<int>(
                              label: 'الوحدة الفرعية',
                              value: selectedSubUnitId,
                              items: state.subUnits
                                  .map(
                                    (subUnit) => DropdownMenuItem<int>(
                                      value: subUnit.id,
                                      child: Text('وحدة ${subUnit.packaging}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => selectedSubUnitId = value);
                              },
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
                    const SizedBox(height: 16),
                    CustomDropdownField<int>(
                      label: 'مستوى السعر',
                      value: selectedPriceLevel,
                      items: const [
                        DropdownMenuItem<int>(
                          value: 1,
                          child: Text('سعر التجزئة'),
                        ),
                        DropdownMenuItem<int>(
                          value: 2,
                          child: Text('سعر الجملة'),
                        ),
                        DropdownMenuItem<int>(value: 3, child: Text('سعر خاص')),
                        DropdownMenuItem<int>(
                          value: 4,
                          child: Text('سعر الموزع'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedPriceLevel = value ?? 1);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      label: 'السعر',
                      hint: '0.00',
                      decoration: const InputDecoration(suffixText: 'ر.س'),
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      controller: minQuantityController,
                      keyboardType: TextInputType.number,
                      label: 'الكمية الدنيا',
                      hint: '1',
                      decoration: const InputDecoration(
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
                HasibButton(
                  label: 'حفظ',
                  onPressed: () {
                    final priceValue =
                        double.tryParse(priceController.text) ?? 0;
                    final minQty =
                        double.tryParse(minQuantityController.text) ?? 1;

                    if (selectedSubUnitId == null) {
                      AppToast.showError(context, 'يرجى اختيار الوحدة الفرعية');
                      return;
                    }

                    if (priceValue <= 0) {
                      AppToast.showError(context, 'يرجى إدخال سعر صحيح');
                      return;
                    }

                    pricesCubit.savePrice(
                      subUnitId: selectedSubUnitId!,
                      priceLevel: selectedPriceLevel,
                      amount: priceValue,
                      minQuantity: minQty,
                    );
                    Navigator.pop(dialogContext);
                  },
                  variant: HasibButtonVariant.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
