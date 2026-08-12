import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/custom_switch_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
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
        title: const Text('بيانات الشركة', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('إدخال المعلومات الأساسية للمنشأة'),
        isActive: currentStep >= 0,
        state: currentStep > 0 ? StepState.complete : StepState.indexed,
        content: CustomCardContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextInputField(
                label: 'اسم الشركة / المنشأة',
                hint: 'أدخل اسم الشركة',
                isRequired: true,
                textEditingController: _companyName,
                prefixIcon: const Icon(Icons.business),
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'هاتف الشركة',
                hint: 'أدخل رقم الهاتف',
                textEditingController: _companyPhone,
                inputType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'الرقم الضريبي',
                hint: 'أدخل الرقم الضريبي (إن وجد)',
                textEditingController: _companyTaxNumber,
                prefixIcon: const Icon(Icons.tag),
              ),
            ],
          ),
        ),
      ),
      Step(
        title: const Text('العملة الافتراضية', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('تحديد عملة النظام الرئيسية'),
        isActive: currentStep >= 1,
        state: currentStep > 1 ? StepState.complete : StepState.indexed,
        content: CustomCardContainer(
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<CurrenciesCubit, CurrenciesState>(
            builder: (context, state) {
              if (state is CurrenciesLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              List<CurrencyEntity> currencies = [];
              if (state is CurrenciesLoaded) currencies = state.currencies;
              if (currencies.isEmpty) {
                return TextInputField(
                  label: 'رمز العملة الرئيسية',
                  hint: 'مثال: SAR',
                  textEditingController: _currencyCode,
                  prefixIcon: const Icon(Icons.monetization_on),
                );
              } else {
                return CustomDropdownField<CurrencyEntity>(
                  label: 'اختر العملة الرئيسية',
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
                  prefixIcon: const Icon(Icons.monetization_on),
                );
              }
            },
          ),
        ),
      ),
      Step(
        title: const Text('المخزن الافتراضي', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('تحديد المستودع الرئيسي لعمليات المخزون'),
        isActive: currentStep >= 2,
        state: currentStep > 2 ? StepState.complete : StepState.indexed,
        content: CustomCardContainer(
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<WarehousesCubit, WarehousesState>(
            builder: (context, state) {
              if (state is WarehousesLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              List<WarehouseEntity> warehouses = [];
              if (state is WarehousesLoaded) warehouses = state.warehouses;
              return CustomDropdownField<WarehouseEntity>(
                label: 'اختر المخزن الرئيسي',
                value: _selectedWarehouse,
                items: warehouses
                    .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedWarehouse = v),
                prefixIcon: const Icon(Icons.warehouse),
              );
            },
          ),
        ),
      ),
      Step(
        title: const Text('إعدادات الضريبة', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('تفعيل وتحديد نسبة القيمة المضافة'),
        isActive: currentStep >= 3,
        state: currentStep > 3 ? StepState.complete : StepState.indexed,
        content: CustomCardContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomSwitchTile(
                title: 'تفعيل ضريبة القيمة المضافة',
                subtitle: 'احتساب الضريبة التلقائية في الفواتير',
                icon: Icons.receipt,
                value: _taxEnabled,
                onChanged: (v) => setState(() => _taxEnabled = v),
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'نسبة الضريبة %',
                hint: '15',
                textEditingController: _taxRate,
                inputType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.percent),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _saveAndFinish() async {
    if (_companyName.text.trim().isEmpty) return;
    final chosenCurrencyCode =
        _selectedCurrency?.code ?? _currencyCode.text.trim();
    if (chosenCurrencyCode.isEmpty) return;
    if (_selectedWarehouse == null) return;

    final settingsCubit = context.read<SettingsCubit>();

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(title: 'معالج الإعداد الأولي للنظام'),
        body: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: Stepper(
            type: StepperType.vertical,
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
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: HasibButton(
                        label: isLast ? 'إنهاء وحفظ الإعدادات' : 'متابعة الخطوة التالية',
                        onPressed: details.onStepContinue,
                        variant: HasibButtonVariant.primary,
                      ),
                    ),
                    if (currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: HasibButton(
                          label: 'الخطوة السابقة',
                          onPressed: details.onStepCancel,
                          variant: HasibButtonVariant.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
