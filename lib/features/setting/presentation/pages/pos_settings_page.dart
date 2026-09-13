import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_dropdown_tile.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/core/widgets/settings_text_field_tile.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class PosSettingsPage extends StatefulWidget {
  const PosSettingsPage({super.key});

  @override
  State<PosSettingsPage> createState() => _PosSettingsPageState();
}

class _PosSettingsPageState extends State<PosSettingsPage> {
  late Map<String, dynamic> posSettings;

  String defaultPaymentMethod = 'cash';
  String defaultCustomerName = '';
  final TextEditingController maxDiscountController = TextEditingController();
  final TextEditingController defaultCreditLimitController =
      TextEditingController();
  bool allowSplitPayment = true;
  bool allowDiscountPerLine = true;
  bool cashRoundingEnabled = false;
  double cashRoundingPrecision = 0.05;
  bool barcodeEnabled = true;
  bool showBarcodeScanner = false;
  bool enableStockAlerts = true;
  bool enableCustomerCredit = false;
  bool blockCustomerOverLimit = false;

  @override
  void initState() {
    super.initState();
    posSettings = context.read<SettingsCubit>().getPosSettings();

    defaultPaymentMethod =
        posSettings['default_payment_method']?.toString() ?? 'cash';
    defaultCustomerName = posSettings['default_customer']?.toString() ?? '';
    final maxDiscount = posSettings['max_discount_percent'];
    maxDiscountController.text = maxDiscount == null ? '' : '$maxDiscount';
    allowSplitPayment = posSettings['allow_split_payment'] ?? true;
    allowDiscountPerLine = posSettings['allow_discount_per_line'] ?? true;
    cashRoundingEnabled = posSettings['cash_rounding_enabled'] ?? false;
    cashRoundingPrecision =
        (posSettings['cash_rounding_precision'] ?? 0.05).toDouble();
    barcodeEnabled = posSettings['barcode_enabled'] ?? true;
    showBarcodeScanner = posSettings['show_barcode_scanner'] ?? false;
    enableStockAlerts = posSettings['enable_stock_alerts'] ?? true;
    enableCustomerCredit = posSettings['enable_customer_credit'] ?? false;
    blockCustomerOverLimit = posSettings['block_customer_over_limit'] ?? false;
    defaultCreditLimitController.text =
        (posSettings['default_credit_limit'] ?? 0).toString();
  }

