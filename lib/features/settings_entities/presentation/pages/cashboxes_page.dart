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
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/cashboxes_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/cashboxes_list_widget.dart';

class CashboxesPage extends StatelessWidget {
  const CashboxesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CashboxesCubit>()..loadCashboxes(),
      child: const _CashboxesView(),
    );
  }
}

class _CashboxesView extends StatefulWidget {
  const _CashboxesView();

  @override
  State<_CashboxesView> createState() => _CashboxesViewState();
}

class _CashboxesViewState extends State<_CashboxesView> {
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
        title: 'الصناديق المالية',
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              if (_showActiveOnly) {
                context.read<CashboxesCubit>().loadActiveCashboxes();
              } else {
                context.read<CashboxesCubit>().loadCashboxes();
              }
            },
            tooltip: _showActiveOnly ? 'عرض الكل' : 'النشطة فقط',
          ),
        ],
      ),
      body: BlocConsumer<CashboxesCubit, CashboxesState>(
        listener: (context, state) {
          if (state is CashboxCreated) {
            AppToast.showSuccess(context, 'تم إضافة الصندوق بنجاح');
          } else if (state is CashboxUpdated) {
            AppToast.showSuccess(context, 'تم تحديث الصندوق بنجاح');
          } else if (state is CashboxDeleted) {
            AppToast.showSuccess(context, 'تم حذف الصندوق بنجاح');
          } else if (state is MainCashboxSet) {
            AppToast.showSuccess(context, 'تم تعيين الصندوق الرئيسي بنجاح');
          } else if (state is CashboxesError) {
            AppToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is CashboxesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CashboxesLoaded) {
            if (state.cashboxes.isEmpty) {
              return const EmptyStateWidget(
                title: 'لا توجد صناديق مضافة',
                subtitle: 'اضغط على الزر أدناه لإضافة صندوق مال جديد',
                icon: Icons.point_of_sale_outlined,
              );
            }
            return CashboxesListWidget(
              cashboxes: state.cashboxes,
              searchController: _searchController,
              onSearchChanged: (value) {
                if (value.isEmpty) {
                  context.read<CashboxesCubit>().loadCashboxes();
                } else {
                  context.read<CashboxesCubit>().searchCashboxes(value);
                }
              },
              onClearSearch: () {
                _searchController.clear();
                context.read<CashboxesCubit>().loadCashboxes();
              },
              onCashboxTap: (cashbox) =>
                  _showCashboxDialog(context, cashbox: cashbox),
              onCashboxEdit: (cashbox) =>
                  _showCashboxDialog(context, cashbox: cashbox),
              onCashboxSetMain: (cashbox) =>
                  _showSetMainDialog(context, cashbox),
              onCashboxDelete: (cashbox) => _showDeleteDialog(context, cashbox),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCashboxDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('صندوق جديد'),
        backgroundColor: AppColors.materialTeal600,
      ),
    );
  }

  void _showCashboxDialog(BuildContext context, {CashboxEntity? cashbox}) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CashboxFormDialog(
        cashbox: cashbox,
        onSave: (savedCashbox) {
          if (cashbox != null) {
            context.read<CashboxesCubit>().updateCashbox(savedCashbox);
          } else {
            context.read<CashboxesCubit>().createCashbox(savedCashbox);
          }
        },
      ),
    );
  }

  void _showSetMainDialog(BuildContext context, CashboxEntity cashbox) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: 'تعيين كصندوق رئيسي',
        message: 'هل تريد تعيين "${cashbox.name}" كصندوق رئيسي؟',
        confirmLabel: 'تعيين كرئيسي',
        icon: Icons.star_rounded,
        onConfirm: () {
          context.read<CashboxesCubit>().setMainCashbox(cashbox.id!);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CashboxEntity cashbox) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: 'حذف الصندوق',
        message: 'هل أنت متأكد من حذف الصندوق "${cashbox.name}"؟',
        confirmLabel: 'حذف',
        isDanger: true,
        onConfirm: () {
          context.read<CashboxesCubit>().deleteCashbox(cashbox.id!);
        },
      ),
    );
  }
}

class _CashboxFormDialog extends StatefulWidget {
  final CashboxEntity? cashbox;
  final ValueChanged<CashboxEntity> onSave;

  const _CashboxFormDialog({this.cashbox, required this.onSave});

  @override
  State<_CashboxFormDialog> createState() => _CashboxFormDialogState();
}

class _CashboxFormDialogState extends State<_CashboxFormDialog> {
  late final TextEditingController _nameController;
  late bool _isActive;
  late bool _isMainFund;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cashbox?.name ?? '');
    _isActive = widget.cashbox?.isActive ?? true;
    _isMainFund = widget.cashbox?.isMainFund ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cashbox != null;
    return CustomDialog(
      title: isEditing ? 'تعديل الصندوق' : 'إضافة صندوق جديد',
      icon: Icons.point_of_sale,
      headerColor: AppColors.materialTeal600,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextInputField(
            label: 'اسم الصندوق',
            isRequired: true,
            textEditingController: _nameController,
          ),
          const SizedBox(height: 16),
          CustomSwitchTile(
            title: 'نشط',
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
          CustomSwitchTile(
            title: 'صندوق رئيسي',
            value: _isMainFund,
            onChanged: (value) => setState(() => _isMainFund = value),
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
              AppToast.showError(context, 'الرجاء إدخال اسم الصندوق');
              return;
            }

            final newCashbox = CashboxEntity(
              id: widget.cashbox?.id,
              name: _nameController.text.trim(),
              isActive: _isActive,
              isMainFund: _isMainFund,
              currentBalance: widget.cashbox?.currentBalance,
              currencyId: widget.cashbox?.currencyId,
              accountId: widget.cashbox?.accountId,
            );

            Navigator.of(context).pop();
            widget.onSave(newCashbox);
          },
        ),
      ],
    );
  }
}
