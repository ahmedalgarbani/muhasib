import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/currency_exchange_service.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_exchange_entity.dart';
import '../cubit/currencies_cubit.dart';

class CurrencyExchangePageV2 extends StatefulWidget {
  const CurrencyExchangePageV2({Key? key}) : super(key: key);

  @override
  State<CurrencyExchangePageV2> createState() => _CurrencyExchangePageV2State();
}

class _CurrencyExchangePageV2State extends State<CurrencyExchangePageV2> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _resultController = TextEditingController();
  final _notesController = TextEditingController();
  final _customRateController = TextEditingController();
  
  CurrencyEntity? fromCurrency;
  CurrencyEntity? toCurrency;
  double exchangeRate = 1.0;
  DateTime selectedDate = DateTime.now();
  bool useCustomRate = false;
  bool isLoading = false;
  
  List<CurrencyExchangeEntity> transactions = [];
  List<Map<String, dynamic>> accounts = [];
  
  int? fromAccountId;
  int? toAccountId;
  int? exchangeDifferenceAccountId;

  late CurrencyExchangeService _exchangeService;

  @override
  void initState() {
    super.initState();
    _exchangeService = CurrencyExchangeService(getIt<DatabaseService>());
    context.read<CurrenciesCubit>().loadAllCurrencies();
    _loadAccounts();
    _loadTransactions();
  }

  Future<void> _loadAccounts() async {
    final db = await getIt<DatabaseService>().database;
    final result = await db.query(
      'accounts',
      columns: ['id', 'code', 'name', 'type'],
      where: 'is_active = 1 AND is_master = 0',
      orderBy: 'code',
    );
    setState(() {
      accounts = result;
    });
  }

  Future<void> _loadTransactions() async {
    final result = await _exchangeService.getAllExchanges();
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
      ),
      (exchanges) => setState(() => transactions = exchanges),
    );
  }

  void _calculateExchange() {
    if (_amountController.text.isEmpty || fromCurrency == null || toCurrency == null) return;
    
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (useCustomRate && _customRateController.text.isNotEmpty) {
      exchangeRate = double.tryParse(_customRateController.text) ?? 1.0;
    } else {
      final fromRate = fromCurrency!.exchangeRate;
      final toRate = toCurrency!.exchangeRate;
      exchangeRate = fromRate / toRate;
    }
    
    final result = amount * exchangeRate;
    _resultController.text = result.toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'صرف العملات',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showHistorySheet(),
              tooltip: 'سجل العمليات',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTransactions,
              tooltip: 'تحديث',
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
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_exchange,
              size: 50,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد عملات مسجلة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
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
            _buildCustomRateSection(),
            const SizedBox(height: 16),
            _buildAccountsSection(),
            const SizedBox(height: 16),
            _buildRateInfo(),
            const SizedBox(height: 16),
            _buildDateAndNotes(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeCard(List<CurrencyEntity> currencies) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تحويل العملات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            // From Currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<CurrencyEntity>(
                    isExpanded: true,
                    value: fromCurrency,
                    decoration: InputDecoration(
                      labelText: 'من العملة (بيع)',
                      prefixIcon: const Icon(Icons.arrow_upward, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.red.withOpacity(0.05),
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
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (_) => _calculateExchange(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      if (double.tryParse(value) == null) {
                        return 'رقم غير صالح';
                      }
                      return null;
                    },
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
                  final tempAccount = fromAccountId;
                  setState(() {
                    fromCurrency = toCurrency;
                    toCurrency = temp;
                    fromAccountId = toAccountId;
                    toAccountId = tempAccount;
                  });
                  _calculateExchange();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                    isExpanded: true,
                    value: toCurrency,
                    decoration: InputDecoration(
                      labelText: 'إلى العملة (شراء)',
                      prefixIcon: const Icon(Icons.arrow_downward, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF10B981).withOpacity(0.05),
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
                  child: TextFormField(
                    controller: _resultController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'الناتج',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF10B981).withOpacity(0.05),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
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

  Widget _buildCustomRateSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: useCustomRate,
                  onChanged: (value) {
                    setState(() => useCustomRate = value ?? false);
                    if (!useCustomRate) {
                      _customRateController.clear();
                    }
                    _calculateExchange();
                  },
                ),
                const Text(
                  'استخدام سعر صرف مخصص',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (useCustomRate) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر الصرف المخصص',
                  prefixIcon: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'أدخل سعر الصرف المراد استخدامه لهذه العملية',
                ),
                onChanged: (_) => _calculateExchange(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الحسابات المحاسبية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'حدد الحسابات التي ستتأثر بعملية الصرف',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: fromAccountId,
              decoration: InputDecoration(
                labelText: 'حساب العملة المباعة (دائن)',
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: accounts.map((account) {
                return DropdownMenuItem(
                  value: account['id'] as int,
                  child: Text('${account['code']} - ${account['name']}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => fromAccountId = value),
              validator: (value) => value == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: toAccountId,
              decoration: InputDecoration(
                labelText: 'حساب العملة المشتراة (مدين)',
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: accounts.map((account) {
                return DropdownMenuItem(
                  value: account['id'] as int,
                  child: Text('${account['code']} - ${account['name']}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => toAccountId = value),
              validator: (value) => value == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: exchangeDifferenceAccountId,
              decoration: InputDecoration(
                labelText: 'حساب فروق الصرف (اختياري)',
                prefixIcon: const Icon(Icons.swap_horiz, color: Color(0xFF3B82F6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'حساب لتسجيل أرباح/خسائر فروق الصرف',
              ),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('-- بدون --')),
                ...accounts.map((account) {
                  return DropdownMenuItem(
                    value: account['id'] as int,
                    child: Text('${account['code']} - ${account['name']}'),
                  );
                }),
              ],
              onChanged: (value) => setState(() => exchangeDifferenceAccountId = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInfo() {
    if (fromCurrency == null || toCurrency == null) return const SizedBox();
    
    final localDifference = (double.tryParse(_amountController.text) ?? 0) * 
        fromCurrency!.exchangeRate - 
        (double.tryParse(_resultController.text) ?? 0) * toCurrency!.exchangeRate;
    
    return Card(
      elevation: 0,
      color: const Color(0xFF3B82F6).withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'سعر الصرف',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        '1 ${fromCurrency!.code} = ${exchangeRate.toStringAsFixed(4)} ${toCurrency!.code}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (localDifference.abs() > 0.01) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    localDifference > 0 ? Icons.trending_up : Icons.trending_down,
                    color: localDifference > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localDifference > 0 ? 'ربح فروق صرف' : 'خسارة فروق صرف',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Text(
                          '${localDifference.abs().toStringAsFixed(2)} (بالعملة المحلية)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: localDifference > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndNotes() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                  prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: const Icon(Icons.note, color: Color(0xFF3B82F6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _saveExchange,
            icon: isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(isLoading ? 'جاري الحفظ...' : 'حفظ عملية الصرف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
      exchangeRate = 1.0;
      useCustomRate = false;
    });
  }

  Future<void> _saveExchange() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (fromCurrency == null || toCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تحديد العملات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (fromAccountId == null || toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تحديد الحسابات المحاسبية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      customExchangeRate: useCustomRate ? double.tryParse(_customRateController.text) : null,
      exchangeDifferenceAccountId: exchangeDifferenceAccountId,
    );

    setState(() => isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
      },
      (exchange) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ عملية الصرف رقم ${exchange.number} بنجاح'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _clearForm();
        _loadTransactions();
      },
    );
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'سجل عمليات الصرف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Divider(height: 32),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('لا توجد عمليات صرف سابقة'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF3B82F6),
                                child: Text(
                                  '${tx.number}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text(
                                '${tx.creditAmount} ${tx.creditCurrencyCode} → ${tx.debitAmount.toStringAsFixed(2)} ${tx.debitCurrencyCode}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'التاريخ: ${DateFormat('yyyy-MM-dd').format(tx.date)}',
                                  ),
                                  if (tx.journalEntryId != null)
                                    Text(
                                      'رقم القيد: ${tx.journalEntryId}',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: tx.exchangeRateDifference.abs() > 0.01
                                  ? Chip(
                                      label: Text(
                                        tx.exchangeRateDifference > 0 ? 'ربح' : 'خسارة',
                                        style: TextStyle(
                                          color: tx.exchangeRateDifference > 0 
                                              ? Colors.green 
                                              : Colors.red,
                                          fontSize: 10,
                                        ),
                                      ),
                                      backgroundColor: tx.exchangeRateDifference > 0
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                    )
                                  : null,
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
