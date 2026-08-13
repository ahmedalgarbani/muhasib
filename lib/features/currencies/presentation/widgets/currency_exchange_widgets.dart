import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import '../../domain/entities/currency_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class CurrencyExchangeForm extends StatelessWidget {
  const CurrencyExchangeForm({
    super.key,
    required this.formKey,
    required this.currencies,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amountController,
    required this.resultController,
    required this.notesController,
    required this.selectedDate,
    required this.exchangeRate,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onAmountChanged,
    required this.onSwap,
    required this.onDateChanged,
    required this.onClear,
    required this.onSave,
    required this.transactions,
  });
  final GlobalKey<FormState> formKey;
  final List<CurrencyEntity> currencies;
  final CurrencyEntity? fromCurrency, toCurrency;
  final TextEditingController amountController,
      resultController,
      notesController;
  final DateTime selectedDate;
  final double exchangeRate;
  final ValueChanged<CurrencyEntity?> onFromChanged, onToChanged;
  final VoidCallback onAmountChanged, onSwap, onClear, onSave;
  final ValueChanged<DateTime> onDateChanged;
  final List<dynamic> transactions;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: AppConstant.defaultPadding,
    child: Form(
      key: formKey,
      child: Column(
        children: [
          CurrencyExchangeCard(
            currencies: currencies,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            amountController: amountController,
            resultController: resultController,
            onFromChanged: onFromChanged,
            onToChanged: onToChanged,
            onAmountChanged: onAmountChanged,
            onSwap: onSwap,
          ),
          const SizedBox(height: 16),
          CurrencyRateInfo(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            exchangeRate: exchangeRate,
          ),
          const SizedBox(height: 16),
          CurrencyDateNotes(
            selectedDate: selectedDate,
            notesController: notesController,
            onDateChanged: onDateChanged,
          ),
          const SizedBox(height: 24),
          CurrencyActionButtons(onClear: onClear, onSave: onSave),
          const SizedBox(height: 24),
          QuickExchangeRates(currencies: currencies),
        ],
      ),
    ),
  );
}

class CurrencyExchangeCard extends StatelessWidget {
  const CurrencyExchangeCard({
    super.key,
    required this.currencies,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amountController,
    required this.resultController,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onAmountChanged,
    required this.onSwap,
  });
  final List<CurrencyEntity> currencies;
  final CurrencyEntity? fromCurrency, toCurrency;
  final TextEditingController amountController, resultController;
  final ValueChanged<CurrencyEntity?> onFromChanged, onToChanged;
  final VoidCallback onAmountChanged, onSwap;
  @override
  Widget build(BuildContext context) => CustomCardContainer(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg20),
      side: BorderSide(color: Theme.of(context).dividerColor),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _CurrencyRow(
            label: 'من العملة',
            value: fromCurrency,
            currencies: currencies,
            controller: amountController,
            iconColor: AppColors.info,
            onChanged: onFromChanged,
            onTextChanged: onAmountChanged,
          ),
          const SizedBox(height: 16),
          IconButton(
            onPressed: onSwap,
            icon: const Icon(Icons.swap_vert, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          _CurrencyRow(
            label: 'إلى العملة',
            value: toCurrency,
            currencies: currencies,
            controller: resultController,
            iconColor: AppColors.success,
            onChanged: onToChanged,
            onTextChanged: () {},
            readOnly: true,
          ),
        ],
      ),
    ),
  );
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.label,
    required this.value,
    required this.currencies,
    required this.controller,
    required this.iconColor,
    required this.onChanged,
    required this.onTextChanged,
    this.readOnly = false,
  });
  final String label;
  final CurrencyEntity? value;
  final List<CurrencyEntity> currencies;
  final TextEditingController controller;
  final Color iconColor;
  final ValueChanged<CurrencyEntity?> onChanged;
  final VoidCallback onTextChanged;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 2,
        child: CustomDropdownField<CurrencyEntity>(
          value: value,
          label: label,
          prefixIcon: Icon(Icons.monetization_on, color: iconColor),
          items: currencies
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.name} (${c.code})'),
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
          keyboardType: TextInputType.number,
          label: readOnly ? 'الناتج' : 'المبلغ',
          onChanged: readOnly ? null : (_) => onTextChanged(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            filled: true,
          ),
        ),
      ),
    ],
  );
}

class CurrencyRateInfo extends StatelessWidget {
  const CurrencyRateInfo({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.exchangeRate,
  });
  final CurrencyEntity? fromCurrency, toCurrency;
  final double exchangeRate;
  @override
  Widget build(BuildContext context) =>
      fromCurrency == null || toCurrency == null
      ? const SizedBox()
      : Card(
          child: Padding(
            padding: AppConstant.defaultPadding,
            child: Text(
              '1 ${fromCurrency!.code} = ${exchangeRate.toStringAsFixed(4)} ${toCurrency!.code}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.info,
              ),
            ),
          ),
        );
}

class CurrencyDateNotes extends StatelessWidget {
  const CurrencyDateNotes({
    super.key,
    required this.selectedDate,
    required this.notesController,
    required this.onDateChanged,
  });
  final DateTime selectedDate;
  final TextEditingController notesController;
  final ValueChanged<DateTime> onDateChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: AppConstant.defaultPadding,
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
              if (picked != null) onDateChanged(picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'تاريخ العملية'),
              child: Text(DateFormatter.formatDate(selectedDate)),
            ),
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'ملاحظات',
            controller: notesController,
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}

class CurrencyActionButtons extends StatelessWidget {
  const CurrencyActionButtons({
    super.key,
    required this.onClear,
    required this.onSave,
  });
  final VoidCallback onClear, onSave;
  @override
  Widget build(BuildContext context) => Row(
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
          label: 'حفظ عملية التحويل',
          onPressed: onSave,
          leading: const Icon(Icons.save),
        ),
      ),
    ],
  );
}

class QuickExchangeRates extends StatelessWidget {
  const QuickExchangeRates({super.key, required this.currencies});
  final List<CurrencyEntity> currencies;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: AppConstant.defaultPadding,
      child: Column(
        children: [
          const Text('أسعار الصرف الحالية'),
          ...currencies
              .map(
                (c) => ListTile(
                  title: Text(c.name),
                  trailing: Text(c.exchangeRate.toStringAsFixed(4)),
                ),
              )
              .toList(),
        ],
      ),
    ),
  );
}
