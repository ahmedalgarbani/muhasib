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
            _showSnackBar(context, 'تم إضافة الأداة بنجاح', Colors.green);
          } else if (state is OtherFeeUpdated) {
            _showSnackBar(context, 'تم تحديث الأداة بنجاح', Colors.green);
          } else if (state is OtherFeeDeleted) {
            _showSnackBar(context, 'تم حذف الأداة بنجاح', Colors.green);
          } else if (state is OtherFeesError) {
            _showSnackBar(context, state.message, Colors.red);
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

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (color == Colors.green) {
      AppToast.showSuccess(context, message);
    } else if (color == Colors.orange) {
      AppToast.showWarning(context, message);
    } else {
      AppToast.showError(context, message);
    }
  }

  void _showOtherFeeDialog(BuildContext context, {OtherFeeEntity? otherFee}) {
    final isEditing = otherFee != null;
    final nameController = TextEditingController(text: otherFee?.name ?? '');
    bool isActive = otherFee?.isActive ?? true;
    int toolType = otherFee?.toolType ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => CustomDialog(
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
                TextInputField(
                  controller: nameController,
                  label: 'اسم الأداة *',
                ),
                const SizedBox(height: 16),
                CustomDropdownField<int>(
                  value: toolType,
                  label: 'نوع الأداة',
                  items: _toolTypes.asMap().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => toolType = value ?? 0),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            HasibButton(
              label: isEditing ? 'تحديث' : 'إضافة',
              onPressed: () {
                if (nameController.text.isEmpty) {
                  _showSnackBar(context, 'الرجاء إدخال اسم الأداة', Colors.red);
                  return;
                }

                final newOtherFee = OtherFeeEntity(
                  id: otherFee?.id,
                  name: nameController.text,
                  isActive: isActive,
                  toolType: toolType,
                );

                Navigator.of(dialogContext).pop();
                if (isEditing) {
                  this.context.read<OtherFeesCubit>().updateOtherFee(
                    newOtherFee,
                  );
                } else {
                  this.context.read<OtherFeesCubit>().createOtherFee(
                    newOtherFee,
                  );
                }
              },
            ),
          ],
        ),
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
              this.context.read<OtherFeesCubit>().deleteOtherFee(otherFee.id!);
            },
          ),
        ],
      ),
    );
  }
}
