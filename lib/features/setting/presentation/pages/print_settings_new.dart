import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
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
  // Print Settings Variables
  String _printType = 'A4';
  String _printMethod = 'Pdf';
  String _printSize = 'A4';
  String _connectionType = 'عبر وسيط آخر';

  // Toggles
  bool _showHeaderData = true;
  bool _showCompanyName = true;
  bool _showCompanyAddress = true;
  bool _showCompanyPhone = true;
  bool _showDate = false;
  bool _showTime = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final cubit = context.read<SettingsCubit>();
    final printerInfo = cubit.getPrinterInfo();

    setState(() {
      _printType = _getPrintTypeString(printerInfo['printType'] ?? 1);
      _printMethod = _getPrintMethodString(printerInfo['printSize'] ?? 0);
      _printSize = printerInfo['print_paper_size'] ?? 'A4';
      _connectionType = _getConnectionTypeString(
        printerInfo['printerConnect'] ?? 1,
      );

      _showHeaderData = printerInfo['showHeaderData'] ?? true;
      _showCompanyName = printerInfo['showHeaderCompanyName'] ?? true;
      _showCompanyAddress = printerInfo['showHeaderCompanyAddress'] ?? true;
      _showCompanyPhone = printerInfo['showHeaderCompanyPhone'] ?? true;
      _showDate = printerInfo['showDate'] ?? false;
      _showTime = printerInfo['showTime'] ?? false;
    });
  }

  String _getPrintTypeString(int type) {
    switch (type) {
      case 0:
        return 'A5';
      case 1:
        return 'A4';
      case 2:
        return 'Letter';
      default:
        return 'A4';
    }
  }

  String _getPrintMethodString(int method) {
    switch (method) {
      case 0:
        return 'Pdf';
      case 1:
        return 'Html';
      default:
        return 'Pdf';
    }
  }

  String _getConnectionTypeString(int type) {
    switch (type) {
      case 0:
        return 'غير وسيط آخر';
      case 1:
        return 'عبر وسيط آخر';
      default:
        return 'عبر وسيط آخر';
    }
  }

  int _getPrintTypeInt(String type) {
    switch (type) {
      case 'A5':
        return 0;
      case 'A4':
        return 1;
      case 'Letter':
        return 2;
      default:
        return 1;
    }
  }

  int _getPrintMethodInt(String method) {
    switch (method) {
      case 'Pdf':
        return 0;
      case 'Html':
        return 1;
      default:
        return 0;
    }
  }

  int _getConnectionTypeInt(String type) {
    switch (type) {
      case 'غير وسيط آخر':
        return 0;
      case 'عبر وسيط آخر':
        return 1;
      default:
        return 1;
    }
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final printerInfo = cubit.getPrinterInfo();

    final updatedInfo = {
      ...printerInfo,
      'printType': _getPrintTypeInt(_printType),
      'printSize': _getPrintMethodInt(_printMethod),
      'print_paper_size': _printSize,
      'printerConnect': _getConnectionTypeInt(_connectionType),
      'showHeaderData': _showHeaderData,
      'showHeaderCompanyName': _showCompanyName,
      'showHeaderCompanyAddress': _showCompanyAddress,
      'showHeaderCompanyPhone': _showCompanyPhone,
      'showDate': _showDate,
      'showTime': _showTime,
    };

    await cubit.updateSetting('printer_info', updatedInfo);

    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'إعدادات الطباعة'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: الإعدادات الرئيسية
                const Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 4,
                  ),
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
                      icon: Icons.description_outlined,
                      title: 'نوع الخط في الطباعة',
                      value: _printType,
                      items: ['A4', 'A5', 'Letter']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _printType = value!),
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      icon: Icons.print_outlined,
                      title: 'طريقة الطباعة',
                      value: _printMethod,
                      items: ['Pdf', 'Html']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _printMethod = value!),
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      icon: Icons.photo_size_select_large_outlined,
                      title: 'حجم الطباعة',
                      value: _printSize,
                      items: ['A4', 'A5', 'Letter']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _printSize = value!),
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      icon: Icons.link_outlined,
                      title: 'نوع اتصال الطابعة',
                      value: _connectionType,
                      items: ['عبر وسيط آخر', 'غير وسيط آخر']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _connectionType = value!),
                    ),
                  ],
                ),

                // Section: إعدادات البيانات
                const Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 4,
                  ),
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
                      icon: Icons.article_outlined,
                      title: 'عرض بيانات رأس الصفحة',
                      value: _showHeaderData,
                      onChanged: (value) =>
                          setState(() => _showHeaderData = value),
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      icon: Icons.text_fields_outlined,
                      title: 'عرض الاسم في رأس الصفحة',
                      value: _showCompanyName,
                      onChanged: (value) =>
                          setState(() => _showCompanyName = value),
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      icon: Icons.home_outlined,
                      title: 'عرض العنوان في رأس الصفحة',
                      value: _showCompanyAddress,
                      onChanged: (value) =>
                          setState(() => _showCompanyAddress = value),
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      icon: Icons.phone_outlined,
                      title: 'عرض الهاتف في رأس الصفحة',
                      value: _showCompanyPhone,
                      onChanged: (value) =>
                          setState(() => _showCompanyPhone = value),
                    ),
                  ],
                ),

                Padding(
                  padding: AppConstant.defaultPadding,
                  child: HasibButton(
                    label: 'حفظ',
                    onPressed: _saveSettings,
                    variant: HasibButtonVariant.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
