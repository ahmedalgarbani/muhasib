import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/constant/account_constants.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/custom_switch_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';

class AccountFormPage extends StatefulWidget {
  final AccountEntity? account;

  const AccountFormPage({super.key, this.account});

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cIdController;
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _statementController;
  late TextEditingController _balanceController;
  late TextEditingController _localBalanceController;

  bool _isMaster = false;
  bool _isActive = true;
  bool _allowUpdateDelete = true;
  int _type = 0;
  int _national = 0;

  @override
  void initState() {
    super.initState();
    _cIdController = TextEditingController(
      text: widget.account?.cId.toString() ?? '',
    );
    _codeController = TextEditingController(text: widget.account?.code ?? '');
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _statementController = TextEditingController(
      text: widget.account?.statement ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.account?.balance.toString() ?? '0.0',
    );
    _localBalanceController = TextEditingController(
      text: widget.account?.localBalance.toString() ?? '0.0',
    );

    if (widget.account != null) {
      _isMaster = widget.account!.isMaster;
      _isActive = widget.account!.isActive;
      _allowUpdateDelete = widget.account!.allowUpdateDelete;
      _type = widget.account!.type;
      _national = widget.account!.national;
    }
  }

  @override
  void dispose() {
    _cIdController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _statementController.dispose();
    _balanceController.dispose();
    _localBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: (widget.account == null ? 'إضافة حساب جديد' : 'تعديل الحساب'),
      ),
      body: BlocListener<AccountsCubit, AccountsState>(
        listener: (context, state) {
          if (state is AccountCreated) {
            AppToast.showSuccess(context, 'تم إنشاء الحساب بنجاح');
            Navigator.pop(context);
          } else if (state is AccountUpdated) {
            AppToast.showSuccess(context, 'تم تحديث الحساب بنجاح');
            Navigator.pop(context);
          } else if (state is AccountsError) {
            AppToast.showError(context, state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextInputField(
                  label: 'معرف الحساب (C_ID)',
                  textEditingController: _cIdController,
                  inputType: TextInputType.number,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال معرف الحساب';
                    }
                    if (int.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextInputField(
                  label: 'كود الحساب',
                  textEditingController: _codeController,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كود الحساب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextInputField(
                  label: 'اسم الحساب',
                  textEditingController: _nameController,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الحساب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomDropdownField<int>(
                  label: 'نوع الحساب',
                  value: _type,
                  items: AccountConstants.accountTypes
                      .map((e) => DropdownMenuItem(
                            value: e['id'] as int,
                            child: Text(e['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustomDropdownField<int>(
                  label: 'التصنيف الوطني',
                  value: _national,
                  items: AccountConstants.classificationTypes
                      .map((e) => DropdownMenuItem(
                            value: e['id'] as int,
                            child: Text(e['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _national = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextInputField(
                  label: 'البيان',
                  textEditingController: _statementController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextInputField(
                  label: 'الرصيد',
                  textEditingController: _balanceController,
                  inputType: TextInputType.number,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الرصيد';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextInputField(
                  label: 'الرصيد المحلي',
                  textEditingController: _localBalanceController,
                  inputType: TextInputType.number,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الرصيد المحلي';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomSwitchTile(
                  title: 'حساب رئيسي',
                  subtitle: 'يمكن إضافة حسابات فرعية تحت هذا الحساب',
                  value: _isMaster,
                  onChanged: (value) => setState(() => _isMaster = value),
                ),
                CustomSwitchTile(
                  title: 'نشط',
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                CustomSwitchTile(
                  title: 'السماح بالتعديل والحذف',
                  value: _allowUpdateDelete,
                  onChanged: (value) => setState(() => _allowUpdateDelete = value),
                ),
                const SizedBox(height: 12),
                BlocBuilder<AccountsCubit, AccountsState>(
                  builder: (context, state) {
                    final loading = state is AccountsLoading;
                    return HasibButton(
                      label: widget.account == null ? 'إضافة الحساب' : 'تحديث الحساب',
                      loading: loading,
                      onPressed: loading ? null : () => _submitForm(context),
                      variant: HasibButtonVariant.primary,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final account = AccountEntity(
        id: widget.account?.id,
        creatorId: widget.account?.creatorId ?? 1,
        lastModifierId: 1,
        concurrencyStamp: widget.account?.concurrencyStamp,
        extraProperties: widget.account?.extraProperties,
        creationTime: widget.account?.creationTime ?? now,
        lastModificationTime: now,
        cId: int.parse(_cIdController.text),
        code: _codeController.text,
        name: _nameController.text,
        isMaster: _isMaster,
        masterId: widget.account?.masterId,
        masterCId: widget.account?.masterCId,
        type: _type,
        national: _national,
        statement: _statementController.text.isEmpty
            ? null
            : _statementController.text,
        isActive: _isActive,
        allowUpdateDelete: _allowUpdateDelete,
        balance: double.parse(_balanceController.text),
        localBalance: double.parse(_localBalanceController.text),
      );

      if (widget.account == null) {
        context.read<AccountsCubit>().addAccount(account);
      } else {
        context.read<AccountsCubit>().modifyAccount(account);
      }
    }
  }
}
