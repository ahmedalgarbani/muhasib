import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
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
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: formKey,
      child: Column(
        children: [
          V2ExchangeCard(
            currencies: currencies,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            amountController: amountController,
            resultController: resultController,
            onFrom: onFromCurrency,
            onTo: onToCurrency,
            onSwap: onSwap,
            onAmount: onAmount,
          ),
          const SizedBox(height: 16),
          V2CustomRate(
            useCustomRate: useCustomRate,
            controller: customRateController,
            onToggle: onCustomRateToggle,
            onChanged: onCustomRate,
          ),
          const SizedBox(height: 16),
          V2Accounts(
            accounts: accounts,
            fromId: fromAccountId,
            toId: toAccountId,
            differenceId: differenceAccountId,
            onFrom: onFromAccount,
            onTo: onToAccount,
            onDifference: onDifferenceAccount,
          ),
          const SizedBox(height: 16),
          V2RateInfo(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: exchangeRate,
            amount: amountController.text,
            result: resultController.text,
          ),
          const SizedBox(height: 16),
          V2DateNotes(date: date, controller: notesController, onDate: onDate),
          const SizedBox(height: 24),
          V2Actions(isLoading: isLoading, onClear: onClear, onSave: onSave),
        ],
      ),
    ),
  );
}

class V2ExchangeCard extends StatelessWidget {
  const V2ExchangeCard({
    super.key,
    required this.currencies,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amountController,
    required this.resultController,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
    required this.onAmount,
  });
  final List<CurrencyEntity> currencies;
  final CurrencyEntity? fromCurrency, toCurrency;
  final TextEditingController amountController, resultController;
  final ValueChanged<CurrencyEntity?> onFrom, onTo;
  final VoidCallback onSwap, onAmount;
  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'تحويل العملات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _V2Row(
            label: 'من العملة (بيع)',
            value: fromCurrency,
            currencies: currencies,
            controller: amountController,
            onChanged: onFrom,
            onTextChanged: onAmount,
          ),
          const SizedBox(height: 16),
          IconButton(
            onPressed: onSwap,
            icon: const Icon(Icons.swap_vert, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          _V2Row(
            label: 'إلى العملة (شراء)',
            value: toCurrency,
            currencies: currencies,
            controller: resultController,
            onChanged: onTo,
            readOnly: true,
            onTextChanged: () => {},
          ),
        ],
      ),
    ),
  );
}

class _V2Row extends StatelessWidget {
  const _V2Row({
    required this.label,
    required this.value,
    required this.currencies,
    required this.controller,
    required this.onChanged,
    required this.onTextChanged,
    this.readOnly = false,
  });
  final String label;
  final CurrencyEntity? value;
  final List<CurrencyEntity> currencies;
  final TextEditingController controller;
  final ValueChanged<CurrencyEntity?> onChanged;
  final VoidCallback onTextChanged;
  final bool readOnly;
  @override
  Widget build(BuildContext c) => Row(
    children: [
      Expanded(
        flex: 2,
        child: CustomDropdownField<CurrencyEntity>(
          label: label,
          value: value,
          items: currencies
              .map(
                (x) => DropdownMenuItem(
                  value: x,
                  child: Text('${x.name} (${x.code})'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextInputField(
          controller: controller,
          readOnly: readOnly,
          label: readOnly ? 'الناتج' : 'المبلغ',
          onChanged: readOnly ? null : (_) => onTextChanged(),
        ),
      ),
    ],
  );
}

class V2CustomRate extends StatelessWidget {
  const V2CustomRate({
    super.key,
    required this.useCustomRate,
    required this.controller,
    required this.onToggle,
    required this.onChanged,
  });
  final bool useCustomRate;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: useCustomRate,
                onChanged: (v) => onToggle(v ?? false),
              ),
              const Text('استخدام سعر صرف مخصص'),
            ],
          ),
          if (useCustomRate)
            TextInputField(
              controller: controller,
              label: 'سعر الصرف المخصص',
              onChanged: onChanged,
            ),
        ],
      ),
    ),
  );
}

class V2Accounts extends StatelessWidget {
  const V2Accounts({
    super.key,
    required this.accounts,
    required this.fromId,
    required this.toId,
    required this.differenceId,
    required this.onFrom,
    required this.onTo,
    required this.onDifference,
  });
  final List<Map<String, dynamic>> accounts;
  final int? fromId, toId, differenceId;
  final ValueChanged<int?> onFrom, onTo, onDifference;
  @override
  Widget build(BuildContext c) {
    Widget field(String label, int? value, ValueChanged<int?> onChanged) {
      return CustomDropdownField<int>(
        label: label,
        value: value,
        items: accounts
            .map(
              (a) => DropdownMenuItem<int>(
                value: a['id'] as int,
                child: Text('${a['code']} - ${a['name']}'),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'مطلوب' : null,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الحسابات المحاسبية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            field('حساب العملة المباعة (دائن)', fromId, onFrom),
            const SizedBox(height: 16),
            field('حساب العملة المشتراة (مدين)', toId, onTo),
            const SizedBox(height: 16),
            field('حساب فروق الصرف (اختياري)', differenceId, onDifference),
          ],
        ),
      ),
    );
  }
}

class V2RateInfo extends StatelessWidget {
  const V2RateInfo({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.amount,
    required this.result,
  });
  final CurrencyEntity? fromCurrency, toCurrency;
  final double rate;
  final String amount, result;
  @override
  Widget build(BuildContext c) => fromCurrency == null || toCurrency == null
      ? const SizedBox()
      : Card(
          color: AppColors.info.withOpacity(.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '1 ${fromCurrency!.code} = ${rate.toStringAsFixed(4)} ${toCurrency!.code}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.info,
              ),
            ),
          ),
        );
}

class V2DateNotes extends StatelessWidget {
  const V2DateNotes({
    super.key,
    required this.date,
    required this.controller,
    required this.onDate,
  });
  final DateTime date;
  final TextEditingController controller;
  final ValueChanged<DateTime> onDate;
  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final p = await showDatePicker(
                context: c,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (p != null) onDate(p);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'تاريخ العملية'),
              child: Text(
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextInputField(controller: controller, label: 'ملاحظات', maxLines: 2),
        ],
      ),
    ),
  );
}

class V2Actions extends StatelessWidget {
  const V2Actions({
    super.key,
    required this.isLoading,
    required this.onClear,
    required this.onSave,
  });
  final bool isLoading;
  final VoidCallback onClear, onSave;
  @override
  Widget build(BuildContext c) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear),
          label: const Text('مسح'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: HasibButton(
          label: isLoading ? 'جاري الحفظ...' : 'حفظ عملية الصرف',
          onPressed: isLoading ? null : onSave,
          loading: isLoading,
          leading: const Icon(Icons.save),
        ),
      ),
    ],
  );
}
