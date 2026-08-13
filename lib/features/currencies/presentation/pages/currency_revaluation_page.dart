import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/currency_exchange_service.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import '../widgets/currency_revaluation_widgets.dart';

class CurrencyRevaluationPage extends StatefulWidget {
  const CurrencyRevaluationPage({super.key});
  @override
  State<CurrencyRevaluationPage> createState() =>
      _CurrencyRevaluationPageState();
}

class _CurrencyRevaluationPageState extends State<CurrencyRevaluationPage> {
  final _formKey = GlobalKey<FormState>();
  final _newRateController = TextEditingController();
  List<Map<String, dynamic>> currencies = [], accounts = [];
  int? selectedCurrencyId, selectedAccountId, gainLossAccountId;
  DateTime revaluationDate = DateTime.now();
  double? currentRate, calculatedDifference;
  bool isLoading = false, isCalculating = false;
  late CurrencyExchangeService _exchangeService;

  @override
  void initState() {
    super.initState();
    _exchangeService = CurrencyExchangeService(getIt<DatabaseService>());
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await getIt<DatabaseService>().database;
    final currencyResult = await db.query(
      'currencies',
      where: 'is_local_currency = 0',
      orderBy: 'name',
    );
    final accountResult = await db.query(
      'accounts',
      where: 'is_active = 1 AND is_master = 0',
      orderBy: 'code',
    );
    setState(() {
      currencies = currencyResult;
      accounts = accountResult;
    });
  }

  Future<void> _calculateDifference() async {
    if (selectedAccountId == null ||
        selectedCurrencyId == null ||
        _newRateController.text.isEmpty)
      return;
    final newRate = double.tryParse(_newRateController.text);
    if (newRate == null) return;
    setState(() => isCalculating = true);
    final result = await _exchangeService.calculateRevaluationDifference(
      accountId: selectedAccountId!,
      currencyId: selectedCurrencyId!,
      currentRate: newRate,
      asOfDate: revaluationDate,
    );
    result.fold(
      (failure) => AppToast.showError(context, failure.message),
      (difference) => setState(() => calculatedDifference = difference),
    );
    setState(() => isCalculating = false);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'إعادة تقييم العملات'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RevaluationInfoCard(),
              const SizedBox(height: 16),
              RevaluationSelectionCard(
                currencies: currencies,
                accounts: accounts,
                selectedCurrencyId: selectedCurrencyId,
                selectedAccountId: selectedAccountId,
                gainLossAccountId: gainLossAccountId,
                onCurrencyChanged: _selectCurrency,
                onAccountChanged: (value) {
                  setState(() => selectedAccountId = value);
                  _calculateDifference();
                },
                onGainLossChanged: (value) =>
                    setState(() => gainLossAccountId = value),
              ),
              const SizedBox(height: 16),
              RevaluationRateCard(
                currentRate: currentRate,
                controller: _newRateController,
                date: revaluationDate,
                onRateChanged: _calculateDifference,
                onDateChanged: (date) {
                  setState(() => revaluationDate = date);
                  _calculateDifference();
                },
              ),
              const SizedBox(height: 16),
              if (calculatedDifference != null)
                RevaluationDifferenceCard(difference: calculatedDifference!),
              const SizedBox(height: 24),
              RevaluationActionButtons(
                isLoading: isLoading,
                canSave:
                    calculatedDifference != null &&
                    calculatedDifference!.abs() >= 0.01,
                onClear: _clearForm,
                onSave: _createRevaluationEntry,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _selectCurrency(int? value) {
    setState(() {
      selectedCurrencyId = value;
      currentRate =
          currencies.firstWhere((c) => c['id'] == value)['exchange_rate']
              as double?;
    });
    _calculateDifference();
  }

  void _clearForm() {
    _newRateController.clear();
    setState(() {
      selectedCurrencyId = null;
      selectedAccountId = null;
      gainLossAccountId = null;
      currentRate = null;
      calculatedDifference = null;
    });
  }

  Future<void> _createRevaluationEntry() async {
    if (!_formKey.currentState!.validate() ||
        calculatedDifference == null ||
        calculatedDifference!.abs() < 0.01)
      return;
    setState(() => isLoading = true);
    final result = await _exchangeService.createRevaluationEntry(
      accountId: selectedAccountId!,
      currencyId: selectedCurrencyId!,
      newExchangeRate: double.parse(_newRateController.text),
      revaluationAmount: calculatedDifference!,
      gainLossAccountId: gainLossAccountId!,
      date: revaluationDate,
      notes: 'إعادة تقييم أرصدة العملات الأجنبية',
    );
    setState(() => isLoading = false);
    result.fold((failure) => AppToast.showError(context, failure.message), (
      journalId,
    ) {
      AppToast.showSuccess(
        context,
        'تم إنشاء قيد التسوية رقم $journalId بنجاح',
      );
      Navigator.pop(context);
    });
  }
}
