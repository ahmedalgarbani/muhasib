import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import '../../domain/entities/opening_balance_entity.dart';
import '../cubit/initial_cubit.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class OpeningBalancesPage extends StatefulWidget {
  const OpeningBalancesPage({super.key});

  @override
  State<OpeningBalancesPage> createState() => _OpeningBalancesPageState();
}

class _OpeningBalancesPageState extends State<OpeningBalancesPage> {
  final Map<int, TextEditingController> _balanceControllers = {};
  final Map<int, bool> _debitCreditSelection =
      {}; // true = debit, false = credit
  List<AccountEntity> _accounts = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    context.read<AccountsCubit>().loadAllAccounts();
  }

  @override
  void dispose() {
    for (var controller in _balanceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'الأرصدة الافتتاحية',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
            tooltip: 'تاريخ الأرصدة',
          ),
        ],
      ),
      body: BlocBuilder<AccountsCubit, AccountsState>(
        builder: (context, state) {
          if (state is AccountsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AccountsLoaded) {
            _accounts = state.accounts.where((a) => !a.isMaster).toList();
            return Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildAccountsList()),
                _buildFooter(),
              ],
            );
          }

          if (state is AccountsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('خطأ: ${state.message}'),
                  ElevatedButton(
                    onPressed: _loadAccounts,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('لا توجد حسابات'));
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أدخل الأرصدة الافتتاحية للحسابات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'الحساب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'مدين',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'دائن',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 100, child: Center(child: Text('المبلغ'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return ListView.builder(
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        _balanceControllers.putIfAbsent(
          account.id!,
          () => TextEditingController(text: '0'),
        );
        _debitCreditSelection.putIfAbsent(account.id!, () => true);

        return CustomCardContainer(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${account.code} - ${account.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (account.statement != null)
                        Text(
                          account.statement!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Radio<bool>(
                    value: true,
                    groupValue: _debitCreditSelection[account.id],
                    onChanged: (value) {
                      setState(() {
                        _debitCreditSelection[account.id!] = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Radio<bool>(
                    value: false,
                    groupValue: _debitCreditSelection[account.id],
                    onChanged: (value) {
                      setState(() {
                        _debitCreditSelection[account.id!] = value!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextInputField(
                    controller: _balanceControllers[account.id],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final totals = _calculateTotals();
    final isBalanced = (totals['debit']! - totals['credit']!).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('إجمالي المدين'),
                  Text(
                    NumberFormat('#,##0.00').format(totals['debit']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('إجمالي الدائن'),
                  Text(
                    NumberFormat('#,##0.00').format(totals['credit']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('الفرق'),
                  Text(
                    NumberFormat(
                      '#,##0.00',
                    ).format((totals['debit']! - totals['credit']!).abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isBalanced ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isBalanced)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تحذير: المجاميع غير متوازنة! يجب أن يكون إجمالي المدين مساوياً لإجمالي الدائن',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.clear),
                label: const Text('مسح الكل'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              ElevatedButton.icon(
                onPressed: isBalanced ? _saveBalances : null,
                icon: const Icon(Icons.save),
                label: const Text('حفظ الأرصدة'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateTotals() {
    double totalDebit = 0;
    double totalCredit = 0;

    for (var account in _accounts) {
      final amount =
          double.tryParse(_balanceControllers[account.id]?.text ?? '0') ?? 0;

      if (_debitCreditSelection[account.id] == true) {
        totalDebit += amount;
      } else {
        totalCredit += amount;
      }
    }

    return {'debit': totalDebit, 'credit': totalCredit};
  }

  void _clearAll() {
    setState(() {
      for (var controller in _balanceControllers.values) {
        controller.text = '0';
      }
      for (var accountId in _debitCreditSelection.keys) {
        _debitCreditSelection[accountId] = true;
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveBalances() async {
    final balances = <OpeningBalanceEntity>[];

    for (var account in _accounts) {
      final amount =
          double.tryParse(_balanceControllers[account.id]?.text ?? '0') ?? 0;

      if (amount > 0) {
        final isDebit = _debitCreditSelection[account.id] == true;
        balances.add(
          OpeningBalanceEntity(
            accountId: account.id!,
            accountName: account.name,
            accountCode: account.code,
            debitAmount: isDebit ? amount : 0,
            creditAmount: isDebit ? 0 : amount,
            balance: isDebit ? amount : -amount,
            currencyCode: 'SAR',
            exchangeRate: 1.0,
            statement: 'رصيد افتتاحي',
            date: _selectedDate,
          ),
        );
      }
    }

    if (balances.isEmpty) {
      AppToast.showWarning(context, 'لا توجد أرصدة لحفظها');
      return;
    }

    try {
      await context.read<InitialCubit>().saveOpeningBalances(balances);

      if (!mounted) return;

      AppToast.showSuccess(context, 'تم حفظ الأرصدة الافتتاحية بنجاح');

      Navigator.pop(context);
    } catch (e) {
      AppToast.showError(context, 'خطأ في حفظ الأرصدة: $e');
    }
  }
}
