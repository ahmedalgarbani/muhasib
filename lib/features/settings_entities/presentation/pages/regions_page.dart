import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_switch_tile.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/settings_entities/domain/entities/region_entity.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/regions_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/regions_list_widget.dart';

class RegionsPage extends StatelessWidget {
  const RegionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RegionsCubit>()..loadRegions(),
      child: const _RegionsView(),
    );
  }
}

class _RegionsView extends StatefulWidget {
  const _RegionsView();

  @override
  State<_RegionsView> createState() => _RegionsViewState();
}

class _RegionsViewState extends State<_RegionsView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'المناطق',
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              if (_showActiveOnly) {
                context.read<RegionsCubit>().loadActiveRegions();
              } else {
                context.read<RegionsCubit>().loadRegions();
              }
            },
            tooltip: _showActiveOnly ? 'عرض الكل' : 'النشطة فقط',
          ),
        ],
      ),
      body: BlocConsumer<RegionsCubit, RegionsState>(
        listener: (context, state) {
          if (state is RegionCreated) {
            _showSnackBar(context, 'تم إضافة المنطقة بنجاح', Colors.green);
          } else if (state is RegionUpdated) {
            _showSnackBar(context, 'تم تحديث المنطقة بنجاح', Colors.green);
          } else if (state is RegionDeleted) {
            _showSnackBar(context, 'تم حذف المنطقة بنجاح', Colors.green);
          } else if (state is RegionsError) {
            _showSnackBar(context, state.message, Colors.red);
          }
        },
        builder: (context, state) {
          if (state is RegionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RegionsLoaded) {
            if (state.regions.isEmpty) {
              return const EmptyStateWidget(
                title: 'لا توجد مناطق',
                subtitle: 'اضغط على الزر أدناه لإضافة منطقة جديدة',
                icon: Icons.location_city_outlined,
              );
            }
            return RegionsListWidget(
              regions: state.regions,
              searchController: _searchController,
              onSearchChanged: (value) {
                if (value.isEmpty) {
                  context.read<RegionsCubit>().loadRegions();
                } else {
                  context.read<RegionsCubit>().searchRegions(value);
                }
              },
              onClearSearch: () {
                _searchController.clear();
                context.read<RegionsCubit>().loadRegions();
              },
              onRegionTap: (region) =>
                  _showRegionDialog(context, region: region),
              onRegionEdit: (region) =>
                  _showRegionDialog(context, region: region),
              onRegionDelete: (region) => _showDeleteDialog(context, region),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('منطقة جديدة'),
        backgroundColor: AppColors.materialDeepOrange500,
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (color == Colors.green) {
      AppToast.showSuccess(context, message);
    } else if (color == Colors.orange) {
      AppToast.showWarning(context, message);
    } else {
      AppToast.showError(context, message);
    }
  }

  void _showRegionDialog(BuildContext context, {RegionEntity? region}) {
    final isEditing = region != null;
    final nameController = TextEditingController(text: region?.name ?? '');
    final codeController = TextEditingController(text: region?.code ?? '');
    final countryController = TextEditingController(
      text: region?.country ?? '',
    );
    final descriptionController = TextEditingController(
      text: region?.description ?? '',
    );
    bool isActive = region?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => CustomDialog(
          title: isEditing ? 'تعديل المنطقة' : 'إضافة منطقة جديدة',
          icon: Icons.location_city,
          headerColor: AppColors.materialDeepOrange500,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextInputField(
                label: 'اسم المنطقة',
                isRequired: true,
                textEditingController: nameController,
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'الرمز (Code)',
                textEditingController: codeController,
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'الدولة',
                textEditingController: countryController,
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'الوصف',
                textEditingController: descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CustomSwitchTile(
                title: 'الحالة',
                subtitle: 'تفعيل أو تعطيل المنطقة',
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            HasibButton(
              label: 'إلغاء',
              variant: HasibButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(width: 12),
            HasibButton(
              label: isEditing ? 'تحديث' : 'إضافة',
              onPressed: () {
                if (nameController.text.isEmpty) {
                  _showSnackBar(
                    context,
                    'الرجاء إدخال اسم المنطقة',
                    Colors.red,
                  );
                  return;
                }

                final newRegion = RegionEntity(
                  id: region?.id,
                  name: nameController.text,
                  code: codeController.text.isNotEmpty
                      ? codeController.text
                      : null,
                  country: countryController.text.isNotEmpty
                      ? countryController.text
                      : null,
                  description: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  isActive: isActive,
                );

                Navigator.of(dialogContext).pop();
                if (isEditing) {
                  this.context.read<RegionsCubit>().updateRegion(newRegion);
                } else {
                  this.context.read<RegionsCubit>().createRegion(newRegion);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, RegionEntity region) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: 'حذف المنطقة',
        message: 'هل أنت متأكد من حذف المنطقة "${region.name}"؟',
        confirmLabel: 'حذف',
        isDanger: true,
        onConfirm: () {
          this.context.read<RegionsCubit>().deleteRegion(region.id!);
        },
      ),
    );
  }
}
