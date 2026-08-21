import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// Bottom Sheet لإضافة حساب جديد بشكل مبسط
void showAddAccountBottomSheet(
  BuildContext context, {
  AccountEntity? masterAccount,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddAccountBottomSheet(masterAccount: masterAccount),
  );
}

class AddAccountBottomSheet extends StatefulWidget {
  final AccountEntity? masterAccount;

  const AddAccountBottomSheet({super.key, this.masterAccount});

  @override
  State<AddAccountBottomSheet> createState() => _AddAccountBottomSheetState();
}

class _AddAccountBottomSheetState extends State<AddAccountBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isMaster = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final uniqueSeed = timestamp + Random().nextInt(1 << 20);

      final cubit = context.read<AccountsCubit>();
      final allAccounts = cubit.allAccounts ?? [];

      String generatedCode = '';
      if (widget.masterAccount == null) {
        // ترقيم الحسابات الرئيسية (1, 2, 3...)
        final rootAccounts = allAccounts
            .where((a) => a.masterId == null && a.masterCId == null)
            .toList();
        if (rootAccounts.isEmpty) {
          generatedCode = '1';
        } else {
          int maxRoot = 0;
          for (var a in rootAccounts) {
            final val = int.tryParse(a.code) ?? 0;
            if (val > maxRoot) maxRoot = val;
          }
          generatedCode = (maxRoot + 1).toString();
        }
      } else {
        // ترقيم الحسابات الفرعية (كود الأب + 01, 02...)
        final parentCode = widget.masterAccount!.code;
        final siblings = allAccounts
            .where(
              (a) =>
                  a.masterId == widget.masterAccount!.id ||
                  a.masterCId == widget.masterAccount!.cId,
            )
            .toList();

        if (siblings.isEmpty) {
          generatedCode = '${parentCode}001';
        } else {
          int maxSuffix = 0;
          for (var a in siblings) {
            if (a.code.startsWith(parentCode) &&
                a.code.length > parentCode.length) {
              final suffixStr = a.code.substring(parentCode.length);
              final suffix = int.tryParse(suffixStr) ?? 0;
              if (suffix > maxSuffix) maxSuffix = suffix;
            }
          }
          generatedCode =
              '$parentCode${(maxSuffix + 1).toString().padLeft(3, '0')}';
        }
      }

      final code = generatedCode;
      final cId = uniqueSeed;

      print('🔍 قيمة _isMaster عند الحفظ: $_isMaster');
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final account = AccountEntity(
        cId: cId,
        code: code,
        name: _nameController.text.trim(),
        type:
            widget.masterAccount?.type ??
            0, // يأخذ نوع الحساب الأب أو أصول افتراضياً
        national:
            widget.masterAccount?.national ??
            0, // يأخذ طبيعة الحساب الأب أو محلي افتراضياً
        creationTime: now,
        lastModificationTime: now,
        isMaster: widget.masterAccount == null
            ? true
            : _isMaster, // يمكن أن يكون رئيسي حتى لو كان تحت حساب آخر
        masterId: widget.masterAccount?.id, // يأخذ id الحساب الأب
        masterCId: widget.masterAccount?.cId, // يأخذ cId الحساب الأب
        isActive: true,
        allowUpdateDelete: true,
        balance: 0.0,
        localBalance: 0.0,
      );

      print(
        '📦 الحساب المُنشأ: isMaster=${account.isMaster}, name=${account.name}',
      );

      context.read<AccountsCubit>().addAccount(account);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountsCubit, AccountsState>(
      listener: (context, state) {
        if (state is AccountCreated) {
          Navigator.pop(context, true);
          buildSnackbar(context, 'تم إضافة الحساب بنجاح', color: Colors.green);
          context.read<AccountsCubit>().loadAllAccounts();
        } else if (state is AccountsError) {
          buildSnackbar(context, state.message);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg20),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.xxs),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.masterAccount != null
                            ? 'إضافة حساب فرعي'
                            : 'إضافة حساب جديد',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextInputField(
                    label: 'اسم سسسسالحساب',
                    hint: 'أدخل اسم الحساب',
                    textEditingController: _nameController,
                    isRequired: true,
                    isArabic: true,
                    prefixIcon: const Icon(Icons.edit, size: 20),
                    inputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('حساب رئيسي'),
                    subtitle: Text(
                      widget.masterAccount != null
                          ? 'يمكن إضافة حسابات تحت هذا الحساب (سيكون تابع لـ "${widget.masterAccount!.name}")'
                          : 'يمكن إضافة حسابات فرعية تحت هذا الحساب',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: widget.masterAccount == null ? true : _isMaster,
                    onChanged: widget.masterAccount == null
                        ? null
                        : (value) {
                            setState(() {
                              _isMaster = value;
                              print(
                                '✅ تم تغيير isMaster إلى: $_isMaster',
                              ); // للتأكد من التغيير
                            });
                          },
                  ),
                  if (widget.masterAccount != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isMaster
                                  ? 'سيتم إضافة هذا الحساب كحساب رئيسي فرعي تحت "${widget.masterAccount!.name}"'
                                  : 'سيتم إضافة هذا الحساب كحساب نهائي تحت "${widget.masterAccount!.name}"',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  BlocBuilder<AccountsCubit, AccountsState>(
                    builder: (context, state) {
                      return HasibButton(
                        label: 'حفظ الحساب',
                        leading: const Icon(
                          Icons.save,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: state is AccountsLoading
                            ? null
                            : _handleSubmit,
                        loading: state is AccountsLoading,
                        variant: HasibButtonVariant.primary,
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // زر الإلغاء
                  HasibButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.pop(context),
                    variant: HasibButtonVariant.text,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
