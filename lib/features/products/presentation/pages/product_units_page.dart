import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_unit_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
import 'package:muhasib/features/products/presentation/widgets/product_units_widgets.dart';

class ProductUnitsPage extends StatefulWidget {
  const ProductUnitsPage({super.key});

  @override
  State<ProductUnitsPage> createState() => _ProductUnitsPageState();
}

class _ProductUnitsPageState extends State<ProductUnitsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProductUnitsCubit>()..loadAllUnits(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              ProductUnitsHeaderWidget(
                searchController: _searchController,
                onSearchChanged: (value) {
                  if (value.isNotEmpty) {
                    context.read<ProductUnitsCubit>().searchUnits(value);
                  } else {
                    context.read<ProductUnitsCubit>().loadAllUnits();
                  }
                },
              ),
              Expanded(
                child: BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
                  builder: (context, state) {
                    if (state is ProductUnitsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProductUnitsError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is ProductUnitsLoaded) {
                      if (state.units.isEmpty) {
                        return const EmptyStateWidget(
                          title: 'لا توجد وحدات قياس',
                          subtitle: 'ابدأ بإضافة وحدة قياس جديدة',
                          icon: Icons.square_foot_outlined,
                        );
                      }
                      return ProductUnitsListWidget(
                        units: state.units,
                        onEditUnit: (unit) => _showUnitDialog(context, unit: unit),
                        onDeleteUnit: (unit) =>
                            _showDeleteConfirmation(context, unit),
                      );
                    }
                    return const Center(
                      child: Text('ابدأ بإضافة وحدات القياس'),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showUnitDialog(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('وحدة جديدة'),
          ),
        ),
      ),
    );
  }

  void _showUnitDialog(BuildContext context, {ProductUnitEntity? unit}) {
    final nameController = TextEditingController(text: unit?.name);
    final shortController = TextEditingController(text: unit?.short);
    final factorController = TextEditingController(
      text: unit?.conversionFactor.toString() ?? '1.0',
    );
    bool isActive = unit?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) => CustomDialog(
            title: Text(unit == null ? 'وحدة جديدة' : 'تعديل الوحدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextInputField(
                    controller: nameController,
                    label: 'اسم الوحدة',
                    hint: 'مثال: كيلوجرام',
                  ),
                  const SizedBox(height: 16),
                  TextInputField(
                    controller: shortController,
                    label: 'الاختصار',
                    hint: 'مثال: كجم',
                  ),
                  const SizedBox(height: 16),
                  TextInputField(
                    controller: factorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    label: 'معامل التحويل',
                    hint: 'مثال: 1.0',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
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
                label: unit == null ? 'إضافة' : 'حفظ',
                onPressed: () {
                  if (nameController.text.trim().isEmpty ||
                      shortController.text.trim().isEmpty) {
                    AppToast.showError(
                      context,
                      'الرجاء إدخال اسم الوحدة والاختصار',
                    );
                    return;
                  }

                  final factor = double.tryParse(factorController.text) ?? 1.0;

                  final entity = ProductUnitEntity(
                    id: unit?.id,
                    name: nameController.text.trim(),
                    short: shortController.text.trim(),
                    conversionFactor: factor,
                    isActive: isActive,
                  );

                  if (unit == null) {
                    context.read<ProductUnitsCubit>().createUnit(entity);
                  } else {
                    context.read<ProductUnitsCubit>().updateUnit(entity);
                  }

                  Navigator.pop(dialogContext);
                },
                variant: HasibButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductUnitEntity unit) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: CustomDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف وحدة "${unit.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (unit.id != null) {
                  context.read<ProductUnitsCubit>().deleteUnit(unit.id!);
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
