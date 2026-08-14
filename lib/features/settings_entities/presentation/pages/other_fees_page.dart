import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/settings_entities/domain/entities/other_fee_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/other_fees_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/other_fees_list_widget.dart';

class OtherFeesPage extends StatelessWidget {
  const OtherFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<OtherFeesCubit>()..loadOtherFees(),
      child: const _OtherFeesView(),
    );
  }
}

class _OtherFeesView extends StatefulWidget {
  const _OtherFeesView();

  @override
  State<_OtherFeesView> createState() => _OtherFeesViewState();
}

class _OtherFeesViewState extends State<_OtherFeesView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = false;

  static const List<String> _toolTypes = ['مصروفات', 'إيرادات', 'أخرى'];

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
        title: 'أدوات أخرى',
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              if (_showActiveOnly) {
                context.read<OtherFeesCubit>().loadActiveOtherFees();
              } else {
                context.read<OtherFeesCubit>().loadOtherFees();
              }
            },
            tooltip: _showActiveOnly ? 'عرض الكل' : 'النشطة فقط',
          ),
        ],
      ),
      body: BlocConsumer<OtherFeesCubit, OtherFeesState>(
        listener: (context, state) {
          if (state is OtherFeeCreated) {
            AppToast.showSuccess(context, 'تم إضافة الأداة بنجاح');
          } else if (state is OtherFeeUpdated) {
            AppToast.showSuccess(context, 'تم تحديث الأداة بنجاح');
          } else if (state is OtherFeeDeleted) {
            AppToast.showSuccess(context, 'تم حذف الأداة بنجاح');
          } else if (state is OtherFeesError) {
            AppToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is OtherFeesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OtherFeesLoaded) {
            if (state.otherFees.isEmpty) {
              return const EmptyStateWidget(
                title: 'لا توجد أدوات',
                subtitle: 'اضغط على الزر أدناه لإضافة أداة جديدة',
                icon: Icons.build_outlined,
              );
            }
            return OtherFeesListWidget(
              otherFees: state.otherFees,
              toolTypes: _toolTypes,
              searchController: _searchController,
              onSearchChanged: (value) {
                if (value.isEmpty) {
                  context.read<OtherFeesCubit>().loadOtherFees();
                } else {
                  context.read<OtherFeesCubit>().searchOtherFees(value);
                }
              },
              onClearSearch: () {
                _searchController.clear();
                context.read<OtherFeesCubit>().loadOtherFees();
              },
              onOtherFeeTap: (otherFee) =>
                  _showOtherFeeDialog(context, otherFee: otherFee),
              onOtherFeeEdit: (otherFee) =>
                  _showOtherFeeDialog(context, otherFee: otherFee),
              onOtherFeeDelete: (otherFee) =>
                  _showDeleteDialog(context, otherFee),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOtherFeeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('أداة جديدة'),
        backgroundColor: AppColors.materialPurple500,
      ),
    );
  }

  void _showOtherFeeDialog(BuildContext context, {OtherFeeEntity? otherFee}) {
    showDialog(
      context: context,
      builder: (dialogContext) => _OtherFeeFormDialog(
        otherFee: otherFee,
        toolTypes: _toolTypes,
        onSave: (savedOtherFee) {
          if (otherFee != null) {
            context.read<OtherFeesCubit>().updateOtherFee(savedOtherFee);
          } else {
            context.read<OtherFeesCubit>().createOtherFee(savedOtherFee);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, OtherFeeEntity otherFee) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text('حذف الأداة'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف الأداة "${otherFee.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'حذف',
            variant: HasibButtonVariant.danger,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<OtherFeesCubit>().deleteOtherFee(otherFee.id!);
            },
          ),
        ],
      ),
    );
  }
}

class _OtherFeeFormDialog extends StatefulWidget {
  final OtherFeeEntity? otherFee;
  final List<String> toolTypes;
  final ValueChanged<OtherFeeEntity> onSave;

  const _OtherFeeFormDialog({
    this.otherFee,
    required this.toolTypes,
    required this.onSave,
  });

  @override
  State<_OtherFeeFormDialog> createState() => _OtherFeeFormDialogState();
}

class _OtherFeeFormDialogState extends State<_OtherFeeFormDialog> {
  late final TextEditingController _nameController;
  late bool _isActive;
  late int _toolType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.otherFee?.name ?? '');
    _isActive = widget.otherFee?.isActive ?? true;
    _toolType = widget.otherFee?.toolType ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.otherFee != null;
    return CustomDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.materialPurple500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.build,
              color: AppColors.materialPurple500,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'تعديل الأداة' : 'إضافة أداة جديدة'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextInputField(controller: _nameController, label: 'اسم الأداة *'),
            const SizedBox(height: 16),
            CustomDropdownField<int>(
              value: _toolType,
              label: 'نوع الأداة',
              items: widget.toolTypes.asMap().entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) => setState(() => _toolType = value ?? 0),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('نشط'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        HasibButton(
          label: isEditing ? 'تحديث' : 'إضافة',
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              AppToast.showError(context, 'الرجاء إدخال اسم الأداة');
              return;
            }

            final newOtherFee = OtherFeeEntity(
              id: widget.otherFee?.id,
              name: _nameController.text.trim(),
              isActive: _isActive,
              toolType: _toolType,
              accountId: widget.otherFee?.accountId,
            );

            Navigator.of(context).pop();
            widget.onSave(newOtherFee);
          },
        ),
      ],
    );
  }
}
