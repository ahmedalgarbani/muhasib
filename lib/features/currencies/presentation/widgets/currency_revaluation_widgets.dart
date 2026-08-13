import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class RevaluationInfoCard extends StatelessWidget {
  const RevaluationInfoCard({super.key});
  @override
  Widget build(BuildContext context) => CustomCardContainer(
    elevation: 0,
    color: AppColors.info.withOpacity(0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: AppColors.info.withOpacity(0.2)),
    ),
    child: Padding(
      padding: AppConstant.defaultPadding,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ما هي إعادة التقييم؟',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
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

class RevaluationSelectionCard extends StatelessWidget {
  const RevaluationSelectionCard({
    super.key,
    required this.currencies,
    required this.accounts,
    required this.selectedCurrencyId,
    required this.selectedAccountId,
    required this.gainLossAccountId,
    required this.onCurrencyChanged,
    required this.onAccountChanged,
    required this.onGainLossChanged,
  });
  final List<Map<String, dynamic>> currencies, accounts;
  final int? selectedCurrencyId, selectedAccountId, gainLossAccountId;
  final ValueChanged<int?> onCurrencyChanged,
      onAccountChanged,
      onGainLossChanged;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تحديد الحساب والعملة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        CustomDropdownField<int>(
          label: 'العملة الأجنبية',
          value: selectedCurrencyId,
          prefixIcon: const Icon(Icons.monetization_on, color: AppColors.info),
          items: currencies
              .map(
                (c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(
                    '${c['name']} (${c['code']}) - سعر: ${c['exchange_rate']}',
                  ),
                ),
              )
              .toList(),
          onChanged: onCurrencyChanged,
          validator: (v) => v == null ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<int>(
          label: 'الحساب',
          value: selectedAccountId,
          prefixIcon: const Icon(
            Icons.account_balance_wallet,
            color: AppColors.info,
          ),
          items: accounts
              .map(
                (a) => DropdownMenuItem<int>(
                  value: a['id'] as int,
                  child: Text('${a['code']} - ${a['name']}'),
                ),
              )
              .toList(),
          onChanged: onAccountChanged,
          validator: (v) => v == null ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        CustomDropdownField<int>(
          label: 'حساب أرباح/خسائر فروق الصرف',
          value: gainLossAccountId,
          prefixIcon: const Icon(Icons.swap_horiz, color: AppColors.info),
          items: accounts
              .where(
                (a) => (a['type'] as int?) == 3 || (a['type'] as int?) == 4,
              )
              .map(
                (a) => DropdownMenuItem<int>(
                  value: a['id'] as int,
                  child: Text('${a['code']} - ${a['name']}'),
                ),
              )
              .toList(),
          onChanged: onGainLossChanged,
          validator: (v) => v == null ? 'مطلوب' : null,
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomCardContainer(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: Theme.of(context).dividerColor),
    ),
    child: Padding(padding: AppConstant.defaultPadding, child: child),
  );
}

class RevaluationRateCard extends StatelessWidget {
  const RevaluationRateCard({
    super.key,
    required this.currentRate,
    required this.controller,
    required this.date,
    required this.onRateChanged,
    required this.onDateChanged,
  });
  final double? currentRate;
  final TextEditingController controller;
  final DateTime date;
  final VoidCallback onRateChanged;
  final ValueChanged<DateTime> onDateChanged;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سعر الصرف الجديد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (currentRate != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          label: 'سعر الصرف الجديد',
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.trending_up, color: AppColors.info),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onChanged: (_) => onRateChanged(),
          validator: (v) => v == null || v.isEmpty
              ? 'مطلوب'
              : double.tryParse(v) == null
              ? 'رقم غير صالح'
              : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) onDateChanged(picked);
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
            child: Text(DateFormatter.formatDate(date)),
          ),
        ),
      ],
    ),
  );
}

class RevaluationDifferenceCard extends StatelessWidget {
  const RevaluationDifferenceCard({super.key, required this.difference});
  final double difference;
  @override
  Widget build(BuildContext context) {
    final isProfit = difference > 0;
    return CustomCardContainer(
      elevation: 0,
      color: (isProfit ? Colors.green : Colors.red).withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: (isProfit ? Colors.green : Colors.red).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
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
                        difference.abs().toStringAsFixed(2),
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
}

class RevaluationActionButtons extends StatelessWidget {
  const RevaluationActionButtons({
    super.key,
    required this.isLoading,
    required this.canSave,
    required this.onClear,
    required this.onSave,
  });
  final bool isLoading, canSave;
  final VoidCallback onClear, onSave;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear),
          label: const Text('مسح'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: HasibButton(
          label: isLoading ? 'جاري الحفظ...' : 'إنشاء قيد التسوية',
          onPressed: isLoading || !canSave ? null : onSave,
          leading: const Icon(Icons.save),
          loading: isLoading,
          variant: HasibButtonVariant.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ],
  );
}
