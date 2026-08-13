import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/currency_exchange_service.dart';
import 'package:muhasib/core/services/database_service.dart';
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
    _exchangeService = CurrencyExchangeService(getIt<DatabaseService>());
    context.read<CurrenciesCubit>().loadAllCurrencies();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final db = await getIt<DatabaseService>().database;
    final result = await db.query(
      'accounts',
      columns: ['id', 'code', 'name', 'type'],
      where: 'is_active = 1 AND is_master = 0',
      orderBy: 'code',
    );
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
    if (!_formKey.currentState!.validate() ||
        fromCurrency == null ||
        toCurrency == null)
      return;
    setState(() => isLoading = true);
    final result = await _exchangeService.createExchange(
      creditAccountId: fromAccountId!,
      creditCurrencyId: fromCurrency!.id!,
      creditCurrencyCode: fromCurrency!.code,
      creditAmount: double.parse(_amountController.text),
      creditExchangeRate: fromCurrency!.exchangeRate,
      debitAccountId: toAccountId!,
      debitCurrencyId: toCurrency!.id!,
      debitCurrencyCode: toCurrency!.code,
      debitAmount: double.parse(_resultController.text),
      debitExchangeRate: toCurrency!.exchangeRate,
      date: selectedDate,
      notes: _notesController.text,
      customExchangeRate: useCustomRate
          ? double.tryParse(_customRateController.text)
          : null,
      exchangeDifferenceAccountId: exchangeDifferenceAccountId,
    );
    setState(() => isLoading = false);
    result.fold((f) => AppToast.showError(context, f.message), (e) {
      AppToast.showSuccess(context, 'تم حفظ عملية الصرف رقم ${e.number} بنجاح');
      _clearForm();
    });
  }
}
