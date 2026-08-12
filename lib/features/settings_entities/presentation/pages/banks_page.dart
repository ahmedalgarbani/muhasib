import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
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
      backgroundColor: AppColors.neutral100,
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

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (color == Colors.green) {
      AppToast.showSuccess(context, message);
    } else if (color == Colors.orange) {
      AppToast.showWarning(context, message);
    } else {
      AppToast.showError(context, message);
    }
  }

  void _showBankDialog(BuildContext context, {BankEntity? bank}) {
    final isEditing = bank != null;
    final nameController = TextEditingController(text: bank?.name ?? '');
    final contactController = TextEditingController(text: bank?.contact ?? '');
    final branchController = TextEditingController(
      text: bank?.branchName ?? '',
    );
    final accountNumberController = TextEditingController(
      text: bank?.accountNumber ?? '',
    );
    final bankCodeController = TextEditingController(
      text: bank?.bankCode ?? '',
    );
    bool isActive = bank?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم البنك *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'رقم التواصل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: branchController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفرع',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الحساب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bankCodeController,
                  decoration: const InputDecoration(
                    labelText: 'كود البنك',
                    border: OutlineInputBorder(),
                  ),
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
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  AppToast.showError(context, 'الرجاء إدخال اسم البنك');

                  return;
                }

                final newBank = BankEntity(
                  id: bank?.id,
                  name: nameController.text,
                  contact: contactController.text,
                  contactType: 0,
                  branchName: branchController.text.isNotEmpty
                      ? branchController.text
                      : null,
                  accountNumber: accountNumberController.text.isNotEmpty
                      ? accountNumberController.text
                      : null,
                  bankCode: bankCodeController.text.isNotEmpty
                      ? bankCodeController.text
                      : null,
                  isActive: isActive,
                );

                Navigator.of(dialogContext).pop();
                if (isEditing) {
                  this.context.read<BanksCubit>().updateBank(newBank);
                } else {
                  this.context.read<BanksCubit>().createBank(newBank);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.materialBlue700,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'تحديث' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BankEntity bank) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              this.context.read<BanksCubit>().deleteBank(bank.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