  @override
  void dispose() {
    maxDiscountController.dispose();
    defaultCreditLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();

    final maxDiscountText = maxDiscountController.text.trim();
    final maxDiscount =
        maxDiscountText.isEmpty ? null : double.tryParse(maxDiscountText);
    if (maxDiscountText.isNotEmpty && maxDiscount == null) {
      AppToast.showError(context, 'أدخل نسبة خصم صحيحة');
      return;
    }

    final creditLimit =
        double.tryParse(defaultCreditLimitController.text.trim()) ?? 0;

    final settings = {
      'default_payment_method': defaultPaymentMethod,
      'default_customer': defaultCustomerName,
      'max_discount_percent': maxDiscount,
      'allow_discount_per_line': allowDiscountPerLine,
      'allow_split_payment': allowSplitPayment,
      'cash_rounding_enabled': cashRoundingEnabled,
      'cash_rounding_precision': cashRoundingPrecision,
      'barcode_enabled': barcodeEnabled,
      'show_barcode_scanner': showBarcodeScanner,
      'enable_stock_alerts': enableStockAlerts,
      'enable_customer_credit': enableCustomerCredit,
      'default_credit_limit': creditLimit,
      'block_customer_over_limit': blockCustomerOverLimit,
    };

    await cubit.updateSetting('pos_setting', settings);

    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'إعدادات نقاط البيع'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('الدفع والخصومات'),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<String>(
                      title: 'طريقة الدفع الافتراضية',
                      value: defaultPaymentMethod,
                      icon: Icons.payments_outlined,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                        DropdownMenuItem(
                          value: 'bank',
                          child: Text('شبكة / بنك'),
                        ),
                        DropdownMenuItem(value: 'deferred', child: Text('آجل')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          defaultPaymentMethod = value!;
                        });
                      },
                    ),
                    const Divider(),
                    BlocBuilder<CustomersCubit, CustomersState>(
                      builder: (context, state) {
                        final names = state is CustomersLoaded
                            ? state.customers.map((c) => c.name).toList()
                            : <String>[];
                        if (defaultCustomerName.isNotEmpty &&
                            !names.contains(defaultCustomerName)) {
                          names.insert(0, defaultCustomerName);
                        }
                        return SettingsDropdownTile<String>(
                          title: 'العميل الافتراضي',
                          value: defaultCustomerName.isEmpty
                              ? null
                              : defaultCustomerName,
                          icon: Icons.person_outline,
                          items: names
                              .map(
                                (name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              defaultCustomerName = value ?? '';
                            });
                          },
                        );
                      },
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'الحد الأقصى لنسبة الخصم %',
                      controller: maxDiscountController,
                      hintText: 'اتركه فارغاً لعدم التقيد بحد',
                      icon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'السماح بالخصم على مستوى الصنف',
                      icon: Icons.percent,
                      value: allowDiscountPerLine,
                      onChanged: (value) {
                        setState(() {
                          allowDiscountPerLine = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'السماح بالدفع المقسم',
                      icon: Icons.call_split_rounded,
                      value: allowSplitPayment,
                      onChanged: (value) {
                        setState(() {
                          allowSplitPayment = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'تقريب المبالغ النقدية',
                      icon: Icons.calculate_outlined,
                      value: cashRoundingEnabled,
                      onChanged: (value) {
                        setState(() {
                          cashRoundingEnabled = value;
                        });
                      },
                    ),
                    if (cashRoundingEnabled) ...[
                      const Divider(),
                      SettingsDropdownTile<double>(
                        title: 'أقرب مبلغ للتقريب',
                        value: cashRoundingPrecision,
                        icon: Icons.money,
                        items: const [
                          DropdownMenuItem(value: 0.01, child: Text('0.01')),
                          DropdownMenuItem(value: 0.05, child: Text('0.05')),
                          DropdownMenuItem(value: 0.1, child: Text('0.10')),
                          DropdownMenuItem(value: 0.25, child: Text('0.25')),
                          DropdownMenuItem(value: 0.5, child: Text('0.50')),
                          DropdownMenuItem(value: 1.0, child: Text('1.00')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            cashRoundingPrecision = value!;
                          });
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _sectionLabel('الباركود والمخزون'),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      title: 'تفعيل الباركود',
                      icon: Icons.qr_code_2_rounded,
                      value: barcodeEnabled,
                      onChanged: (value) {
                        setState(() {
                          barcodeEnabled = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'فتح الماسح الضوئي تلقائياً (الجوال)',
                      icon: Icons.qr_code_scanner_rounded,
                      value: showBarcodeScanner,
                      enabled: barcodeEnabled,
                      onChanged: (value) {
                        setState(() {
                          showBarcodeScanner = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'تنبيهات الكمية في المخزون',
                      icon: Icons.inventory_2_outlined,
                      value: enableStockAlerts,
                      onChanged: (value) {
                        setState(() {
                          enableStockAlerts = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionLabel('ائتمان العملاء'),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      title: 'تفعيل التحقق من حد الائتمان',
                      icon: Icons.credit_score_outlined,
                      value: enableCustomerCredit,
                      onChanged: (value) {
                        setState(() {
                          enableCustomerCredit = value;
                        });
                      },
                    ),
                    if (enableCustomerCredit) ...[
                      const Divider(),
                      SettingsTextFieldTile(
                        title: 'حد الائتمان الافتراضي',
                        controller: defaultCreditLimitController,
                        hintText: '0 = بدون حد',
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const Divider(),
                      SettingsSwitchTile(
                        title: 'منع البيع عند تجاوز حد الائتمان',
                        icon: Icons.block,
                        value: blockCustomerOverLimit,
                        onChanged: (value) {
                          setState(() {
                            blockCustomerOverLimit = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                HasibButton(
                  label: 'حفظ التغييرات',
                  onPressed: _saveSettings,
                  variant: HasibButtonVariant.primary,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
