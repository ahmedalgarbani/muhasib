import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class StockSettingsPage extends StatefulWidget {
  const StockSettingsPage({Key? key}) : super(key: key);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'إعدادات المخزون والفواتير',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
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
                    borderRadius: BorderRadius.circular(12),
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
                _buildCard([
                  _buildSwitchField(
                    label: 'السماح بالارجاع بدون فاتورة',
                    value: allowReturnWithoutInvoice,
                    icon: Icons.assignment_return,
                    onChanged: (value) {
                      setState(() {
                        allowReturnWithoutInvoice = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'اظهار الرصيد الحالي في الفاتورة',
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
                  _buildSwitchField(
                    label: 'منع البيع في حالة ان سعر البيع أقل من سعر التكلفة',
                    value: preventWhenSaleLessThanCost,
                    icon: Icons.price_check,
                    onChanged: (value) {
                      setState(() {
                        preventWhenSaleLessThanCost = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'اظهار رقم موبايل العميل في الفواتير',
                    value: showCustomPhoneInInvoice,
                    icon: Icons.phone,
                    onChanged: (value) {
                      setState(() {
                        showCustomPhoneInInvoice = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'انتسار بترتيب نحدى في الفاتورة',
                    value: false,
                    icon: Icons.sort,
                    enabled: false,
                    onChanged: (value) {},
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'اظهار الفواتير النقدية في حساب العميل او المورد من خلال عمل قيد منتج للفاتورة',
                    value: showMonetaryInvoiceInCustomerAccount,
                    icon: Icons.receipt_long,
                    onChanged: (value) {
                      setState(() {
                        showMonetaryInvoiceInCustomerAccount = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'اظهار سعر التكلفة للاصناف في شاشة الفواتير',
                    value: showCostAmountInCategoryWhenAddInvoice,
                    icon: Icons.attach_money,
                    onChanged: (value) {
                      setState(() {
                        showCostAmountInCategoryWhenAddInvoice = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'اظهار سعر التكلفة للاصناف في شاشة الفواتير بالنسبة لنقاط البيع',
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
                  _buildSwitchField(
                    label: 'فحص رصيد الصندوق او البنك في المشتريات ومردود المبيعات',
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
                  _buildSwitchField(
                    label: 'السماح بالبيع بالسالب بكمية لاصناف',
                    value: isStockNegativeAllowed,
                    icon: Icons.remove_circle_outline,
                    enabled: false,
                    onChanged: (value) {
                      setState(() {
                        isStockNegativeAllowed = value;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'حفظ التغييرات',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, size: 20, color: enabled ? Colors.grey[600] : Colors.grey[400]),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.black87 : Colors.grey[400],
        ),
      ),
      subtitle: Text(
        value ? 'مفعل' : 'غير مفعل',
        style: TextStyle(
          fontSize: 11,
          color: enabled ? Colors.grey : Colors.grey[400],
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: Theme.of(context).primaryColor,
      dense: true,
    );
  }
}
