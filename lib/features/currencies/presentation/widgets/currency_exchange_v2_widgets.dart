import 'package:flutter/material.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import '../../domain/entities/currency_entity.dart';

class CurrencyExchangeV2Form extends StatelessWidget {
  const CurrencyExchangeV2Form({
    super.key,
    required this.formKey,
    required this.currencies,
    required this.accounts,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAccountId,
    required this.toAccountId,
    required this.differenceAccountId,
    required this.amountController,
    required this.resultController,
    required this.customRateController,
    required this.notesController,
    required this.useCustomRate,
    required this.exchangeRate,
    required this.date,
    required this.isLoading,
    required this.onFromCurrency,
    required this.onToCurrency,
    required this.onSwap,
    required this.onAmount,
    required this.onCustomRate,
    required this.onCustomRateToggle,
    required this.onFromAccount,
    required this.onToAccount,
    required this.onDifferenceAccount,
    required this.onDate,
    required this.onClear,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final List<CurrencyEntity> currencies;
  final List<Map<String, dynamic>> accounts;
  final CurrencyEntity? fromCurrency, toCurrency;
  final int? fromAccountId, toAccountId, differenceAccountId;
  final TextEditingController amountController,
      resultController,
      customRateController,
      notesController;
  final bool useCustomRate, isLoading;
  final double exchangeRate;
  final DateTime date;
  final ValueChanged<CurrencyEntity?> onFromCurrency, onToCurrency;
  final VoidCallback onSwap, onAmount;
  final ValueChanged<String> onCustomRate;
  final ValueChanged<bool> onCustomRateToggle;
  final ValueChanged<int?> onFromAccount, onToAccount, onDifferenceAccount;
  final ValueChanged<DateTime> onDate;
  final VoidCallback onClear, onSave;

  @override
  Widget build(BuildContext context) {
    final fromAmount = double.tryParse(amountController.text) ?? 0.0;
    final toAmount = double.tryParse(resultController.text) ?? 0.0;
    final fromLocal = fromAmount * (fromCurrency?.exchangeRate ?? 1.0);
    final toLocal = toAmount * (toCurrency?.exchangeRate ?? 1.0);
    final diff = toLocal - fromLocal;
    final hasDiff = diff.abs() > 0.005 && fromAmount > 0;

    return SingleChildScrollView(
      padding: AppConstant.defaultPadding,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Guide Banner
            const _ExchangeGuideBanner(),
            const SizedBox(height: 16),

            // 2. Interactive Converter Card
            _ModernConverterCard(
              currencies: currencies,
              accounts: accounts,
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
              amountController: amountController,
              resultController: resultController,
              exchangeRate: exchangeRate,
              onFromCurrency: onFromCurrency,
              onToCurrency: onToCurrency,
              onFromAccount: onFromAccount,
              onToAccount: onToAccount,
              onSwap: onSwap,
              onAmountChanged: onAmount,
            ),
            const SizedBox(height: 16),

            // 3. Custom Rate Toggle & Settings
            _CustomRateCard(
              useCustomRate: useCustomRate,
              controller: customRateController,
              defaultRate: fromCurrency != null && toCurrency != null
                  ? fromCurrency!.exchangeRate / toCurrency!.exchangeRate
                  : 1.0,
              onToggle: onCustomRateToggle,
              onChanged: onCustomRate,
            ),
            const SizedBox(height: 16),

            // 4. Live Accounting Breakdown & Impact
            _AccountingImpactCard(
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              fromAmount: fromAmount,
              toAmount: toAmount,
              fromLocal: fromLocal,
              toLocal: toLocal,
              difference: diff,
              accounts: accounts,
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
              differenceAccountId: differenceAccountId,
              hasDifference: hasDiff,
              onDifferenceAccount: onDifferenceAccount,
            ),
            const SizedBox(height: 16),

            // 5. Date and Notes
            _DateAndNotesCard(
              date: date,
              notesController: notesController,
              onDate: onDate,
            ),
            const SizedBox(height: 12),

            // 6. Action Buttons
            _ActionButtons(
              isLoading: isLoading,
              onClear: onClear,
              onSave: onSave,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ExchangeGuideBanner extends StatelessWidget {
  const _ExchangeGuideBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_exchange,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحويل وصرف العملات المحاسبي',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'يتم سحب المبلغ من حساب العملة المباعة (دائن) وإيداعه في حساب العملة المشتراة (مدين) مع توليد قيد يومية متوازن آلياً وحساب أي أرباح أو خسائر ناتجة عن فروق الصرف.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernConverterCard extends StatelessWidget {
  const _ModernConverterCard({
    required this.currencies,
    required this.accounts,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountController,
    required this.resultController,
    required this.exchangeRate,
    required this.onFromCurrency,
    required this.onToCurrency,
    required this.onFromAccount,
    required this.onToAccount,
    required this.onSwap,
    required this.onAmountChanged,
  });

  final List<CurrencyEntity> currencies;
  final List<Map<String, dynamic>> accounts;
  final CurrencyEntity? fromCurrency, toCurrency;
  final int? fromAccountId, toAccountId;
  final TextEditingController amountController, resultController;
  final double exchangeRate;
  final ValueChanged<CurrencyEntity?> onFromCurrency, onToCurrency;
  final ValueChanged<int?> onFromAccount, onToAccount;
  final VoidCallback onSwap, onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FROM Section
            _SideBox(
              title: 'العملة المباعة (سحب من الحساب)',
              badgeLabel: 'الطرف الدائن 🔴',
              badgeColor: AppColors.rose50,
              badgeTextColor: AppColors.rose700,
              currency: fromCurrency,
              currencies: currencies,
              accountId: fromAccountId,
              accounts: accounts,
              amountController: amountController,
              isReadOnly: false,
              onCurrencyChanged: onFromCurrency,
              onAccountChanged: onFromAccount,
              onAmountChanged: onAmountChanged,
            ),

            // Center Swap & Rate Info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Tooltip(
                      message: 'تبديل العملات والحسابات',
                      child: InkWell(
                        onTap: onSwap,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.swap_vert,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (fromCurrency != null && toCurrency != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '1 ${fromCurrency!.code} = ${exchangeRate.toStringAsFixed(4)} ${toCurrency!.code}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // TO Section
            _SideBox(
              title: 'العملة المشتراة (إيداع في الحساب)',
              badgeLabel: 'الطرف المدين 🟢',
              badgeColor: AppColors.emerald50,
              badgeTextColor: AppColors.emerald700,
              currency: toCurrency,
              currencies: currencies,
              accountId: toAccountId,
              accounts: accounts,
              amountController: resultController,
              isReadOnly: true,
              onCurrencyChanged: onToCurrency,
              onAccountChanged: onToAccount,
              onAmountChanged: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _SideBox extends StatelessWidget {
  const _SideBox({
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.currency,
    required this.currencies,
    required this.accountId,
    required this.accounts,
    required this.amountController,
    required this.isReadOnly,
    required this.onCurrencyChanged,
    required this.onAccountChanged,
    required this.onAmountChanged,
  });

  final String title;
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeTextColor;
  final CurrencyEntity? currency;
  final List<CurrencyEntity> currencies;
  final int? accountId;
  final List<Map<String, dynamic>> accounts;
  final TextEditingController amountController;
  final bool isReadOnly;
  final ValueChanged<CurrencyEntity?> onCurrencyChanged;
  final ValueChanged<int?> onAccountChanged;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Currency Dropdown
              Expanded(
                flex: 5,
                child: CustomDropdownField<CurrencyEntity>(
                  label: 'العملة',
                  value: currency,
                  items: currencies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.name} (${c.code})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onCurrencyChanged,
                  validator: (v) => v == null ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 10),
              // Amount Input
              Expanded(
                flex: 4,
                child: TextInputField(
                  controller: amountController,
                  label: isReadOnly ? 'المبلغ المستلم' : 'المبلغ المصروف',
                  hint: '0.00',
                  readOnly: isReadOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: isReadOnly ? null : (_) => onAmountChanged(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    final num = double.tryParse(v);
                    if (num == null || num <= 0) return 'قيمة غير صالحة';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Account Selector (Cashbox / Bank)
          CustomDropdownField<int>(
            label: 'حساب الخزينة / البنك',
            value: accountId,
            items: accounts
                .map(
                  (a) => DropdownMenuItem<int>(
                    value: a['id'] as int,
                    child: Text(
                      '${a['code']} - ${a['name']}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            onChanged: onAccountChanged,
            validator: (v) => v == null ? 'يرجى اختيار الحساب' : null,
          ),
        ],
      ),
    );
  }
}

class _CustomRateCard extends StatelessWidget {
  const _CustomRateCard({
    required this.useCustomRate,
    required this.controller,
    required this.defaultRate,
    required this.onToggle,
    required this.onChanged,
  });

  final bool useCustomRate;
  final TextEditingController controller;
  final double defaultRate;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'استخدام سعر صرف مخصص للعملية',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'فعّل هذا الخيار في حال تم الصرف بسعر تفاوضي يختلف عن سعر الصرف الرسمي في النظام.',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: useCustomRate,
              onChanged: onToggle,
            ),
            if (useCustomRate) ...[
              const SizedBox(height: 10),
              TextInputField(
                controller: controller,
                label: 'سعر الصرف الفعلي للعملية',
                hint: defaultRate.toStringAsFixed(4),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: onChanged,
                validator: (v) {
                  if (useCustomRate) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'أدخل سعر صرف صحيح';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountingImpactCard extends StatelessWidget {
  const _AccountingImpactCard({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.fromLocal,
    required this.toLocal,
    required this.difference,
    required this.accounts,
    required this.fromAccountId,
    required this.toAccountId,
    required this.differenceAccountId,
    required this.hasDifference,
    required this.onDifferenceAccount,
  });

  final CurrencyEntity? fromCurrency, toCurrency;
  final double fromAmount, toAmount, fromLocal, toLocal, difference;
  final List<Map<String, dynamic>> accounts;
  final int? fromAccountId, toAccountId, differenceAccountId;
  final bool hasDifference;
  final ValueChanged<int?> onDifferenceAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfit = difference > 0.005;
    final isLoss = difference < -0.005;
    final diffAbs = difference.abs();

    String fromAccountName = 'حساب العملة المباعة';
    String toAccountName = 'حساب العملة المشتراة';
    for (final a in accounts) {
      if (a['id'] == fromAccountId) fromAccountName = a['name'] as String;
      if (a['id'] == toAccountId) toAccountName = a['name'] as String;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'المعاينة والأثر المحاسبي التلقائي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (fromAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: hasDifference
                          ? (isProfit ? AppColors.emerald50 : AppColors.rose50)
                          : AppColors.sky50,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      hasDifference
                          ? (isProfit
                                ? 'أرباح فروق صرف (+${diffAbs.toStringAsFixed(2)})'
                                : 'خسائر فروق صرف (-${diffAbs.toStringAsFixed(2)})')
                          : 'متطابق بدون فروق عملة ✅',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasDifference
                            ? (isProfit
                                  ? AppColors.emerald700
                                  : AppColors.rose700)
                            : AppColors.sky100,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Financial Breakdown Table
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  _BreakdownRow(
                    label: 'القيمة المسحوبة (بالمحلي):',
                    value:
                        '${fromLocal.toStringAsFixed(2)} ${fromCurrency?.isLocalCurrency == true ? fromCurrency?.code : 'محلي'}',
                    color: AppColors.rose700,
                  ),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: 'القيمة المستلمة (بالمحلي):',
                    value:
                        '${toLocal.toStringAsFixed(2)} ${toCurrency?.isLocalCurrency == true ? toCurrency?.code : 'محلي'}',
                    color: AppColors.emerald700,
                  ),
                  if (hasDifference) ...[
                    const Divider(height: 16),
                    _BreakdownRow(
                      label: isProfit
                          ? 'صافي أرباح فروق الصرف (دائن):'
                          : 'صافي خسائر فروق الصرف (مدين):',
                      value: '${diffAbs.toStringAsFixed(2)} محلي',
                      color: isProfit
                          ? AppColors.emerald700
                          : AppColors.rose700,
                      isBold: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Live Journal Entry Lines Preview
            const Text(
              'أسطر القيد المتولد:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Debit Line
                  Text(
                    '🟢 من حـ/ $toAccountName (مدين): ${toLocal.toStringAsFixed(2)} محلي (${toAmount.toStringAsFixed(2)} ${toCurrency?.code ?? ''})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isLoss && hasDifference)
                    Text(
                      '🔴 من حـ/ خسائر فروق صرف العملات (مدين): ${diffAbs.toStringAsFixed(2)} محلي',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.rose700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // Credit Line
                  Text(
                    '🔴 إلى حـ/ $fromAccountName (دائن): ${fromLocal.toStringAsFixed(2)} محلي (${fromAmount.toStringAsFixed(2)} ${fromCurrency?.code ?? ''})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isProfit && hasDifference)
                    Text(
                      '🟢 إلى حـ/ أرباح فروق صرف العملات (دائن): ${diffAbs.toStringAsFixed(2)} محلي',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.emerald700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            if (hasDifference) ...[
              const SizedBox(height: 14),
              CustomDropdownField<int>(
                label: 'حساب أرباح/خسائر فروق الصرف (مطلوب عند وجود فروق)',
                value: differenceAccountId,
                items: accounts
                    .map(
                      (a) => DropdownMenuItem<int>(
                        value: a['id'] as int,
                        child: Text(
                          '${a['code']} - ${a['name']}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onDifferenceAccount,
                validator: (v) {
                  if (hasDifference && v == null) {
                    return 'يرجى اختيار حساب فروق الصرف لتوجيه الفرق إليه';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DateAndNotesCard extends StatelessWidget {
  const _DateAndNotesCard({
    required this.date,
    required this.notesController,
    required this.onDate,
  });

  final DateTime date;
  final TextEditingController notesController;
  final ValueChanged<DateTime> onDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) onDate(picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ عملية الصرف',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              controller: notesController,
              label: 'ملاحظات / تفاصيل إضافية',
              hint: 'اكتب أي ملاحظات خاصة بالعملية...',
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isLoading,
    required this.onClear,
    required this.onSave,
  });

  final bool isLoading;
  final VoidCallback onClear, onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onClear,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة تعيين'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: HasibButton(
            label: isLoading ? 'جاري الحفظ والترحيل...' : 'حفظ عملية الصرف',
            onPressed: isLoading ? null : onSave,
            loading: isLoading,
            variant: HasibButtonVariant.primary,
            leading: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
