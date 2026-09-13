import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  String _printSize = 'A4';
  String _orientation = 'portrait';

  // Toggles
  bool _showHeaderData = true;
  bool _showCompanyName = true;
  bool _showCompanyAddress = true;
  bool _showCompanyPhone = true;
  bool _showDate = false;
  bool _showTime = false;
  bool _tafqeetAmount = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final cubit = context.read<SettingsCubit>();
    final printerInfo = cubit.getPrinterInfo();

    setState(() {
      _printSize = printerInfo['print_paper_size'] ?? 'A4';
      _orientation = printerInfo['print_orientation'] ?? 'portrait';

      _showHeaderData = printerInfo['showHeaderData'] ?? true;
      _showCompanyName = printerInfo['showHeaderCompanyName'] ?? true;
      _showCompanyAddress = printerInfo['showHeaderCompanyAddress'] ?? true;
      _showCompanyPhone = printerInfo['showHeaderCompanyPhone'] ?? true;
      _showDate = printerInfo['showDate'] ?? false;
      _showTime = printerInfo['showTime'] ?? false;
      _tafqeetAmount = printerInfo['tafqeetAmount'] ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final printerInfo = cubit.getPrinterInfo();

    final updatedInfo = {
      ...printerInfo,
      'print_paper_size': _printSize,
      'print_orientation': _orientation,
      'showHeaderData': _showHeaderData,
      'showHeaderCompanyName': _showCompanyName,
      'showHeaderCompanyAddress': _showCompanyAddress,
      'showHeaderCompanyPhone': _showCompanyPhone,
      'showDate': _showDate,
      'showTime': _showTime,
      'tafqeetAmount': _tafqeetAmount,
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
                      icon: Icons.screen_rotation_outlined,
                      title: 'اتجاه الصفحة',
                      value: _orientation,
                      items: const [
                        DropdownMenuItem(
                          value: 'portrait',
                          child: Text('طولي'),
                        ),
                        DropdownMenuItem(
                          value: 'landscape',
                          child: Text('عرضي'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _orientation = value!),
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
                    const Divider(),
                    SettingsSwitchTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'عرض التاريخ',
                      value: _showDate,
                      onChanged: (value) => setState(() => _showDate = value),
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      icon: Icons.access_time_outlined,
                      title: 'عرض الوقت',
                      value: _showTime,
                      onChanged: (value) => setState(() => _showTime = value),
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      icon: Icons.record_voice_over_outlined,
                      title: 'تفقيط المبلغ (كتابة المبلغ بالحروف)',
                      value: _tafqeetAmount,
                      onChanged: (value) =>
                          setState(() => _tafqeetAmount = value),
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
