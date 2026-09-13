import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
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
  bool _isSaving = false;

  final _companyName = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyTaxNumber = TextEditingController();

  CurrencyEntity? _selectedCurrency;
  WarehouseEntity? _selectedWarehouse;
  bool _taxEnabled = true;
  final _taxRate = TextEditingController(text: '15');
  final _currencyCode = TextEditingController(text: 'SAR');

  final List<Map<String, dynamic>> _stepMeta = const [
    {
      'title': 'بيانات المنشأة',
      'subtitle': 'المعلومات الأساسية لنشاطك التجاري',
      'icon': Icons.business_rounded,
    },
    {
      'title': 'العملة الرئيسية',
      'subtitle': 'عملة الحسابات والتقارير المالية',
      'icon': Icons.payments_rounded,
    },
    {
      'title': 'المستودع الرئيسي',
      'subtitle': 'مستودع المخزون وعمليات البيع',
      'icon': Icons.warehouse_rounded,
    },
    {
      'title': 'إعدادات الضريبة',
      'subtitle': 'تحديد نسبة ضريبة القيمة المضافة',
      'icon': Icons.receipt_long_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsCubit = context.read<SettingsCubit>();
      await settingsCubit.loadSettings();

      final personal = settingsCubit.getPersonalInfo();
      final other = settingsCubit.getOtherSettings();
      final stock = settingsCubit.getStockSettings();

      if (mounted) {
        setState(() {
          if (_companyName.text.isEmpty && personal['name'] != null) {
            _companyName.text = personal['name'].toString();
          }
          if (_companyPhone.text.isEmpty && personal['phone'] != null) {
            _companyPhone.text = personal['phone'].toString();
          }
          if (_companyTaxNumber.text.isEmpty && personal['taxNo'] != null) {
            _companyTaxNumber.text = personal['taxNo'].toString();
          }
          if (other['default_currency'] != null) {
            _currencyCode.text = other['default_currency'].toString();
          }
          if (stock['tax_enabled'] != null) {
            _taxEnabled = stock['tax_enabled'] == true;
          }
          if (stock['default_tax_rate'] != null) {
            _taxRate.text = stock['default_tax_rate'].toString();
          }
        });
      }

      if (mounted) {
        context.read<CurrenciesCubit>().loadAllCurrencies();
        context.read<WarehousesCubit>().loadWarehouses();
      }
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

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_companyName.text.trim().isEmpty) {
          AppToast.showWarning(
            context,
            'يرجى إدخال اسم الشركة أو المنشأة للمتابعة',
          );
          return false;
        }
        return true;
      case 1:
        final code = _selectedCurrency?.code ?? _currencyCode.text.trim();
        if (code.isEmpty) {
          AppToast.showWarning(context, 'يرجى تحديد العملة الرئيسية للمتابعة');
          return false;
        }
        return true;
      case 2:
        if (_selectedWarehouse == null) {
          AppToast.showWarning(
            context,
            'يرجى اختيار المستودع الرئيسي للمتابعة',
          );
          return false;
        }
        return true;
      case 3:
        if (_taxEnabled) {
          final rate = double.tryParse(_taxRate.text.trim());
          if (rate == null || rate < 0) {
            AppToast.showWarning(context, 'يرجى إدخال نسبة ضريبة صحيحة');
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep(currentStep)) return;
    if (currentStep < _stepMeta.length - 1) {
      setState(() => currentStep += 1);
    } else {
      _saveAndFinish();
    }
  }

  void _prevStep() {
    if (currentStep > 0) {
      setState(() => currentStep -= 1);
    }
  }

  Future<void> _saveAndFinish() async {
    if (!_validateStep(currentStep)) return;

    final chosenCurrencyCode =
        _selectedCurrency?.code ?? _currencyCode.text.trim();
    if (chosenCurrencyCode.isEmpty) {
      AppToast.showWarning(context, 'يرجى اختيار العملة الرئيسية');
      return;
    }
    if (_selectedWarehouse == null) {
      AppToast.showWarning(context, 'يرجى اختيار المستودع الرئيسي');
      return;
    }

    setState(() => _isSaving = true);

    try {
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

      if (!mounted) return;
      await context.read<InitialCubit>().markSetupComplete();

      if (!mounted) return;
      AppToast.showSuccess(context, 'تم حفظ إعدادات النظام بنجاح!');

      if (Navigator.canPop(context)) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'حدث خطأ أثناء حفظ الإعدادات: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildStepProgressBar(bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isSmall) ...[
            // Compact Header for Mobile
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _stepMeta[currentStep]['icon'] as IconData,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الخطوة ${currentStep + 1} من ${_stepMeta.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stepMeta[currentStep]['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm10),
                  ),
                  child: Text(
                    '${((currentStep + 1) / _stepMeta.length * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: LinearProgressIndicator(
                value: (currentStep + 1) / _stepMeta.length,
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ] else ...[
            // Full Width Stepper for Tablet / Desktop
            Row(
              children: List.generate(_stepMeta.length, (index) {
                final isCompleted = index < currentStep;
                final isActive = index == currentStep;
                final meta = _stepMeta[index];

                final circleColor = isActive
                    ? AppColors.primary
                    : isCompleted
                    ? AppColors.success
                    : Theme.of(context).dividerColor;

                final textColor = isActive
                    ? AppColors.primary
                    : isCompleted
                    ? AppColors.success
                    : Theme.of(context).colorScheme.onSurfaceVariant;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: index <= currentStep
                              ? () => setState(() => currentStep = index)
                              : null,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isActive || isCompleted
                                      ? circleColor
                                      : Theme.of(context).colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: circleColor,
                                    width: 2,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.white
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(
                                        meta['title'] as String,
                                        style: TextStyle(
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: textColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isActive
                                          ? 'جارٍ الإعداد'
                                          : isCompleted
                                          ? 'مكتمل'
                                          : 'قادم',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < _stepMeta.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 16,
                            height: 2,
                            color: isCompleted
                                ? AppColors.success
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep0CompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'بيانات المنشأة أو الشركة',
          description:
              'أدخل الاسم والمعلومات الأساسية لمنشأتك، ستظهر هذه البيانات تلقائياً في ترويسة الفواتير والسندات.',
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        CustomCardContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextInputField(
                label: 'اسم الشركة / المنشأة',
                hint: 'أدخل الاسم التجاري للمنشأة',
                isRequired: true,
                textEditingController: _companyName,
                prefixIcon: const Icon(Icons.business_rounded),
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'هاتف المنشأة / التواصل',
                hint: 'مثال: 05XXXXXXXX أو 966XXXXXXXXX',
                textEditingController: _companyPhone,
                inputType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'الرقم الضريبي للمنشأة',
                hint: 'أدخل الرقم الضريبي (15 خانة إن وجد)',
                textEditingController: _companyTaxNumber,
                inputType: TextInputType.number,
                prefixIcon: const Icon(Icons.tag_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Currency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'العملة الأساسية للنظام',
          description:
              'حدد العملة الافتراضية التي سيتم استخدامها في إدخال الفواتير والحسابات وقوائم الأسعار والتقارير.',
          icon: Icons.payments_rounded,
        ),
        const SizedBox(height: 16),
        CustomCardContainer(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<CurrenciesCubit, CurrenciesState>(
            builder: (context, state) {
              if (state is CurrenciesLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              List<CurrencyEntity> currencies = [];
              if (state is CurrenciesLoaded) {
                currencies = state.currencies;
              }

              if (currencies.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextInputField(
                      label: 'رمز العملة الرئيسية',
                      hint: 'مثال: SAR',
                      isRequired: true,
                      textEditingController: _currencyCode,
                      prefixIcon: const Icon(Icons.monetization_on_rounded),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لم يتم العثور على عملات مسجلة مسبقاً، يرجى كتابة رمز العملة وسيقوم النظام بتهيئتها.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }

              // Auto-select currency if none selected
              if (_selectedCurrency == null) {
                final match = currencies.firstWhere(
                  (c) =>
                      c.code.toUpperCase() ==
                      _currencyCode.text.trim().toUpperCase(),
                  orElse: () => currencies.first,
                );
                _selectedCurrency = match;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDropdownField<CurrencyEntity>(
                    label: 'اختر العملة الرئيسية',
                    hint: 'حدد العملة من القائمة',
                    isRequired: true,
                    value: _selectedCurrency,
                    items: currencies
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.code} - ${c.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCurrency = v;
                        if (v != null) {
                          _currencyCode.text = v.code;
                        }
                      });
                    },
                    prefixIcon: const Icon(Icons.monetization_on_rounded),
                  ),
                  if (_selectedCurrency != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'العملة المحددة: ${_selectedCurrency!.name} (${_selectedCurrency!.code})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Warehouse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'المستودع / المخزن الرئيسي',
          description:
              'حدد المستودع الافتراضي لعمليات المخزون وتوريد وصرف الأصناف في فواتير البيع والشراء.',
          icon: Icons.warehouse_rounded,
        ),
        const SizedBox(height: 16),
        CustomCardContainer(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<WarehousesCubit, WarehousesState>(
            builder: (context, state) {
              if (state is WarehousesLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              List<WarehouseEntity> warehouses = [];
              if (state is WarehousesLoaded) {
                warehouses = state.warehouses;
              }

              if (warehouses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'لا يوجد مستودعات مسجلة في النظام حالياً.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'سيتم اعتماد المستودع الافتراضي تلقائياً عند حفظ الإعدادات.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Auto-select first warehouse if none selected
              _selectedWarehouse ??= warehouses.first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDropdownField<WarehouseEntity>(
                    label: 'اختر المستودع الرئيسي',
                    hint: 'حدد المستودع من القائمة',
                    isRequired: true,
                    value: _selectedWarehouse,
                    items: warehouses
                        .map(
                          (w) =>
                              DropdownMenuItem(value: w, child: Text(w.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedWarehouse = v),
                    prefixIcon: const Icon(Icons.warehouse_rounded),
                  ),
                  if (_selectedWarehouse != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'المستودع المعتمد: ${_selectedWarehouse!.name}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Tax() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'إعدادات الضريبة (VAT)',
          description:
              'تفعيل أو تعطيل ضريبة القيمة المضافة وتحديد النسبة الافتراضية المطبقة على العمليات والفواتير.',
          icon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 16),
        CustomCardContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomSwitchTile(
                title: 'تفعيل ضريبة القيمة المضافة',
                subtitle: 'احتساب الضريبة التلقائية في فواتير البيع والشراء',
                icon: Icons.receipt_rounded,
                value: _taxEnabled,
                onChanged: (v) => setState(() => _taxEnabled = v),
              ),
              if (_taxEnabled) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),
                TextInputField(
                  label: 'نسبة الضريبة الافتراضية %',
                  hint: '15',
                  isRequired: true,
                  textEditingController: _taxRate,
                  inputType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: const Icon(Icons.percent_rounded),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'النسبة المعتمدة في المملكة العربية السعودية ومعظم دول الخليج هي 15%. يمكنك تعديل النسبة لكل صنف لاحقاً.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildStep0CompanyInfo();
      case 1:
        return _buildStep1Currency();
      case 2:
        return _buildStep2Warehouse();
      case 3:
        return _buildStep3Tax();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(bool isSmall) {
    final isLast = currentStep == _stepMeta.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              flex: isSmall ? 2 : 1,
              child: HasibButton(
                label: 'السابق',
                icon: Icons.arrow_forward_rounded,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                fontSize: 14,
                onPressed: _isSaving ? null : _prevStep,
                variant: HasibButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: currentStep > 0 ? (isSmall ? 3 : 2) : 1,
            child: HasibButton(
              label: isLast ? 'إنهاء وحفظ الإعدادات' : (isSmall ? 'التالي' : 'متابعة الخطوة التالية'),
              icon: isLast
                  ? Icons.check_circle_rounded
                  : Icons.arrow_back_rounded,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              fontSize: 14,
              onPressed: _isSaving ? null : _nextStep,
              loading: _isSaving,
              variant: isLast
                  ? HasibButtonVariant.success
                  : HasibButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'معالج التهيئة الأولية',
          showBack: Navigator.canPop(context),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 720;
            final horizontalPadding = isSmall ? 16.0 : 32.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStepProgressBar(isSmall),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey<int>(currentStep),
                                child: _buildStepContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(isSmall),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
