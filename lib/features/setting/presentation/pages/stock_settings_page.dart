import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/core/widgets/settings_text_field_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

import 'package:muhasib/core/constant/app_constant.dart';

class StockSettingsPage extends StatefulWidget {
  const StockSettingsPage({super.key});

  @override
  State<StockSettingsPage> createState() => _StockSettingsPageState();
}

class _StockSettingsPageState extends State<StockSettingsPage> {
  late Map<String, dynamic> stockSettings;

  bool allowReturnWithoutInvoice = true;
  bool showCustomerBalanceInInvoice = false;
  bool preventWhenSaleLessThanCost = true;
  bool showCostAmountInInvoice = true;
  bool showCustomPhoneInInvoice = true;
  bool showCostAmountInCategoryWhenAddInvoice = true;
  bool showCostAmountInCategoryWhenAddInvoicePOS = false;
  bool checkFundAndBankBalanceEnabledInInvoice = false;
  bool isStockNegativeAllowed = false;
  bool taxEnabled = false;
  bool taxInclusivePricing = false;

  final TextEditingController invoicePrefixController = TextEditingController();
  final TextEditingController quotationPrefixController =
      TextEditingController();
  final TextEditingController returnPrefixController = TextEditingController();
  final TextEditingController invoiceStartingNumberController =
      TextEditingController();
  final TextEditingController taxNameController = TextEditingController();
  final TextEditingController taxRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    stockSettings = cubit.getStockSettings();

    allowReturnWithoutInvoice =
        stockSettings['allowReturnWithoutInvoice'] ?? true;
    showCustomerBalanceInInvoice =
        stockSettings['showCustomerBalanceInInvoice'] ?? false;
    preventWhenSaleLessThanCost =
        stockSettings['preventWhenSaleLessThanCost'] ?? true;
    showCostAmountInInvoice = stockSettings['showCoseAmountInInvoice'] ?? true;
    showCustomPhoneInInvoice = stockSettings['showCustomPhoneInInvoice'] ?? true;
    showCostAmountInCategoryWhenAddInvoice =
        stockSettings['showCostAmountInCategoryWhenAddInvoice'] ?? true;
    showCostAmountInCategoryWhenAddInvoicePOS =
        stockSettings['showCostAmountInCategoryWhenAddInvoicePOS'] ?? false;
    checkFundAndBankBalanceEnabledInInvoice =
        stockSettings['checkFundAndBankBalanceEnabledInInvoice'] ?? false;
    isStockNegativeAllowed = stockSettings['isStockNegativeAllowed'] ?? false;
    taxEnabled = stockSettings['tax_enabled'] ?? false;
    taxInclusivePricing = stockSettings['tax_inclusive_pricing'] ?? false;

