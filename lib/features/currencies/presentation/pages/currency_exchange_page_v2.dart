import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/currency_exchange_service.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_exchange_entity.dart';
import '../cubit/currencies_cubit.dart';
import '../widgets/currency_exchange_v2_widgets.dart';

class CurrencyExchangePageV2 extends StatefulWidget {
  const CurrencyExchangePageV2({super.key});
  @override
  State<CurrencyExchangePageV2> createState() => _CurrencyExchangePageV2State();
}

class _CurrencyExchangePageV2State extends State<CurrencyExchangePageV2> {
  final _formKey = GlobalKey<FormState>(),
      _amountController = TextEditingController(),
      _resultController = TextEditingController(),
      _notesController = TextEditingController(),
      _customRateController = TextEditingController();
  CurrencyEntity? fromCurrency, toCurrency;
  double exchangeRate = 1;
  DateTime selectedDate = DateTime.now();
  bool useCustomRate = false, isLoading = false;
  List<CurrencyExchangeEntity> transactions = [];
  List<Map<String, dynamic>> accounts = [];
  int? fromAccountId, toAccountId, exchangeDifferenceAccountId;
  late CurrencyExchangeService _exchangeService;
  @override
  void initState() {
    super.initState();
    _exchangeService = getIt<CurrencyExchangeService>();
    context.read<CurrenciesCubit>().loadAllCurrencies();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final ds = getIt<ReportsLocalDataSource>();
    final result = await ds.getAccountsForExchange();
    setState(() => accounts = result);
  }

  void _calculateExchange() {
    if (_amountController.text.isEmpty ||
        fromCurrency == null ||
        toCurrency == null)
      return;
    exchangeRate = useCustomRate && _customRateController.text.isNotEmpty
        ? double.tryParse(_customRateController.text) ?? 1
        : fromCurrency!.exchangeRate / toCurrency!.exchangeRate;
    _resultController.text =
        ((double.tryParse(_amountController.text) ?? 0) * exchangeRate)
            .toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'صرف العملات'),
      body: BlocBuilder<CurrenciesCubit, CurrenciesState>(
        builder: (context, state) {
          if (state is CurrenciesLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is CurrenciesLoaded && state.currencies.isNotEmpty)
            return CurrencyExchangeV2Form(
              formKey: _formKey,
              currencies: state.currencies,
              accounts: accounts,
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
              differenceAccountId: exchangeDifferenceAccountId,
              amountController: _amountController,
              resultController: _resultController,
              customRateController: _customRateController,
              notesController: _notesController,
              useCustomRate: useCustomRate,
              exchangeRate: exchangeRate,
              date: selectedDate,
              isLoading: isLoading,
              onFromCurrency: (v) {
                setState(() => fromCurrency = v);
                _calculateExchange();
              },
              onToCurrency: (v) {
                setState(() => toCurrency = v);
                _calculateExchange();
              },
              onSwap: () {
                final c = fromCurrency;
                final a = fromAccountId;
                setState(() {
                  fromCurrency = toCurrency;
                  toCurrency = c;
                  fromAccountId = toAccountId;
                  toAccountId = a;
                });
                _calculateExchange();
              },
              onAmount: _calculateExchange,
              onCustomRate: (v) => _calculateExchange(),
              onCustomRateToggle: (v) {
                setState(() {
                  useCustomRate = v;
                  if (!v) _customRateController.clear();
                });
                _calculateExchange();
              },
              onFromAccount: (v) => setState(() => fromAccountId = v),
              onToAccount: (v) => setState(() => toAccountId = v),
              onDifferenceAccount: (v) =>
                  setState(() => exchangeDifferenceAccountId = v),
              onDate: (v) => setState(() => selectedDate = v),
              onClear: _clearForm,
              onSave: _saveExchange,
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
    _customRateController.clear();
    setState(() {
      fromCurrency = null;
      toCurrency = null;
      fromAccountId = null;
      toAccountId = null;
      exchangeDifferenceAccountId = null;
      exchangeRate = 1;
      useCustomRate = false;
    });
  }

  Future<void> _saveExchange() async {
    if (!_formKey.currentState!.validate()) return;
    if (fromCurrency == null || toCurrency == null) {
      AppToast.showError(context, 'يرجى اختيار العملة المباعة والعملة المشتراة');
      return;
    }
    if (fromCurrency!.id == toCurrency!.id) {
      AppToast.showError(context, 'لا يمكن صرف نفس العملة، يرجى اختيار عملتين مختلفتين');
      return;
    }
    if (fromAccountId == null || toAccountId == null) {
      AppToast.showError(context, 'يرجى اختيار حساب الخزينة للعملتين');
      return;
    }
    if (fromAccountId == toAccountId) {
      AppToast.showError(context, 'لا يمكن التحويل من وإلى نفس حساب الخزينة');
      return;
    }

    final fromAmount = double.tryParse(_amountController.text) ?? 0;
    final toAmount = double.tryParse(_resultController.text) ?? 0;
    final fromLocal = fromAmount * fromCurrency!.exchangeRate;
    final toLocal = toAmount * toCurrency!.exchangeRate;
    final diff = (toLocal - fromLocal).abs();

    if (diff > 0.005 && exchangeDifferenceAccountId == null) {
      AppToast.showError(context, 'توجد فروق أسعار صرف (${diff.toStringAsFixed(2)})، يرجى تحديد حساب فروق الصرف');
      return;
    }

    setState(() => isLoading = true);
    final result = await _exchangeService.createExchange(
      creditAccountId: fromAccountId!,
      creditCurrencyId: fromCurrency!.id!,
      creditCurrencyCode: fromCurrency!.code,
      creditAmount: fromAmount,
      creditExchangeRate: fromCurrency!.exchangeRate,
      debitAccountId: toAccountId!,
      debitCurrencyId: toCurrency!.id!,
      debitCurrencyCode: toCurrency!.code,
      debitAmount: toAmount,
      debitExchangeRate: toCurrency!.exchangeRate,
      date: selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      customExchangeRate: useCustomRate
          ? double.tryParse(_customRateController.text)
          : null,
      exchangeDifferenceAccountId: exchangeDifferenceAccountId,
    );
    setState(() => isLoading = false);
    result.fold((f) => AppToast.showError(context, f.message), (e) {
      AppToast.showSuccess(context, 'تم حفظ وترحيل عملية الصرف رقم EX-${e.number} بنجاح');
      _clearForm();
    });
  }
}
