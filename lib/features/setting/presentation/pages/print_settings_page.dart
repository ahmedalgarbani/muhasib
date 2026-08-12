import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

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
            padding: const EdgeInsets.all(16),
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
                _buildCard([
                  _buildDropdownField(
                    label: 'نوع الخط في الطباعة',
                    value: printType,
                    icon: Icons.font_download_outlined,
                    items: ['A', 'الخط الثاني', 'الخط الثالث'],
                    onChanged: (value) {
                      setState(() {
                        printType = value!;
                      });
                    },
                  ),
                  const Divider(),
                  _buildDropdownField(
                    label: 'طريقة الطباعة',
                    value: printMethod,
                    icon: Icons.print,
                    items: ['Pdf', 'طابعة محلية'],
                    onChanged: (value) {
                      setState(() {
                        printMethod = value!;
                      });
                    },
                  ),
                  const Divider(),
                  _buildDropdownField(
                    label: 'حجم الطباعة',
                    value: printSize,
                    icon: Icons.photo_size_select_large,
                    items: ['A4', 'A5', 'Letter'],
                    onChanged: (value) {
                      setState(() {
                        printSize = value!;
                      });
                    },
                  ),
                  const Divider(),
                  _buildDropdownField(
                    label: 'نوع اتصال الطابعة',
                    value: printerConnect,
                    icon: Icons.link,
                    items: ['عبر وسيط آخر', 'مباشر', 'شبكة'],
                    onChanged: (value) {
                      setState(() {
                        printerConnect = value!;
                      });
                    },
                  ),
                ]),
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
                _buildCard([
                  _buildSwitchField(
                    label: 'عرض بيانات رأس الصفحة',
                    value: showHeaderData,
                    icon: Icons.view_headline,
                    onChanged: (value) {
                      setState(() {
                        showHeaderData = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'عرض الاسم في رأس الصفحة',
                    value: showHeaderCompanyName,
                    icon: Icons.text_fields,
                    onChanged: (value) {
                      setState(() {
                        showHeaderCompanyName = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'عرض العنوان في رأس الصفحة',
                    value: showHeaderCompanyAddress,
                    icon: Icons.home,
                    onChanged: (value) {
                      setState(() {
                        showHeaderCompanyAddress = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'عرض الهاتف في رأس الصفحة',
                    value: showHeaderCompanyPhone,
                    icon: Icons.phone,
                    onChanged: (value) {
                      setState(() {
                        showHeaderCompanyPhone = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'تكرار الترويسة في كل الصفحات',
                    value: repateHeaderInAllPages,
                    icon: Icons.repeat,
                    onChanged: (value) {
                      setState(() {
                        repateHeaderInAllPages = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'عرض تاريخ الطباعة',
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
                  _buildSwitchField(
                    label: 'عرض الوقت الطباعة',
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
                  _buildSwitchField(
                    label: 'تفقيط إجمالي المبلغ',
                    value: tafqeetAmount,
                    icon: Icons.text_format,
                    enabled: false,
                    onChanged: (value) {
                      setState(() {
                        tafqeetAmount = value;
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

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
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
      secondary: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
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
      activeThumbColor: Theme.of(context).primaryColor,
      dense: true,
    );
  }
}
