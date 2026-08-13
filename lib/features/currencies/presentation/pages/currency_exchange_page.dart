import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import '../cubit/currencies_cubit.dart';
import '../../domain/entities/currency_entity.dart';

class CurrencyExchangePage extends StatefulWidget {
  const CurrencyExchangePage({super.key});

  @override
  State<CurrencyExchangePage> createState() => _CurrencyExchangePageState();
}

class _CurrencyExchangePageState extends State<CurrencyExchangePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _resultController = TextEditingController();
  final _notesController = TextEditingController();

  CurrencyEntity? fromCurrency;
  CurrencyEntity? toCurrency;
  double exchangeRate = 1.0;
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
        toCurrency == null) {
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    final fromRate = fromCurrency!.exchangeRate;
    final toRate = toCurrency!.exchangeRate;

    // Calculate exchange: convert to base currency first, then to target
    final result = (amount * fromRate) / toRate;
    exchangeRate = fromRate / toRate;

    _resultController.text = result.toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'تحويل العملات',
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showHistorySheet(),
            ),
          ],
        ),
        body: BlocBuilder<CurrenciesCubit, CurrenciesState>(
          builder: (context, state) {
            if (state is CurrenciesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CurrenciesLoaded) {
              final currencies = state.currencies;
              if (currencies.isEmpty) {
                return _buildEmptyState();
              }
              return _buildExchangeForm(currencies);
            }
            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_exchange,
              size: 50,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد عملات مسجلة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى إضافة عملات أولاً من صفحة إدارة العملات',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeForm(List<CurrencyEntity> currencies) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExchangeCard(currencies),
            const SizedBox(height: 16),
            _buildRateInfo(),
            const SizedBox(height: 16),
            _buildDateAndNotes(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildQuickExchangeRates(currencies),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeCard(List<CurrencyEntity> currencies) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // From Currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<CurrencyEntity>(
                    initialValue: fromCurrency,
                    decoration: InputDecoration(
                      labelText: 'من العملة',
                      prefixIcon: const Icon(
                        Icons.monetization_on,
                        color: AppColors.info,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text('${currency.name} (${currency.code})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => fromCurrency = value);
                      _calculateExchange();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextInputField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    label: 'المبلغ',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (_) => _calculateExchange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Swap Button
            Center(
              child: GestureDetector(
                onTap: () {
                  final temp = fromCurrency;
                  setState(() {
                    fromCurrency = toCurrency;
                    toCurrency = temp;
                  });
                  _calculateExchange();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.swap_vert, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // To Currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<CurrencyEntity>(
                    initialValue: toCurrency,
                    decoration: InputDecoration(
                      labelText: 'إلى العملة',
                      prefixIcon: const Icon(
                        Icons.monetization_on,
                        color: AppColors.success,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text('${currency.name} (${currency.code})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => toCurrency = value);
                      _calculateExchange();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextInputField(
                    controller: _resultController,
                    readOnly: true,
                    label: 'الناتج',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      filled: true,
                      fillColor: AppColors.success.withOpacity(0.05),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInfo() {
    if (fromCurrency == null || toCurrency == null) return const SizedBox();

    return Card(
      elevation: 0,
      color: AppColors.info.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سعر الصرف',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '1 ${fromCurrency!.code} = ${exchangeRate.toStringAsFixed(4)} ${toCurrency!.code}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndNotes() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'تاريخ العملية',
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: AppColors.info,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextInputField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: const Icon(Icons.note, color: AppColors.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearForm,
            icon: const Icon(Icons.clear),
            label: const Text('مسح'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _saveExchange,
            icon: const Icon(Icons.save),
            label: const Text('حفظ عملية التحويل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickExchangeRates(List<CurrencyEntity> currencies) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أسعار الصرف الحالية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...currencies.map((currency) => _buildRateRow(currency)),
          ],
        ),
      ),
    );
  }

  Widget _buildRateRow(CurrencyEntity currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm10),
            ),
            child: Center(
              child: Text(
                currency.code.length > 2
                    ? currency.code.substring(0, 2)
                    : currency.code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  currency.code,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            currency.exchangeRate.toStringAsFixed(4),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _amountController.clear();
    _resultController.clear();
    _notesController.clear();
    setState(() {
      fromCurrency = null;
      toCurrency = null;
      exchangeRate = 1.0;
    });
  }

  void _saveExchange() {
    if (fromCurrency == null ||
        toCurrency == null ||
        _amountController.text.isEmpty) {
      AppToast.showError(context, 'الرجاء ملء جميع الحقول المطلوبة');
      return;
    }

    final transaction = ExchangeTransaction(
      fromCurrency: fromCurrency!,
      toCurrency: toCurrency!,
      amount: double.parse(_amountController.text),
      result: double.parse(_resultController.text),
      exchangeRate: exchangeRate,
      date: selectedDate,
      notes: _notesController.text,
    );

    setState(() {
      transactions.insert(0, transaction);
    });

    AppToast.showSuccess(context, 'تم حفظ عملية التحويل بنجاح');

    _clearForm();
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'سجل التحويلات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Divider(height: 32),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('لا توجد عمليات تحويل سابقة'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.info,
                                child: Icon(
                                  Icons.currency_exchange,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${tx.amount} ${tx.fromCurrency.code} → ${tx.result.toStringAsFixed(2)} ${tx.toCurrency.code}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'معدل: ${tx.exchangeRate.toStringAsFixed(4)} • ${DateFormat('yyyy-MM-dd').format(tx.date)}',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExchangeTransaction {
  final CurrencyEntity fromCurrency;
  final CurrencyEntity toCurrency;
  final double amount;
  final double result;
  final double exchangeRate;
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
