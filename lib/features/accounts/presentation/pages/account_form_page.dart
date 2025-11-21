import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';

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
      appBar: AppBar(
        title: Text(
          widget.account == null ? 'إضافة حساب جديد' : 'تعديل الحساب',
        ),
      ),
      body: BlocListener<AccountsCubit, AccountsState>(
        listener: (context, state) {
          if (state is AccountCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إنشاء الحساب بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is AccountUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث الحساب بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is AccountsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _cIdController,
                  decoration: const InputDecoration(
                    labelText: 'معرف الحساب (C_ID)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'كود الحساب',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كود الحساب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الحساب',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الحساب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'نوع الحساب',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('أصول')),
                    DropdownMenuItem(value: 1, child: Text('خصوم')),
                    DropdownMenuItem(value: 2, child: Text('حقوق ملكية')),
                    DropdownMenuItem(value: 3, child: Text('إيرادات')),
                    DropdownMenuItem(value: 4, child: Text('مصروفات')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _type = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _national,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف الوطني',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('محلي')),
                    DropdownMenuItem(value: 1, child: Text('دولي')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _national = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _statementController,
                  decoration: const InputDecoration(
                    labelText: 'البيان',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'الرصيد',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                TextFormField(
                  controller: _localBalanceController,
                  decoration: const InputDecoration(
                    labelText: 'الرصيد المحلي',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                SwitchListTile(
                  title: const Text('حساب رئيسي'),
                  subtitle: const Text(
                    'يمكن إضافة حسابات فرعية تحت هذا الحساب',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isMaster,
                  onChanged: (value) {
                    setState(() {
                      _isMaster = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('السماح بالتعديل والحذف'),
                  value: _allowUpdateDelete,
                  onChanged: (value) {
                    setState(() {
                      _allowUpdateDelete = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                BlocBuilder<AccountsCubit, AccountsState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is AccountsLoading
                          ? null
                          : () => _submitForm(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state is AccountsLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              widget.account == null
                                  ? 'إضافة الحساب'
                                  : 'تحديث الحساب',
                              style: const TextStyle(fontSize: 16),
                            ),
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
