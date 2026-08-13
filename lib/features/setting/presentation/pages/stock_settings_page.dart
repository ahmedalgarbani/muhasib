import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class StockSettingsPage extends StatefulWidget {
  const StockSettingsPage({super.key});

  @override
  State<StockSettingsPage> createState() => _StockSettingsPageState();
}

class _StockSettingsPageState extends State<StockSettingsPage> {
  late Map<String, dynamic> stockSettings;
  
  bool allowReturnWithoutInvoice = true;
  bool showCustomerBalanceInInvoice = false;
  bool showMonetaryInvoiceInCustomerAccount = true;
  bool preventWhenSaleLessThanCost = true;
  bool showCostAmountInInvoice = true;
  bool showCustomPhoneInInvoice = true;
  bool showCostAmountInCategoryWhenAddInvoice = true;
  bool showCostAmountInCategoryWhenAddInvoicePOS = false;
  bool checkFundAndBankBalanceEnabledInInvoice = false;
  bool isStockNegativeAllowed = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    stockSettings = cubit.getStockSettings();
    
    allowReturnWithoutInvoice = stockSettings['allowReturnWithoutInvoice'] ?? true;
    showCustomerBalanceInInvoice = stockSettings['showCustomerBalanceInInvoice'] ?? false;
    showMonetaryInvoiceInCustomerAccount = stockSettings['showMonetaryInvoiceInCustomerAccount'] ?? true;
    preventWhenSaleLessThanCost = stockSettings['preventWhenSaleLessThanCost'] ?? true;
    showCostAmountInInvoice = stockSettings['showCoseAmountInInvoice'] ?? true;
    showCustomPhoneInInvoice = stockSettings['showCustomPhoneInInvoice'] ?? true;
    showCostAmountInCategoryWhenAddInvoice = stockSettings['showCostAmountInCategoryWhenAddInvoice'] ?? true;
    showCostAmountInCategoryWhenAddInvoicePOS = stockSettings['showCostAmountInCategoryWhenAddInvoicePOS'] ?? false;
    checkFundAndBankBalanceEnabledInInvoice = stockSettings['checkFundAndBankBalanceEnabledInInvoice'] ?? false;
    isStockNegativeAllowed = stockSettings['isStockNegativeAllowed'] ?? false;
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final stockSettings = {
      'allowReturnWithoutInvoice': allowReturnWithoutInvoice,
      'showCustomerBalanceInInvoice': showCustomerBalanceInInvoice,
      'showMonetaryInvoiceInCustomerAccount': showMonetaryInvoiceInCustomerAccount,
      'preventWhenSaleLessThanCost': preventWhenSaleLessThanCost,
      'showCoseAmountInInvoice': showCostAmountInInvoice,
      'showCustomPhoneInInvoice': showCustomPhoneInInvoice,
      'showCostAmountInCategoryWhenAddInvoice': showCostAmountInCategoryWhenAddInvoice,
      'showCostAmountInCategoryWhenAddInvoicePOS': showCostAmountInCategoryWhenAddInvoicePOS,
      'checkFundAndBankBalanceEnabledInInvoice': checkFundAndBankBalanceEnabledInInvoice,
      'isStockNegativeAllowed': isStockNegativeAllowed,
    };
    
    await cubit.updateSetting('stock_setting', stockSettings);
    
    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: 'إعدادات المخزون والفواتير'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'إعدادات التكاليف',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
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
                      enabled: false,
                      onChanged: (value) {
                        setState(() {
                          showCustomerBalanceInInvoice = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'منع البيع في حالة ان سعر البيع أقل من سعر التكلفة',
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
                      title: 'انتسار بترتيب نحدى في الفاتورة',
                      value: false,
                      icon: Icons.sort,
                      enabled: false,
                      onChanged: (value) {},
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'اظهار الفواتير النقدية في حساب العميل او المورد من خلال عمل قيد منتج للفاتورة',
                      value: showMonetaryInvoiceInCustomerAccount,
                      icon: Icons.receipt_long,
                      onChanged: (value) {
                        setState(() {
                          showMonetaryInvoiceInCustomerAccount = value;
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
                      title: 'اظهار سعر التكلفة للاصناف في شاشة الفواتير بالنسبة لنقاط البيع',
                      value: showCostAmountInCategoryWhenAddInvoicePOS,
                      icon: Icons.point_of_sale,
                      enabled: false,
                      onChanged: (value) {
                        setState(() {
                          showCostAmountInCategoryWhenAddInvoicePOS = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'فحص رصيد الصندوق او البنك في المشتريات ومردود المبيعات',
                      value: checkFundAndBankBalanceEnabledInInvoice,
                      icon: Icons.account_balance,
                      enabled: false,
                      onChanged: (value) {
                        setState(() {
                          checkFundAndBankBalanceEnabledInInvoice = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'السماح بالبيع بالسالب بكمية لاصناف',
                      value: isStockNegativeAllowed,
                      icon: Icons.remove_circle_outline,
                      enabled: false,
                      onChanged: (value) {
                        setState(() {
                          isStockNegativeAllowed = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
