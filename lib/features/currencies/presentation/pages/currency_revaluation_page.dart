import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/currency_exchange_service.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

/// Page for revaluating foreign currency balances
class CurrencyRevaluationPage extends StatefulWidget {
  const CurrencyRevaluationPage({super.key});

  @override
  State<CurrencyRevaluationPage> createState() =>
      _CurrencyRevaluationPageState();
}

class _CurrencyRevaluationPageState extends State<CurrencyRevaluationPage> {
  final _formKey = GlobalKey<FormState>();
  final _newRateController = TextEditingController();

  List<Map<String, dynamic>> currencies = [];
  List<Map<String, dynamic>> accounts = [];

  int? selectedCurrencyId;
  int? selectedAccountId;
  int? gainLossAccountId;
  DateTime revaluationDate = DateTime.now();

  double? currentRate;
  double? calculatedDifference;
  bool isLoading = false;
  bool isCalculating = false;

  late CurrencyExchangeService _exchangeService;

  @override
  void initState() {
    super.initState();
    _exchangeService = CurrencyExchangeService(getIt<DatabaseService>());
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await getIt<DatabaseService>().database;

    // Load currencies
    final currencyResult = await db.query(
      'currencies',
      where: 'is_local_currency = 0',
      orderBy: 'name',
    );

    // Load accounts (assets with currency)
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
    if (selectedAccountId == null || selectedCurrencyId == null) return;
    if (_newRateController.text.isEmpty) return;

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
      (failure) {
        AppToast.showError(context, failure.message);
      },
      (difference) {
        setState(() => calculatedDifference = difference);
      },
    );

    setState(() => isCalculating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildSelectionCard(),
                const SizedBox(height: 16),
                _buildRateCard(),
                const SizedBox(height: 16),
                if (calculatedDifference != null) _buildDifferenceCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: AppColors.info.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.info.withOpacity(0.2)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ما هي إعادة التقييم؟',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'إعادة تقييم الأرصدة بالعملات الأجنبية عند تغير سعر الصرف، ينتج عنها أرباح أو خسائر فروق صرف تُسجل في قائمة الدخل.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  Widget _buildSelectionCard() {
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
              'تحديد الحساب والعملة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedCurrencyId,
              decoration: InputDecoration(
                labelText: 'العملة الأجنبية',
                prefixIcon: const Icon(
                  Icons.monetization_on,
                  color: AppColors.info,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              items: currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency['id'] as int,
                  child: Text(
                    '${currency['name']} (${currency['code']}) - سعر: ${currency['exchange_rate']}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCurrencyId = value;
                  currentRate =
                      currencies.firstWhere(
                            (c) => c['id'] == value,
                          )['exchange_rate']
                          as double?;
                });
                _calculateDifference();
              },
              validator: (value) => value == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedAccountId,
              decoration: InputDecoration(
                labelText: 'الحساب',
                prefixIcon: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.info,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              items: accounts.map((account) {
                return DropdownMenuItem(
                  value: account['id'] as int,
                  child: Text('${account['code']} - ${account['name']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedAccountId = value);
                _calculateDifference();
              },
              validator: (value) => value == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: gainLossAccountId,
              decoration: InputDecoration(
                labelText: 'حساب أرباح/خسائر فروق الصرف',
                prefixIcon: const Icon(Icons.swap_horiz, color: AppColors.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                helperText: 'سيتم احتسابه تلقائياً بناءً على نوع الفرق',
              ),
              items: accounts
                  .where(
                    (a) => (a['type'] as int?) == 3 || (a['type'] as int?) == 4,
                  )
                  .map((account) {
                    return DropdownMenuItem(
                      value: account['id'] as int,
                      child: Text('${account['code']} - ${account['name']}'),
                    );
                  })
                  .toList(),
              onChanged: (value) => setState(() => gainLossAccountId = value),
              validator: (value) => value == null ? 'مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard() {
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
              'سعر الصرف الجديد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (currentRate != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'السعر الحالي: ${currentRate!.toStringAsFixed(4)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextInputField(
              controller: _newRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'سعر الصرف الجديد',
                prefixIcon: const Icon(
                  Icons.trending_up,
                  color: AppColors.info,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onChanged: (_) => _calculateDifference(),
              validator: (value) {
                if (value == null || value.isEmpty) return 'مطلوب';
                if (double.tryParse(value) == null) return 'رقم غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: revaluationDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => revaluationDate = picked);
                  _calculateDifference();
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'تاريخ إعادة التقييم',
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: AppColors.info,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(revaluationDate)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifferenceCard() {
    final isProfit = calculatedDifference! > 0;

    return Card(
      elevation: 0,
      color: isProfit
          ? Colors.green.withOpacity(0.05)
          : Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isProfit
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isProfit ? 'أرباح فروق الصرف' : 'خسائر فروق الصرف',
                        style: TextStyle(
                          fontSize: 14,
                          color: isProfit ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      Text(
                        calculatedDifference!.abs().toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isProfit ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              isProfit
                  ? 'سيتم تسجيل قيد محاسبي بزيادة قيمة الأصول وتسجيل أرباح فروق الصرف'
                  : 'سيتم تسجيل قيد محاسبي بتخفيض قيمة الأصول وتسجيل خسائر فروق الصرف',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
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
            onPressed: () {
              _newRateController.clear();
              setState(() {
                selectedCurrencyId = null;
                selectedAccountId = null;
                gainLossAccountId = null;
                currentRate = null;
                calculatedDifference = null;
              });
            },
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
            onPressed:
                (isLoading ||
                    calculatedDifference == null ||
                    calculatedDifference!.abs() < 0.01)
                ? null
                : _createRevaluationEntry,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(isLoading ? 'جاري الحفظ...' : 'إنشاء قيد التسوية'),
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

  Future<void> _createRevaluationEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (calculatedDifference == null || calculatedDifference!.abs() < 0.01) {
      return;
    }

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

    result.fold(
      (failure) {
        AppToast.showError(context, failure.message);
      },
      (journalId) {
        AppToast.showSuccess(context, 'تم إنشاء قيد التسوية رقم $journalId بنجاح');
        Navigator.pop(context);
      },
    );
  }
}
