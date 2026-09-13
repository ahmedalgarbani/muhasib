import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/backup_service.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/widgets/app_lock_gate.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';

/// Intercepts application exit (desktop window close / Android back at root)
/// and offers to create a database backup first, honoring the
/// `showBackupNotifyWhenCloseApp` setting.
class BackupExitGuard extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const BackupExitGuard({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  @override
  State<BackupExitGuard> createState() => _BackupExitGuardState();
}

class _BackupExitGuardState extends State<BackupExitGuard> {
  late final AppLifecycleListener _lifecycleListener;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _onExitRequested,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<ui.AppExitResponse> _onExitRequested() async {
    if (!SettingsCache.showBackupNotifyWhenCloseApp) {
      return ui.AppExitResponse.exit;
    }
    // While the app lock screen is showing we cannot display the reminder.
    if (AppLockState.locked.value) {
      return ui.AppExitResponse.exit;
    }
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null || _dialogOpen) {
      return ui.AppExitResponse.exit;
    }

    _dialogOpen = true;
    final choice = await showDialog<String>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('النسخ الاحتياطي'),
        content: const Text(
          'هل تريد إنشاء نسخة احتياطية من البيانات قبل إغلاق التطبيق؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'exit'),
            child: const Text('خروج بدون نسخة'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'backup'),
            child: const Text('إنشاء وخروج'),
          ),
        ],
      ),
    );
    _dialogOpen = false;

    if (choice == 'backup') {
      final path = await getIt<BackupService>().createBackup();
      if (path != null) {
        try {
          await getIt<SettingsCubit>().updateSetting('backup_settings', {
            'deviceSaveTime': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (_) {}
      }
      return ui.AppExitResponse.exit;
    }
    if (choice == 'exit') {
      return ui.AppExitResponse.exit;
    }
    return ui.AppExitResponse.cancel;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


