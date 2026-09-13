import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/backup_service.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_dropdown_tile.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  bool backupEnabled = true;
  String backupFrequency = 'daily';
  int deviceSaveMethod = 1;
  bool notifyOnClose = true;
  bool _busy = false;
  List<BackupFile> _backups = const [];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    final security = cubit.getSecurityInfo();
    final backup = cubit.getBackupSettings();
    final other = cubit.getOtherSettings();

    backupEnabled = security['backup_enabled'] ?? true;
    backupFrequency = security['backup_frequency']?.toString() ?? 'daily';
    deviceSaveMethod = (backup['deviceSaveMethod'] ?? 1) as int;
    notifyOnClose = other['showBackupNotifyWhenCloseApp'] ?? true;
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final backups = await getIt<BackupService>().getAvailableBackups();
    if (mounted) setState(() => _backups = backups);
  }

  int get _frequencyHours {
    return switch (backupFrequency) {
      'weekly' => 168,
      'monthly' => 720,
      _ => 24,
    };
  }

  Future<void> _createBackupNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final cubit = context.read<SettingsCubit>();
    final path = await getIt<BackupService>().createBackup();
    if (path != null) {
      await cubit.updateSetting('backup_settings', {
        'deviceSaveTime': DateTime.now().millisecondsSinceEpoch,
      });
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (path == null) {
      AppToast.showError(context, 'تعذر إنشاء النسخة الاحتياطية');
      return;
    }
    AppToast.showSuccess(context, 'تم إنشاء النسخة الاحتياطية بنجاح');
    await _loadBackups();
  }

  Future<void> _restore(BackupFile backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: Text(
          'سيتم استبدال البيانات الحالية ببيانات النسخة (${backup.name}). هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final ok = await getIt<BackupService>().restoreBackup(backup.path);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      AppToast.showError(context, 'تعذرت استعادة النسخة الاحتياطية');
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تمت الاستعادة'),
        content: const Text(
          'تمت استعادة البيانات بنجاح. يرجى إغلاق التطبيق وإعادة فتحه لتطبيق التغييرات.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    await cubit.updateSetting('security_info', {
      'backup_enabled': backupEnabled,
      'backup_frequency': backupFrequency,
    });
    await cubit.updateSetting('backup_settings', {
      'deviceSaveMethod': deviceSaveMethod,
      'hours': _frequencyHours,
    });
    await cubit.updateSetting('other_setting', {
      'showBackupNotifyWhenCloseApp': notifyOnClose,
    });
    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'النسخ الاحتياطي'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('إعدادات النسخ الاحتياطي'),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      title: 'تفعيل النسخ الاحتياطي',
                      icon: Icons.backup_outlined,
                      value: backupEnabled,
                      onChanged: (value) {
                        setState(() {
                          backupEnabled = value;
                        });
                      },
                    ),
                    if (backupEnabled) ...[
                      const Divider(),
                      SettingsDropdownTile<String>(
                        title: 'تكرار النسخ الاحتياطي',
                        value: backupFrequency,
                        icon: Icons.schedule,
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('يومياً'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('أسبوعياً'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('شهرياً'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            backupFrequency = value!;
                          });
                        },
                      ),
                      const Divider(),
                      SettingsDropdownTile<int>(
                        title: 'طريقة النسخ على الجهاز',
                        value: deviceSaveMethod,
                        icon: Icons.phone_android,
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('تلقائي عند فتح التطبيق'),
                          ),
                          DropdownMenuItem(
                            value: 0,
                            child: Text('يدوي فقط'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            deviceSaveMethod = value!;
                          });
                        },
                      ),
                    ],
                    const Divider(),
                    SettingsSwitchTile(
                      title: 'تذكير بالنسخ الاحتياطي عند الخروج',
                      icon: Icons.notifications_outlined,
                      value: notifyOnClose,
                      onChanged: (value) {
                        setState(() {
                          notifyOnClose = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionLabel('نسخة يدوية'),
                HasibButton(
                  label: _busy ? 'جارٍ التنفيذ...' : 'إنشاء نسخة احتياطية الآن',
                  onPressed: _busy ? null : _createBackupNow,
                  variant: HasibButtonVariant.primary,
                ),
                const SizedBox(height: 16),
                const _SectionLabel('النسخ المتوفرة'),
                SettingsCard(
                  children: _backups.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: EmptyStateWidget(
                              title: 'لا توجد نسخ احتياطية',
                              subtitle: 'قم بإنشاء نسخة احتياطية للاحتفاظ ببياناتك',
                              icon: Icons.backup_outlined,
                            ),
                          ),
                        ]
                      : _backups
                            .map(
                              (backup) => ListTile(
                                leading: const Icon(Icons.storage_outlined),
                                title: Text(
                                  backup.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  backup.createdAt == null
                                      ? ''
                                      : DateFormatter.formatDateTime(
                                          backup.createdAt!,
                                        ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _restore(backup),
                                  child: const Text('استعادة'),
                                ),
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: 12),
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
