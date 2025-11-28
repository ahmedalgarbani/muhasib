import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class VoucherSettingsPage extends StatefulWidget {
  const VoucherSettingsPage({Key? key}) : super(key: key);

  @override
  State<VoucherSettingsPage> createState() => _VoucherSettingsPageState();
}

class _VoucherSettingsPageState extends State<VoucherSettingsPage> {
  late Map<String, dynamic> voucherSettings;
  
  // Payment voucher settings
  late TextEditingController paymentLine1Controller;
  late TextEditingController paymentLine2Controller;
  bool paymentVoucherSignature = true;
  late TextEditingController paymentFirstSignatureController;
  late TextEditingController paymentSecondSignatureController;
  late TextEditingController paymentThirdSignatureController;
  late TextEditingController paymentFourthSignatureController;
  
  // Receipt voucher settings
  late TextEditingController receiptLine1Controller;
  late TextEditingController receiptLine2Controller;
  bool receiptVoucherSignature = true;
  late TextEditingController receiptFirstSignatureController;
  late TextEditingController receiptSecondSignatureController;
  late TextEditingController receiptThirdSignatureController;
  late TextEditingController receiptFourthSignatureController;
  
  bool allowMultiCurrency = false;
  bool showAccountBalance = false;
  bool checkFundBalance = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    voucherSettings = cubit.getVoucherSettings();
    
    // Initialize payment voucher controllers
    paymentLine1Controller = TextEditingController(text: voucherSettings['paymentVoucherLine1'] ?? 'الاخ');
    paymentLine2Controller = TextEditingController(text: voucherSettings['paymentVoucherLine2'] ?? 'عليكم مبلغ');
    paymentVoucherSignature = voucherSettings['paymentVoucherSignature'] ?? true;
    paymentFirstSignatureController = TextEditingController(text: voucherSettings['paymentVoucherFirstSignature'] ?? 'المستلم');
    paymentSecondSignatureController = TextEditingController(text: voucherSettings['paymentVoucherSecondSignature'] ?? 'مدير الحسابات');
    paymentThirdSignatureController = TextEditingController(text: voucherSettings['paymentVoucherThirdSignature'] ?? 'الصندوق');
    paymentFourthSignatureController = TextEditingController(text: voucherSettings['paymentVoucherFourthSignature'] ?? 'المدير العام');
    
    // Initialize receipt voucher controllers
    receiptLine1Controller = TextEditingController(text: voucherSettings['receiptVoucherVoucherLine1'] ?? 'الاخ');
    receiptLine2Controller = TextEditingController(text: voucherSettings['receiptVoucherVoucherLine2'] ?? 'لكم مبلغ');
    receiptVoucherSignature = voucherSettings['receiptVoucherSignature'] ?? true;
    receiptFirstSignatureController = TextEditingController(text: voucherSettings['receiptVoucherFirstSignature'] ?? 'المستلم');
    receiptSecondSignatureController = TextEditingController(text: voucherSettings['receiptVoucherSecondSignature'] ?? 'مدير الحسابات');
    receiptThirdSignatureController = TextEditingController(text: voucherSettings['receiptVoucherThirdSignature'] ?? 'الصندوق');
    receiptFourthSignatureController = TextEditingController(text: voucherSettings['receiptVoucherFourthSignature'] ?? 'المدير العام');
    
