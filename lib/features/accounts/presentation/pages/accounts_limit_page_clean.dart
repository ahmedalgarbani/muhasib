import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_limits_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/core/helpers/get_it.dart';

class AccountLimitsScreen extends StatefulWidget {
  const AccountLimitsScreen({super.key});

  @override
  State<AccountLimitsScreen> createState() => _AccountLimitsScreenState();
}

class _AccountLimitsScreenState extends State<AccountLimitsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AccountLimitsCubit>().loadLimits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حدود الحسابات'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AccountLimitsCubit, AccountLimitsState>(
        listener: (context, state) {
          if (state is AccountLimitsLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          } else if (state is AccountLimitsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AccountLimitsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is AccountLimitsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AccountLimitsCubit>().loadLimits(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          
          if (state is AccountLimitsLoaded) {
            if (state.limits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد حدود حسابات',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddLimitDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة حد حساب جديد'),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الحدود المضافة: ${state.limits.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddLimitDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة حد جديد'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.limits.length,
                    itemBuilder: (context, index) {
                      final limit = state.limits[index];
                      return _buildLimitCard(context, limit);
                    },
                  ),
                ),
              ],
            );
          }
          
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLimitCard(BuildContext context, AccountLimitEntity limit) {
    final theme = Theme.of(context);
    final usageLevel = limit.usageLevel;
    final color = usageLevel == UsageLevel.critical
        ? Colors.red
        : usageLevel == UsageLevel.warning
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        limit.accountName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الكود: ${limit.accountCode} - العملة: ${limit.currencyCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditLimitDialog(context, limit),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, limit),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (limit.debitLimit > 0) ...[
              _buildLimitRow(
                context,
                'حد المدين',
                limit.currentDebit,
                limit.debitLimit,
                limit.debitUsagePercentage,
                color,
              ),
              const SizedBox(height: 8),
            ],
            if (limit.creditLimit > 0) ...[
              _buildLimitRow(
                context,
                'حد الدائن',
                limit.currentCredit,
                limit.creditLimit,
                limit.creditUsagePercentage,
                color,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الحالة: ${limit.isActive ? "نشط" : "غير نشط"}',
                  style: TextStyle(
                    color: limit.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    usageLevel == UsageLevel.critical
                        ? 'حرج'
                        : usageLevel == UsageLevel.warning
                            ? 'تحذير'
                            : 'آمن',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitRow(
    BuildContext context,
    String label,
    double current,
    double limit,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${current.toStringAsFixed(2)} / ${limit.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(1)}% مستخدم',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountLimitsCubit>()),
          BlocProvider(create: (_) => getIt<AccountsCubit>()..loadAllAccounts()),
          BlocProvider(create: (_) => getIt<CurrenciesCubit>()..loadAllCurrencies()),
        ],
        child: const AddEditLimitDialog(),
      ),
    );
  }

  void _showEditLimitDialog(BuildContext context, AccountLimitEntity limit) {
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountLimitsCubit>()),
          BlocProvider(create: (_) => getIt<AccountsCubit>()..loadAllAccounts()),
          BlocProvider(create: (_) => getIt<CurrenciesCubit>()..loadAllCurrencies()),
        ],
        child: AddEditLimitDialog(limit: limit),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AccountLimitEntity limit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف حد الحساب ${limit.accountName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AccountLimitsCubit>().deleteLimit(limit.id!);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddEditLimitDialog extends StatefulWidget {
  final AccountLimitEntity? limit;

  const AddEditLimitDialog({super.key, this.limit});

  @override
  State<AddEditLimitDialog> createState() => _AddEditLimitDialogState();
}

class _AddEditLimitDialogState extends State<AddEditLimitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _debitLimitController;
  late TextEditingController _creditLimitController;
  AccountEntity? _selectedAccount;
  CurrencyEntity? _selectedCurrency;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _debitLimitController = TextEditingController(
      text: widget.limit?.debitLimit.toString() ?? '0',
    );
    _creditLimitController = TextEditingController(
      text: widget.limit?.creditLimit.toString() ?? '0',
    );
    _isActive = widget.limit?.isActive ?? true;
  }

  @override
  void dispose() {
    _debitLimitController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.limit == null ? 'إضافة حد حساب' : 'تعديل حد الحساب'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.limit == null) ...[
                BlocBuilder<AccountsCubit, AccountsState>(
                  builder: (context, state) {
                    if (state is AccountsLoaded) {
                      return DropdownButtonFormField<AccountEntity>(
                        value: _selectedAccount,
                        decoration: const InputDecoration(
                          labelText: 'الحساب',
                          border: OutlineInputBorder(),
                        ),
                        items: state.accounts.map((account) {
                          return DropdownMenuItem(
                            value: account,
                            child: Text(account.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccount = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'يرجى اختيار الحساب';
                          }
                          return null;
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<CurrenciesCubit, CurrenciesState>(
                  builder: (context, state) {
                    if (state is CurrenciesLoaded) {
                      return DropdownButtonFormField<CurrencyEntity>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'العملة',
                          border: OutlineInputBorder(),
                        ),
                        items: state.currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('${currency.name} (${currency.code})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'يرجى اختيار العملة';
                          }
                          return null;
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _debitLimitController,
                decoration: const InputDecoration(
                  labelText: 'حد المدين',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال حد المدين';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 0) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'حد الدائن',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال حد الدائن';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 0) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('نشط'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saveLimit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _saveLimit() {
    if (_formKey.currentState!.validate()) {
      final limit = widget.limit?.copyWith(
            debitLimit: double.parse(_debitLimitController.text),
            creditLimit: double.parse(_creditLimitController.text),
            isActive: _isActive,
          ) ??
          AccountLimitEntity(
            accountId: _selectedAccount!.id!,
            accountName: _selectedAccount!.name,
            accountCode: _selectedAccount!.code,
            currencyId: _selectedCurrency!.id!,
            currencyCode: _selectedCurrency!.code,
            debitLimit: double.parse(_debitLimitController.text),
            creditLimit: double.parse(_creditLimitController.text),
            isActive: _isActive,
          );

      context.read<AccountLimitsCubit>().saveLimit(limit);
      Navigator.pop(context);
    }
  }
}
