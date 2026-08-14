import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/banks_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/banks_list_widget.dart';

class BanksPage extends StatelessWidget {
  const BanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BanksCubit>()..loadBanks(),
      child: const _BanksView(),
    );
  }
}

class _BanksView extends StatefulWidget {
  const _BanksView();

  @override
  State<_BanksView> createState() => _BanksViewState();
}

class _BanksViewState extends State<_BanksView> {
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
        title: 'البنوك',
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              if (_showActiveOnly) {
                context.read<BanksCubit>().loadActiveBanks();
              } else {
                context.read<BanksCubit>().loadBanks();
              }
            },
            tooltip: _showActiveOnly ? 'عرض الكل' : 'النشطة فقط',
          ),
        ],
      ),
      body: BlocConsumer<BanksCubit, BanksState>(
        listener: (context, state) {
          if (state is BankCreated) {
            AppToast.showSuccess(context, 'تم إضافة البنك بنجاح');
          } else if (state is BankUpdated) {
            AppToast.showSuccess(context, 'تم تحديث البنك بنجاح');
          } else if (state is BankDeleted) {
            AppToast.showSuccess(context, 'تم حذف البنك بنجاح');
          } else if (state is BanksError) {
            AppToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is BanksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BanksLoaded) {
            if (state.banks.isEmpty) {
              return const EmptyStateWidget(
                title: 'لا توجد بنوك',
                subtitle: 'اضغط على الزر أدناه لإضافة بنك جديد',
                icon: Icons.account_balance_outlined,
              );
            }
            return BanksListWidget(
              banks: state.banks,
              searchController: _searchController,
              onSearchChanged: (value) {
                if (value.isEmpty) {
                  context.read<BanksCubit>().loadBanks();
                } else {
                  context.read<BanksCubit>().searchBanks(value);
                }
              },
              onClearSearch: () {
                _searchController.clear();
                context.read<BanksCubit>().loadBanks();
              },
              onBankTap: (bank) => _showBankDialog(context, bank: bank),
              onBankEdit: (bank) => _showBankDialog(context, bank: bank),
              onBankDelete: (bank) => _showDeleteDialog(context, bank),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBankDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('بنك جديد'),
        backgroundColor: AppColors.materialBlue700,
      ),
    );
  }

  void _showBankDialog(BuildContext context, {BankEntity? bank}) {
    showDialog(
      context: context,
      builder: (dialogContext) => _BankFormDialog(
        bank: bank,
        onSave: (savedBank) {
          if (bank != null) {
            context.read<BanksCubit>().updateBank(savedBank);
          } else {
            context.read<BanksCubit>().createBank(savedBank);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BankEntity bank) {
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
            const Text('حذف البنك'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف البنك "${bank.name}"؟'),
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
              this.context.read<BanksCubit>().deleteBank(bank.id!);
            },
          ),
        ],
      ),
    );
  }
}

class _BankFormDialog extends StatefulWidget {
  final BankEntity? bank;
  final ValueChanged<BankEntity> onSave;

  const _BankFormDialog({this.bank, required this.onSave});

  @override
  State<_BankFormDialog> createState() => _BankFormDialogState();
}

class _BankFormDialogState extends State<_BankFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _branchController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _bankCodeController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bank?.name ?? '');
    _contactController = TextEditingController(text: widget.bank?.contact ?? '');
    _branchController = TextEditingController(text: widget.bank?.branchName ?? '');
    _accountNumberController = TextEditingController(text: widget.bank?.accountNumber ?? '');
    _bankCodeController = TextEditingController(text: widget.bank?.bankCode ?? '');
    _isActive = widget.bank?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _branchController.dispose();
    _accountNumberController.dispose();
    _bankCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bank != null;
    return CustomDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.materialBlue700.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppColors.materialBlue700,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'تعديل البنك' : 'إضافة بنك جديد'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextInputField(
              controller: _nameController,
              label: 'اسم البنك *',
            ),
            const SizedBox(height: 16),
            TextInputField(
              controller: _contactController,
              label: 'رقم التواصل',
            ),
            const SizedBox(height: 16),
            TextInputField(
              controller: _branchController,
              label: 'اسم الفرع',
            ),
            const SizedBox(height: 16),
            TextInputField(
              controller: _accountNumberController,
              label: 'رقم الحساب',
            ),
            const SizedBox(height: 16),
            TextInputField(
              controller: _bankCodeController,
              label: 'كود البنك',
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
              AppToast.showError(context, 'الرجاء إدخال اسم البنك');
              return;
            }

            final newBank = BankEntity(
              id: widget.bank?.id,
              name: _nameController.text.trim(),
              contact: _contactController.text.trim(),
              contactType: 0,
              branchName: _branchController.text.trim().isNotEmpty
                  ? _branchController.text.trim()
                  : null,
              accountNumber: _accountNumberController.text.trim().isNotEmpty
                  ? _accountNumberController.text.trim()
                  : null,
              bankCode: _bankCodeController.text.trim().isNotEmpty
                  ? _bankCodeController.text.trim()
                  : null,
              isActive: _isActive,
              accountId: widget.bank?.accountId,
            );

            Navigator.of(context).pop();
            widget.onSave(newBank);
          },
        ),
      ],
    );
  }
}
