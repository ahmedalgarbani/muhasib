import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class OtherSettingsPage extends StatefulWidget {
  const OtherSettingsPage({Key? key}) : super(key: key);

  @override
  State<OtherSettingsPage> createState() => _OtherSettingsPageState();
}

class _OtherSettingsPageState extends State<OtherSettingsPage> {
  late Map<String, dynamic> otherSettings;
  
  String dateFormat = 'dd - MM - yyyy';
  String timeFormat = '12 ساعة';
  int decimalNoInput = 7;
  int decimalNoOutput = 2;
  String debitText = 'مدين';
  String creditText = 'دائن';
  bool showStockModule = true;
  bool showAccountantAdvanceModule = true;
  bool showTaxModule = false;
  bool useMiniHasib = false;
  bool showBackupNotifyWhenCloseApp = true;
  String homeScreenType = 'الأولى';
  double fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    otherSettings = cubit.getOtherSettings();
    
    dateFormat = _getDateFormatString(otherSettings['dateFormat'] ?? 0);
    timeFormat = _getTimeFormatString(otherSettings['timeFormat'] ?? 0);
    decimalNoInput = otherSettings['decimalNoInput'] ?? 7;
    decimalNoOutput = otherSettings['decimalNoOutput'] ?? 2;
    debitText = otherSettings['debit'] ?? 'مدين';
    creditText = otherSettings['credit'] ?? 'دائن';
    showStockModule = otherSettings['showStockModule'] ?? true;
    showAccountantAdvanceModule = otherSettings['showAccountantAdvanceModule'] ?? true;
    showTaxModule = otherSettings['showTaxModule'] ?? false;
    useMiniHasib = otherSettings['useMiniHasib'] ?? false;
    showBackupNotifyWhenCloseApp = otherSettings['showBackupNotifyWhenCloseApp'] ?? true;
    homeScreenType = _getHomeScreenTypeString(otherSettings['homeScrrenType'] ?? 1);
    fontScale = (otherSettings['fontScale'] ?? 1.0).toDouble();
  }

  String _getDateFormatString(int format) {
    switch (format) {
      case 0:
        return 'dd - MM - yyyy';
      case 1:
        return 'yyyy - MM - dd';
      case 2:
        return 'MM - dd - yyyy';
      default:
        return 'dd - MM - yyyy';
    }
  }

  int _getDateFormatInt(String format) {
    switch (format) {
      case 'dd - MM - yyyy':
        return 0;
      case 'yyyy - MM - dd':
        return 1;
      case 'MM - dd - yyyy':
        return 2;
      default:
        return 0;
    }
  }

  String _getTimeFormatString(int format) {
    return format == 0 ? '12 ساعة' : '24 ساعة';
  }

  int _getTimeFormatInt(String format) {
    return format == '12 ساعة' ? 0 : 1;
  }

  String _getHomeScreenTypeString(int type) {
    switch (type) {
      case 1:
        return 'الأولى';
      case 2:
        return 'الثانية';
      case 3:
        return 'الثالثة';
      default:
        return 'الأولى';
    }
  }

  int _getHomeScreenTypeInt(String type) {
    switch (type) {
      case 'الأولى':
        return 1;
      case 'الثانية':
        return 2;
      case 'الثالثة':
        return 3;
      default:
        return 1;
    }
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final otherSettings = {
      'dateFormat': _getDateFormatInt(dateFormat),
      'timeFormat': _getTimeFormatInt(timeFormat),
      'decimalNoInput': decimalNoInput,
      'decimalNoOutput': decimalNoOutput,
      'debit': debitText,
      'credit': creditText,
      'showStockModule': showStockModule,
      'showAccountantAdvanceModule': showAccountantAdvanceModule,
      'updateCostAmountType': 2,
      'showTaxModule': showTaxModule,
      'homeScrrenType': _getHomeScreenTypeInt(homeScreenType),
      'useMiniHasib': useMiniHasib,
      'showBackupNotifyWhenCloseApp': showBackupNotifyWhenCloseApp,
      'fontScale': fontScale,
    };
    
    await cubit.updateSetting('other_setting', otherSettings);
    
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
      appBar: CustomAppBar(title: 'إعدادات أخرى'),
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
                    'تكوينات النظام',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  _buildSwitchField(
                    label: 'استخدام حسيب بشكل مبسط (دفتر حسابات)',
                    value: useMiniHasib,
                    icon: Icons.account_tree,
                    enabled: false,
                    onChanged: (value) {
                      setState(() {
                        useMiniHasib = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchField(
                    label: 'إظهار موديول المخازن',
                    value: showStockModule,
                    icon: Icons.inventory_2,
                    onChanged: (value) {
                      setState(() {
                        showStockModule = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildDropdownField(
                    label: 'تغيير عرض الشاشة الرئيسية',
                    value: homeScreenType,
                    icon: Icons.home_outlined,
                    items: ['الأولى', 'الثانية', 'الثالثة'],
                    onChanged: (value) {
                      setState(() {
                        homeScreenType = value!;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'الشاشات والخطوط',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  ListTile(
                    leading: Icon(Icons.text_fields, size: 20, color: Colors.grey[600]),
                    title: const Text(
                      'حجم الخط',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      fontScale == 1.0 ? 'طبيعي' : 'x${fontScale.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'إعدادات الوقت والتاريخ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  _buildDropdownField(
                    label: 'صيغة التاريخ',
                    value: dateFormat,
                    icon: Icons.calendar_today,
                    items: ['dd - MM - yyyy', 'yyyy - MM - dd', 'MM - dd - yyyy'],
                    onChanged: (value) {
                      setState(() {
                        dateFormat = value!;
                      });
                    },
                  ),
                  const Divider(),
                  _buildDropdownField(
                    label: 'نظام الوقت',
                    value: timeFormat,
                    icon: Icons.access_time,
                    items: ['12 ساعة', '24 ساعة'],
                    onChanged: (value) {
                      setState(() {
                        timeFormat = value!;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'الأرقام العشرية',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  ListTile(
                    leading: Icon(Icons.numbers, size: 20, color: Colors.grey[600]),
                    title: const Text(
                      'عدد الارقام بعد الفاصلة عند الإدخال',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      decimalNoInput.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.numbers, size: 20, color: Colors.grey[600]),
                    title: const Text(
                      'عدد الارقام بعد الفاصلة عند العرض',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      decimalNoOutput.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'المدين والدائن',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  ListTile(
                    leading: Icon(Icons.arrow_upward, size: 20, color: Colors.grey[600]),
                    title: const Text(
                      'مدين',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: TextField(
                      controller: TextEditingController(text: debitText),
                      onChanged: (value) => debitText = value,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.arrow_downward, size: 20, color: Colors.grey[600]),
                    title: const Text(
                      'دائن',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: TextField(
                      controller: TextEditingController(text: creditText),
                      onChanged: (value) => creditText = value,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
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
                    'إعدادات عامة',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildCard([
                  _buildSwitchField(
                    label: 'إظهار تأكيد النسخ الاحتياطي عند الخروج من النظام',
                    value: showBackupNotifyWhenCloseApp,
                    icon: Icons.backup,
                    onChanged: (value) {
                      setState(() {
                        showBackupNotifyWhenCloseApp = value;
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
}
