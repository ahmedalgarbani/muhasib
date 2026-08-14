import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/cubit/local_cubit.dart';
import 'package:muhasib/core/helpers/cubit/theme_cubit.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/core/widgets/settings_dropdown_tile.dart';
import 'package:muhasib/core/widgets/settings_text_field_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class OtherSettingsPage extends StatefulWidget {
  const OtherSettingsPage({super.key});

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
  String language = 'ar';
  double fontScale = 1.0;
  ThemeMode themeMode = ThemeMode.system;

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
    showAccountantAdvanceModule =
        otherSettings['showAccountantAdvanceModule'] ?? true;
    showTaxModule = otherSettings['showTaxModule'] ?? false;
    useMiniHasib = otherSettings['useMiniHasib'] ?? false;
    showBackupNotifyWhenCloseApp =
        otherSettings['showBackupNotifyWhenCloseApp'] ?? true;
    homeScreenType = _getHomeScreenTypeString(
      otherSettings['homeScrrenType'] ?? 1,
    );
    language = otherSettings['language'] ?? SettingsCache.language;
    fontScale = (otherSettings['fontScale'] ?? 1.0).toDouble();
    themeMode = context.read<ThemeCubit>().state;
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

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'النظام الافتراضي';
    }
  }

  ThemeMode _themeModeFromLabel(String label) {
    switch (label) {
      case 'فاتح':
        return ThemeMode.light;
      case 'داكن':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
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
      'language': language,
      'fontScale': fontScale,
    };

    await cubit.updateSetting('other_setting', otherSettings);

    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'إعدادات أخرى'),
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
                    'تكوينات النظام',
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
                      title: 'استخدام حسيب بشكل مبسط (دفتر حسابات)',
                      value: useMiniHasib,
                      icon: Icons.account_tree,
                      enabled: true,
                      onChanged: (value) {
                        setState(() {
                          useMiniHasib = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'إظهار موديول المخازن',
                      value: showStockModule,
                      icon: Icons.inventory_2,
                      onChanged: (value) {
                        setState(() {
                          showStockModule = value;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      title: 'اللغة',
                      value: language,
                      icon: Icons.language,
                      items: [
                        const DropdownMenuItem(
                          value: 'ar',
                          child: Text('العربية'),
                        ),
                        const DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          language = value!;
                        });
                        context
                            .read<LocaleCubit>()
                            .updateLocale(Locale(value!));
                      },
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      title: 'تغيير عرض الشاشة الرئيسية',
                      value: homeScreenType,
                      icon: Icons.home_outlined,
                      items: ['الأولى', 'الثانية', 'الثالثة']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          homeScreenType = value!;
                        });
                      },
                    ),
                  ],
                ),
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
                SettingsCard(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.text_fields,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      title: const Text(
                        'حجم الخط',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        fontScale == 1.0
                            ? 'طبيعي'
                            : 'x${fontScale.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      title: 'المظهر',
                      value: _themeModeLabel(themeMode),
                      icon: Icons.dark_mode_outlined,
                      items: ['النظام الافتراضي', 'فاتح', 'داكن']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        final mode = _themeModeFromLabel(value!);
                        setState(() {
                          themeMode = mode;
                        });
                        context.read<ThemeCubit>().updateTheme(mode);
                      },
                    ),
                  ],
                ),
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
                SettingsCard(
                  children: [
                    SettingsDropdownTile<String>(
                      title: 'صيغة التاريخ',
                      value: dateFormat,
                      icon: Icons.calendar_today,
                      items: [
                        'dd - MM - yyyy',
                        'yyyy - MM - dd',
                        'MM - dd - yyyy',
                      ]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          dateFormat = value!;
                        });
                      },
                    ),
                    const Divider(),
                    SettingsDropdownTile<String>(
                      title: 'نظام الوقت',
                      value: timeFormat,
                      icon: Icons.access_time,
                      items: ['12 ساعة', '24 ساعة']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          timeFormat = value!;
                        });
                      },
                    ),
                  ],
                ),
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
                SettingsCard(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.numbers,
                        size: 20,
                        color: Colors.grey[600],
                      ),
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
                      leading: Icon(
                        Icons.numbers,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      title: const Text(
                        'عدد الارقام بعد الفاصلة عند العرض',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        decimalNoOutput.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
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
                SettingsCard(
                  children: [
                    SettingsTextFieldTile(
                      icon: Icons.arrow_upward,
                      title: 'مدين',
                      controller: TextEditingController(text: debitText),
                      onChanged: (value) => debitText = value,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      icon: Icons.arrow_downward,
                      title: 'دائن',
                      controller: TextEditingController(text: creditText),
                      onChanged: (value) => creditText = value,
                    ),
                  ],
                ),
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
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      title: 'إظهار تأكيد النسخ الاحتياطي عند الخروج من النظام',
                      value: showBackupNotifyWhenCloseApp,
                      icon: Icons.backup,
                      onChanged: (value) {
                        setState(() {
                          showBackupNotifyWhenCloseApp = value;
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