    invoicePrefixController.text =
        stockSettings['invoice_prefix']?.toString() ?? 'INV-';
    quotationPrefixController.text =
        stockSettings['quotation_prefix']?.toString() ?? 'QUO-';
    returnPrefixController.text =
        stockSettings['return_prefix']?.toString() ?? 'RET-';
    invoiceStartingNumberController.text =
        (stockSettings['invoice_starting_number'] ?? 1000).toString();
    taxNameController.text =
        stockSettings['tax_name']?.toString() ?? 'ضريبة القيمة المضافة';
    taxRateController.text = (stockSettings['default_tax_rate'] ?? 15).toString();
  }

  @override
  void dispose() {
    invoicePrefixController.dispose();
    quotationPrefixController.dispose();
    returnPrefixController.dispose();
    invoiceStartingNumberController.dispose();
    taxNameController.dispose();
    taxRateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final stockSettings = {
      'allowReturnWithoutInvoice': allowReturnWithoutInvoice,
      'showCustomerBalanceInInvoice': showCustomerBalanceInInvoice,
      'preventWhenSaleLessThanCost': preventWhenSaleLessThanCost,
      'showCoseAmountInInvoice': showCostAmountInInvoice,
      'showCustomPhoneInInvoice': showCustomPhoneInInvoice,
      'showCostAmountInCategoryWhenAddInvoice':
          showCostAmountInCategoryWhenAddInvoice,
      'showCostAmountInCategoryWhenAddInvoicePOS':
          showCostAmountInCategoryWhenAddInvoicePOS,
      'checkFundAndBankBalanceEnabledInInvoice':
          checkFundAndBankBalanceEnabledInInvoice,
      'isStockNegativeAllowed': isStockNegativeAllowed,
      'invoice_prefix': invoicePrefixController.text.trim(),
      'quotation_prefix': quotationPrefixController.text.trim(),
      'return_prefix': returnPrefixController.text.trim(),
      'invoice_starting_number':
          int.tryParse(invoiceStartingNumberController.text.trim()) ?? 1000,
      'tax_enabled': taxEnabled,
      'tax_inclusive_pricing': taxInclusivePricing,
      'tax_name': taxNameController.text.trim(),
      'default_tax_rate':
          int.tryParse(taxRateController.text.trim()) ?? 15,
    };

    await cubit.updateSetting('stock_setting', stockSettings);

    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'إعدادات المخزون والفواتير'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('إعدادات التكاليف'),
                Container(
                  padding: AppConstant.defaultPadding,
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'اذا تم تعديل أو حذف كميات من فواتير أو عمليات سابقة فان نظام التكلفة الخاصة',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber[900],
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      title: 'السماح بالارجاع بدون فاتورة',
                      value: allowReturnWithoutInvoice,
                      icon: Icons.assignment_return,
                      onChanged: (value) {
                        setState(() {
                          allowReturnWithoutInvoice = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'اظهار الرصيد الحالي في الفاتورة',
                      value: showCustomerBalanceInInvoice,
                      icon: Icons.account_balance_wallet,
                      onChanged: (value) {
                        setState(() {
                          showCustomerBalanceInInvoice = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title:
                          'منع البيع في حالة ان سعر البيع أقل من سعر التكلفة',
                      value: preventWhenSaleLessThanCost,
                      icon: Icons.price_check,
                      onChanged: (value) {
                        setState(() {
                          preventWhenSaleLessThanCost = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'اظهار رقم موبايل العميل في الفواتير',
                      value: showCustomPhoneInInvoice,
                      icon: Icons.phone,
                      onChanged: (value) {
                        setState(() {
                          showCustomPhoneInInvoice = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'اظهار سعر التكلفة للاصناف في شاشة الفواتير',
                      value: showCostAmountInCategoryWhenAddInvoice,
                      icon: Icons.attach_money,
                      onChanged: (value) {
                        setState(() {
                          showCostAmountInCategoryWhenAddInvoice = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title:
                          'اظهار سعر التكلفة للاصناف في شاشة نقاط البيع',
                      value: showCostAmountInCategoryWhenAddInvoicePOS,
                      icon: Icons.point_of_sale,
                      onChanged: (value) {
                        setState(() {
                          showCostAmountInCategoryWhenAddInvoicePOS = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'السماح بالبيع بالسالب بكمية للاصناف',
                      value: isStockNegativeAllowed,
                      icon: Icons.remove_circle_outline,
                      onChanged: (value) {
                        setState(() {
                          isStockNegativeAllowed = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionLabel('ترقيم المستندات'),
                SettingsCard(
                  children: [
                    SettingsTextFieldTile(
                      title: 'بادئة فاتورة البيع',
                      controller: invoicePrefixController,
                      hintText: 'INV-',
                      icon: Icons.tag,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'بادئة عرض السعر',
                      controller: quotationPrefixController,
                      hintText: 'QUO-',
                      icon: Icons.tag,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'بادئة المردود',
                      controller: returnPrefixController,
                      hintText: 'RET-',
                      icon: Icons.tag,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'رقم بداية الفواتير',
                      controller: invoiceStartingNumberController,
                      hintText: '1000',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionLabel('إعدادات الضريبة'),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      title: 'تفعيل الضريبة في الفواتير',
                      value: taxEnabled,
                      icon: Icons.percent,
                      onChanged: (value) {
                        setState(() {
                          taxEnabled = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'الأسعار شاملة الضريبة',
                      value: taxInclusivePricing,
                      icon: Icons.price_change_outlined,
                      enabled: taxEnabled,
                      onChanged: (value) {
                        setState(() {
                          taxInclusivePricing = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'نسبة الضريبة %',
                      controller: taxRateController,
                      hintText: '15',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'اسم الضريبة',
                      controller: taxNameController,
                      hintText: 'ضريبة القيمة المضافة',
                      icon: Icons.label_outline,
                    ),
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
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
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
