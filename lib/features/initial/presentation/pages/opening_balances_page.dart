import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/initial/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/initial/presentation/cubit/initial_cubit.dart';
import 'package:muhasib/features/initial/presentation/widgets/opening_balances_widgets.dart';

class OpeningBalancesPage extends StatefulWidget {
  const OpeningBalancesPage({super.key});

  @override
  State<OpeningBalancesPage> createState() => _OpeningBalancesPageState();
}

class _OpeningBalancesPageState extends State<OpeningBalancesPage> {
  final Map<int, TextEditingController> _balanceControllers = {};
  final Map<int, bool> _debitCreditSelection = {}; // true = debit, false = credit
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
            final totals = _calculateTotals();
            final isBalanced =
                (totals['debit']! - totals['credit']!).abs() < 0.01;

            return Column(
              children: [
                OpeningBalancesHeaderWidget(selectedDate: _selectedDate),
                Expanded(
                  child: OpeningBalancesAccountsListWidget(
                    accounts: _accounts,
                    balanceControllers: _balanceControllers,
                    debitCreditSelection: _debitCreditSelection,
                    onSelectionChanged: (accountId, isDebit) {
                      setState(() {
                        _debitCreditSelection[accountId] = isDebit;
                      });
                    },
                    onChanged: () => setState(() {}),
                  ),
                ),
                OpeningBalancesFooterWidget(
                  totals: totals,
                  isBalanced: isBalanced,
                  onClearAll: _clearAll,
                  onSaveBalances: isBalanced ? _saveBalances : null,
                ),
              ],
            );
          }

          if (state is AccountsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('خطأ: ${state.message}'),
                  HasibButton(
                    label: 'إعادة المحاولة',
                    onPressed: _loadAccounts,
                    variant: HasibButtonVariant.primary,
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
