import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/core/widgets/settings_text_field_tile.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class VoucherSettingsPage extends StatefulWidget {
  const VoucherSettingsPage({super.key});

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
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: 'إعدادات السندات'),
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
                SettingsCard(
                  children: [
                    SettingsTextFieldTile(
                      title: 'السطر 1',
                      controller: paymentLine1Controller,
                      hintText: 'الاخ',
                      icon: Icons.text_fields,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'السطر 2',
                      controller: paymentLine2Controller,
                      hintText: 'عليكم مبلغ',
                      icon: Icons.text_fields,
                    ),
                  ],
                ),
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
                SettingsCard(
                  children: [
                    SettingsTextFieldTile(
                      title: 'السطر 1',
                      controller: receiptLine1Controller,
                      hintText: 'الاخ',
                      icon: Icons.text_fields,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      title: 'السطر 2',
                      controller: receiptLine2Controller,
                      hintText: 'لكم مبلغ',
                      icon: Icons.text_fields,
                    ),
                  ],
                ),
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
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.draw,
                      title: 'إظهار التوقيع اسفل السند',
                      value: paymentVoucherSignature,
                      onChanged: (value) {
                        setState(() {
                          paymentVoucherSignature = value;
                        });
                      },
                    ),
                    if (paymentVoucherSignature) ...[
                      const Divider(),
                      SettingsTextFieldTile(
                        title: 'التوقيع الأول',
                        controller: paymentFirstSignatureController,
                        hintText: 'المستلم',
                        icon: Icons.draw_outlined,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        title: 'التوقيع الثاني',
                        controller: paymentSecondSignatureController,
                        hintText: 'مدير الحسابات',
                        icon: Icons.draw_outlined,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        title: 'التوقيع الثالث',
                        controller: paymentThirdSignatureController,
                        hintText: 'الصندوق',
                        icon: Icons.draw_outlined,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        title: 'التوقيع الرابع',
                        controller: paymentFourthSignatureController,
                        hintText: 'المدير العام',
                        icon: Icons.draw_outlined,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
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
}
