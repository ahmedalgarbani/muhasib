import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import '../cubit/currencies_cubit.dart';
import '../../domain/entities/currency_entity.dart';
import '../widgets/currency_exchange_widgets.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class CurrencyExchangePage extends StatefulWidget {
  const CurrencyExchangePage({super.key});
  @override
  State<CurrencyExchangePage> createState() => _CurrencyExchangePageState();
}

class _CurrencyExchangePageState extends State<CurrencyExchangePage> {
  final _formKey = GlobalKey<FormState>(),
      _amountController = TextEditingController(),
      _resultController = TextEditingController(),
      _notesController = TextEditingController();
  CurrencyEntity? fromCurrency, toCurrency;
  double exchangeRate = 1;
  DateTime selectedDate = DateTime.now();
  List<ExchangeTransaction> transactions = [];
  @override
  void initState() {
    super.initState();
    context.read<CurrenciesCubit>().loadAllCurrencies();
  }

  void _calculateExchange() {
    if (_amountController.text.isEmpty ||
        fromCurrency == null ||
        toCurrency == null)
      return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    exchangeRate = fromCurrency!.exchangeRate / toCurrency!.exchangeRate;
    _resultController.text = (amount * exchangeRate).toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'تحويل العملات',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistorySheet,
          ),
        ],
      ),
      body: BlocBuilder<CurrenciesCubit, CurrenciesState>(
        builder: (context, state) {
          if (state is CurrenciesLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is CurrenciesLoaded && state.currencies.isNotEmpty)
            return CurrencyExchangeForm(
              formKey: _formKey,
              currencies: state.currencies,
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              amountController: _amountController,
              resultController: _resultController,
              notesController: _notesController,
              selectedDate: selectedDate,
              exchangeRate: exchangeRate,
              onFromChanged: (v) {
                setState(() => fromCurrency = v);
                _calculateExchange();
              },
              onToChanged: (v) {
                setState(() => toCurrency = v);
                _calculateExchange();
              },
              onAmountChanged: _calculateExchange,
              onSwap: () {
                final t = fromCurrency;
                setState(() {
                  fromCurrency = toCurrency;
                  toCurrency = t;
                });
                _calculateExchange();
              },
              onDateChanged: (v) => setState(() => selectedDate = v),
              onClear: _clearForm,
              onSave: _saveExchange,
              transactions: transactions,
            );
          return const EmptyStateWidget(
            title: 'لا توجد عملات مسجلة',
            subtitle: 'يرجى إضافة عملات أولاً من صفحة إدارة العملات',
            icon: Icons.currency_exchange,
            iconSize: 50,
            iconColor: AppColors.info,
          );
        },
      ),
    ),
  );
  void _clearForm() {
    _amountController.clear();
    _resultController.clear();
    _notesController.clear();
    setState(() {
      fromCurrency = null;
      toCurrency = null;
      exchangeRate = 1;
    });
  }

  void _saveExchange() {
    if (fromCurrency == null ||
        toCurrency == null ||
        _amountController.text.isEmpty) {
      AppToast.showError(context, 'الرجاء ملء جميع الحقول المطلوبة');
      return;
    }
    transactions.insert(
      0,
      ExchangeTransaction(
        fromCurrency: fromCurrency!,
        toCurrency: toCurrency!,
        amount: double.parse(_amountController.text),
        result: double.parse(_resultController.text),
        exchangeRate: exchangeRate,
        date: selectedDate,
        notes: _notesController.text,
      ),
    );
    AppToast.showSuccess(context, 'تم حفظ عملية التحويل بنجاح');
    _clearForm();
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        padding: AppConstant.defaultPadding,
        children: transactions.isEmpty
            ? [const Center(child: Text('لا توجد عمليات تحويل سابقة'))]
            : transactions
                  .map(
                    (tx) => ListTile(
                      title: Text(
                        '${tx.amount} ${tx.fromCurrency.code} → ${tx.result.toStringAsFixed(2)} ${tx.toCurrency.code}',
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}

class ExchangeTransaction {
  final CurrencyEntity fromCurrency, toCurrency;
  final double amount, result, exchangeRate;
  final DateTime date;
  final String notes;
  ExchangeTransaction({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.result,
    required this.exchangeRate,
    required this.date,
    required this.notes,
  });
}
