import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_dropdown_tile.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PrintSettingsPage extends StatefulWidget {
  const PrintSettingsPage({super.key});

  @override
  State<PrintSettingsPage> createState() => _PrintSettingsPageState();
}

class _PrintSettingsPageState extends State<PrintSettingsPage> {
  late Map<String, dynamic> printerSettings;
  
  String printType = 'A';
  String printMethod = 'Pdf';
  String printSize = 'A4';
  String printerConnect = 'عبر وسيط آخر';
  bool showHeaderData = true;
  bool repateHeaderInAllPages = true;
  bool showDate = false;
  bool showTime = false;
  bool showDateWithHistory = false;
  bool tafqeetAmount = false;
  bool showHeaderCompanyName = true;
  bool showHeaderCompanyAddress = true;
  bool showHeaderCompanyPhone = true;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    printerSettings = cubit.getPrinterInfo();
    
    printType = _getPrintTypeString(printerSettings['printType'] ?? 1);
    printMethod = _getPrintMethodString(printerSettings['printSize'] ?? 0);
    showHeaderData = printerSettings['showHeaderData'] ?? true;
    repateHeaderInAllPages = printerSettings['repateHeaderInAllPages'] ?? true;
    showDate = printerSettings['showDate'] ?? false;
    showTime = printerSettings['showTime'] ?? false;
    tafqeetAmount = printerSettings['tafqeetAmount'] ?? false;
    showHeaderCompanyName = printerSettings['showHeaderCompanyName'] ?? true;
    showHeaderCompanyAddress = printerSettings['showHeaderCompanyAddress'] ?? true;
    showHeaderCompanyPhone = printerSettings['showHeaderCompanyPhone'] ?? true;
  }

  String _getPrintTypeString(int type) {
    switch (type) {
      case 1:
        return 'A';
      case 2:
        return 'الخط الثاني';
      case 3:
        return 'الخط الثالث';
      default:
        return 'A';
    }
  }

  int _getPrintTypeInt(String type) {
    switch (type) {
      case 'A':
        return 1;
      case 'الخط الثاني':
        return 2;
      case 'الخط الثالث':
        return 3;
      default:
        return 1;
    }
  }

  String _getPrintMethodString(int method) {
    switch (method) {
      case 0:
        return 'Pdf';
      case 1:
        return 'طابعة محلية';
      default:
        return 'Pdf';
    }
  }

  int _getPrintMethodInt(String method) {
    switch (method) {
      case 'Pdf':
        return 0;
      case 'طابعة محلية':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final printerInfo = {
      'printType': _getPrintTypeInt(printType),
      'printSize': _getPrintMethodInt(printMethod),
      'printerConnect': 1,
      'showHeaderData': showHeaderData,
      'repateHeaderInAllPages': repateHeaderInAllPages,
      'showDate': showDate,
      'showTime': showTime,
      'showSignatureAndSealingInVoucher': 2,
      'showSignatureAndSealingInInvoice': 2,
      'showSignatureAndSealingInJournal': 2,
      'tafqeetAmount': tafqeetAmount,
      'showHeaderCompanyName': showHeaderCompanyName,
      'showHeaderCompanyAddress': showHeaderCompanyAddress,
      'showHeaderCompanyPhone': showHeaderCompanyPhone,
      'printFontType': 'assets/fonts/Alexandria-Regular.ttf',
    };
    
    await cubit.updateSetting('printer_info', printerInfo);
    
    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(title: 'إعدادات الطباعة'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'الإعدادات الرئيسية',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<String>(
                      title: 'نوع الخط في الطباعة',
                      value: printType,
                      icon: Icons.font_download_outlined,
                      items: ['A', 'الخط الثاني', 'الخط الثالث']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          printType = value!;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      title: 'طريقة الطباعة',
                      value: printMethod,
                      icon: Icons.print,
                      items: ['Pdf', 'طابعة محلية']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          printMethod = value!;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      title: 'حجم الطباعة',
                      value: printSize,
                      icon: Icons.photo_size_select_large,
                      items: ['A4', 'A5', 'Letter']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          printSize = value!;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      title: 'نوع اتصال الطابعة',
                      value: printerConnect,
                      icon: Icons.link,
                      items: ['عبر وسيط آخر', 'مباشر', 'شبكة']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          printerConnect = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'إعدادات البيانات',
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
                      title: 'عرض بيانات رأس الصفحة',
                      value: showHeaderData,
                      icon: Icons.view_headline,
                      onChanged: (value) {
                        setState(() {
                          showHeaderData = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'عرض الاسم في رأس الصفحة',
                      value: showHeaderCompanyName,
                      icon: Icons.text_fields,
                      onChanged: (value) {
                        setState(() {
                          showHeaderCompanyName = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'عرض العنوان في رأس الصفحة',
                      value: showHeaderCompanyAddress,
                      icon: Icons.home,
                      onChanged: (value) {
                        setState(() {
                          showHeaderCompanyAddress = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'عرض الهاتف في رأس الصفحة',
                      value: showHeaderCompanyPhone,
                      icon: Icons.phone,
                      onChanged: (value) {
                        setState(() {
                          showHeaderCompanyPhone = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'تكرار الترويسة في كل الصفحات',
                      value: repateHeaderInAllPages,
                      icon: Icons.repeat,
                      onChanged: (value) {
                        setState(() {
                          repateHeaderInAllPages = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'عرض تاريخ الطباعة',
                      value: showDate,
                      icon: Icons.date_range,
                      enabled: false,
                      onChanged: (value) {
                        setState(() {
                          showDate = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'عرض الوقت الطباعة',
                      value: showTime,
                      icon: Icons.access_time,
                      enabled: false,
                      onChanged: (value) {
                        setState(() {
                          showTime = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'تفقيط إجمالي المبلغ',
                      value: tafqeetAmount,
                      icon: Icons.text_format,
                      enabled: false,
                      onChanged: (value) {
                        setState(() {
                          tafqeetAmount = value;
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
