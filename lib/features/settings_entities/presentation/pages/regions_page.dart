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
            AppToast.showSuccess(context, 'تم إضافة المنطقة بنجاح');
          } else if (state is RegionUpdated) {
            AppToast.showSuccess(context, 'تم تحديث المنطقة بنجاح');
          } else if (state is RegionDeleted) {
            AppToast.showSuccess(context, 'تم حذف المنطقة بنجاح');
          } else if (state is RegionsError) {
            AppToast.showError(context, state.message);
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

  void _showRegionDialog(BuildContext context, {RegionEntity? region}) {
    showDialog(
      context: context,
      builder: (dialogContext) => _RegionFormDialog(
        region: region,
        onSave: (savedRegion) {
          if (region != null) {
            context.read<RegionsCubit>().updateRegion(savedRegion);
          } else {
            context.read<RegionsCubit>().createRegion(savedRegion);
          }
        },
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
          context.read<RegionsCubit>().deleteRegion(region.id!);
        },
      ),
    );
  }
}

class _RegionFormDialog extends StatefulWidget {
  final RegionEntity? region;
  final ValueChanged<RegionEntity> onSave;

  const _RegionFormDialog({this.region, required this.onSave});

  @override
  State<_RegionFormDialog> createState() => _RegionFormDialogState();
}

class _RegionFormDialogState extends State<_RegionFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _countryController;
  late final TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.region?.name ?? '');
    _codeController = TextEditingController(text: widget.region?.code ?? '');
    _countryController = TextEditingController(text: widget.region?.country ?? '');
    _descriptionController = TextEditingController(text: widget.region?.description ?? '');
    _isActive = widget.region?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.region != null;
    return CustomDialog(
      title: isEditing ? 'تعديل المنطقة' : 'إضافة منطقة جديدة',
      icon: Icons.location_city,
      headerColor: AppColors.materialDeepOrange500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextInputField(
            label: 'اسم المنطقة',
            isRequired: true,
            textEditingController: _nameController,
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'الرمز (Code)',
            textEditingController: _codeController,
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'الدولة',
            textEditingController: _countryController,
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'الوصف',
            textEditingController: _descriptionController,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          CustomSwitchTile(
            title: 'الحالة',
            subtitle: 'تفعيل أو تعطيل المنطقة',
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
        ],
      ),
      actions: [
        HasibButton(
          label: 'إلغاء',
          variant: HasibButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        HasibButton(
          label: isEditing ? 'تحديث' : 'إضافة',
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              AppToast.showError(context, 'الرجاء إدخال اسم المنطقة');
              return;
            }

            final newRegion = RegionEntity(
              id: widget.region?.id,
              name: _nameController.text.trim(),
              code: _codeController.text.trim().isNotEmpty
                  ? _codeController.text.trim()
                  : null,
              country: _countryController.text.trim().isNotEmpty
                  ? _countryController.text.trim()
                  : null,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
              isActive: _isActive,
              parentRegionId: widget.region?.parentRegionId,
            );

            Navigator.of(context).pop();
            widget.onSave(newRegion);
          },
        ),
      ],
    );
  }
}
