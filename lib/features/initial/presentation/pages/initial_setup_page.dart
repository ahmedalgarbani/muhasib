import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/features/initial/presentation/cubit/initial_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  int currentStep = 0;

  final _companyName = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyTaxNumber = TextEditingController();

  CurrencyEntity? _selectedCurrency;
  WarehouseEntity? _selectedWarehouse;
  bool _taxEnabled = true;
  final _taxRate = TextEditingController(text: '15');
  final _currencyCode = TextEditingController(text: 'SAR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrenciesCubit>().loadAllCurrencies();
      context.read<WarehousesCubit>().loadWarehouses();
      context.read<SettingsCubit>().loadSettings();
    });
  }

  @override
  void dispose() {
    _companyName.dispose();
    _companyPhone.dispose();
    _companyTaxNumber.dispose();
    _taxRate.dispose();
    _currencyCode.dispose();
    super.dispose();
  }

  List<Step> _steps(BuildContext context) {
    return [
      Step(
        title: const Text('بيانات الشركة'),
        isActive: currentStep >= 0,
        state: currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            TextField(
              controller: _companyName,
              decoration: const InputDecoration(labelText: 'اسم الشركة'),
            ),
            TextField(
              controller: _companyPhone,
              decoration: const InputDecoration(labelText: 'هاتف الشركة'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _companyTaxNumber,
              decoration: const InputDecoration(labelText: 'الرقم الضريبي'),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('العملة الافتراضية'),
        isActive: currentStep >= 1,
        state: currentStep > 1 ? StepState.complete : StepState.indexed,
        content: BlocBuilder<CurrenciesCubit, CurrenciesState>(
          builder: (context, state) {
            if (state is CurrenciesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            List<CurrencyEntity> currencies = [];
            if (state is CurrenciesLoaded) currencies = state.currencies;
            if (currencies.isEmpty) {
              return TextField(
                controller: _currencyCode,
                decoration: const InputDecoration(
                  labelText: 'رمز العملة (مثال: SAR)',
                ),
              );
            } else {
              return DropdownButtonFormField<CurrencyEntity>(
                value: _selectedCurrency,
                items: currencies
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.code} - ${c.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCurrency = v),
                decoration: const InputDecoration(labelText: 'اختر العملة'),
              );
            }
          },
        ),
      ),
      Step(
        title: const Text('المخزن الافتراضي'),
        isActive: currentStep >= 2,
        state: currentStep > 2 ? StepState.complete : StepState.indexed,
        content: BlocBuilder<WarehousesCubit, WarehousesState>(
          builder: (context, state) {
            if (state is WarehousesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            List<WarehouseEntity> warehouses = [];
            if (state is WarehousesLoaded) warehouses = state.warehouses;
            return DropdownButtonFormField<WarehouseEntity>(
              value: _selectedWarehouse,
              items: warehouses
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedWarehouse = v),
              decoration: const InputDecoration(labelText: 'اختر المخزن'),
            );
          },
        ),
      ),
      Step(
        title: const Text('الضريبة'),
        isActive: currentStep >= 3,
        state: currentStep > 3 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: _taxEnabled,
              onChanged: (v) => setState(() => _taxEnabled = v),
              title: const Text('تفعيل الضريبة'),
            ),
            TextField(
              controller: _taxRate,
              decoration: const InputDecoration(labelText: 'نسبة الضريبة %'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _saveAndFinish() async {
    if (_companyName.text.trim().isEmpty) return;
    // If no currencies exist, allow manual code entry
    final chosenCurrencyCode =
        _selectedCurrency?.code ?? _currencyCode.text.trim();
    if (chosenCurrencyCode.isEmpty) return;
    if (_selectedWarehouse == null) return;

    // Persist via SettingsCubit (data layer abstraction)
    final settingsCubit = context.read<SettingsCubit>();

    // Read existing values to merge
    final personalInfo = {
      ...settingsCubit.getPersonalInfo(),
      'name': _companyName.text.trim(),
      'phone': _companyPhone.text.trim(),
      'taxNo': _companyTaxNumber.text.trim(),
    };

    final otherSetting = {
      ...settingsCubit.getOtherSettings(),
      'default_currency': chosenCurrencyCode,
    };

    final stockSetting = {
      ...settingsCubit.getStockSettings(),
      'default_warehouse': _selectedWarehouse!.id ?? 1,
      'tax_enabled': _taxEnabled,
      'default_tax_rate': double.tryParse(_taxRate.text.trim()) ?? 0,
    };

    await settingsCubit.updateMultipleSettings({
      'personal_info': personalInfo,
      'other_setting': otherSetting,
      'stock_setting': stockSetting,
    });

    await context.read<InitialCubit>().markSetupComplete();

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعداد الأولي')),
      body: Stepper(
        currentStep: currentStep,
        onStepContinue: () async {
          if (currentStep == _steps(context).length - 1) {
            await _saveAndFinish();
          } else {
            setState(() => currentStep += 1);
          }
        },
        onStepCancel: () {
          if (currentStep > 0) setState(() => currentStep -= 1);
        },
        steps: _steps(context),
        controlsBuilder: (context, details) {
          final isLast = currentStep == _steps(context).length - 1;
          return Row(
            children: [
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: Text(isLast ? 'إنهاء' : 'التالي'),
              ),
              const SizedBox(width: 8),
              if (currentStep > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('رجوع'),
                ),
            ],
          );
        },
      ),
    );
  }
}