    allowMultiCurrency = voucherSettings['allowMultiCurrencyInVoucher'] ?? false;
    showAccountBalance = voucherSettings['showAccountBalanceInVoucher'] ?? false;
    checkFundBalance = voucherSettings['checkFundAndBankBalanceEnabledInVoucher'] ?? false;
  }

  @override
  void dispose() {
    paymentLine1Controller.dispose();
    paymentLine2Controller.dispose();
    paymentFirstSignatureController.dispose();
    paymentSecondSignatureController.dispose();
    paymentThirdSignatureController.dispose();
    paymentFourthSignatureController.dispose();
    receiptLine1Controller.dispose();
    receiptLine2Controller.dispose();
    receiptFirstSignatureController.dispose();
    receiptSecondSignatureController.dispose();
    receiptThirdSignatureController.dispose();
    receiptFourthSignatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final voucherSettings = {
      'paymentVoucherLine1': paymentLine1Controller.text,
      'paymentVoucherLine2': paymentLine2Controller.text,
      'receiptVoucherVoucherLine1': receiptLine1Controller.text,
      'receiptVoucherVoucherLine2': receiptLine2Controller.text,
      'paymentVoucherSignature': paymentVoucherSignature,
      'paymentVoucherFirstSignature': paymentFirstSignatureController.text,
      'paymentVoucherSecondSignature': paymentSecondSignatureController.text,
      'paymentVoucherThirdSignature': paymentThirdSignatureController.text,
      'paymentVoucherFourthSignature': paymentFourthSignatureController.text,
      'receiptVoucherSignature': receiptVoucherSignature,
      'receiptVoucherFirstSignature': receiptFirstSignatureController.text,
      'receiptVoucherSecondSignature': receiptSecondSignatureController.text,
      'receiptVoucherThirdSignature': receiptThirdSignatureController.text,
      'receiptVoucherFourthSignature': receiptFourthSignatureController.text,
      'notesInBotton': null,
      'allowMultiCurrencyInVoucher': allowMultiCurrency,
      'showAccountBalanceInVoucher': showAccountBalance,
      'checkFundAndBankBalanceEnabledInVoucher': checkFundBalance,
    };
    
    await cubit.updateSetting('voucher_setting', voucherSettings);
    
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
          'إعدادات السندات',
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
                    'صيغة سندات الصرف',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  _buildListTile(
                    title: 'السطر 1',
                    value: paymentLine1Controller.text,
                    icon: Icons.text_fields,
                    child: TextField(
                      controller: paymentLine1Controller,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'الاخ',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Divider(),
                  _buildListTile(
                    title: 'السطر 2',
                    value: paymentLine2Controller.text,
                    icon: Icons.text_fields,
                    child: TextField(
                      controller: paymentLine2Controller,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'عليكم مبلغ',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'صيغة سندات القبض',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  _buildListTile(
                    title: 'السطر 1',
                    value: receiptLine1Controller.text,
                    icon: Icons.text_fields,
                    child: TextField(
                      controller: receiptLine1Controller,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'الاخ',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Divider(),
                  _buildListTile(
                    title: 'السطر 2',
                    value: receiptLine2Controller.text,
                    icon: Icons.text_fields,
                    child: TextField(
                      controller: receiptLine2Controller,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'لكم مبلغ',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'توقيع سندات الصرف',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  SwitchListTile(
                    secondary: const Icon(Icons.draw, size: 20, color: Colors.grey),
                    title: const Text(
                      'إظهار التوقيع اسفل السند',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    subtitle: Text(
                      paymentVoucherSignature ? 'مفعل' : 'غير مفعل',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: paymentVoucherSignature,
                    onChanged: (value) {
                      setState(() {
                        paymentVoucherSignature = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                    dense: true,
                  ),
                  if (paymentVoucherSignature) ...[
                    const Divider(),
                    _buildListTile(
                      title: 'التوقيع الأول',
                      value: paymentFirstSignatureController.text,
                      icon: Icons.draw_outlined,
                      child: TextField(
                        controller: paymentFirstSignatureController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'المستلم',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Divider(),
                    _buildListTile(
                      title: 'التوقيع الثاني',
                      value: paymentSecondSignatureController.text,
                      icon: Icons.draw_outlined,
                      child: TextField(
                        controller: paymentSecondSignatureController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'مدير الحسابات',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Divider(),
                    _buildListTile(
                      title: 'التوقيع الثالث',
                      value: paymentThirdSignatureController.text,
                      icon: Icons.draw_outlined,
                      child: TextField(
                        controller: paymentThirdSignatureController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'الصندوق',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Divider(),
                    _buildListTile(
                      title: 'التوقيع الرابع',
                      value: paymentFourthSignatureController.text,
                      icon: Icons.draw_outlined,
                      child: TextField(
                        controller: paymentFourthSignatureController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'المدير العام',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildListTile({
    required String title,
    required String value,
    required IconData icon,
    required Widget child,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: child,
    );
  }
}
