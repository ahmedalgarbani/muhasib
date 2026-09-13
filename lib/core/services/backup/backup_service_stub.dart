import 'package:muhasib/core/services/backup/backup_file.dart';

/// No-op implementation for platforms without filesystem access (web).
class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  Future<String?> createBackup() async => null;

  Future<String?> createBackupIfDue() async => null;

  Future<bool> restoreBackup(String backupFilePath) async => false;

  Future<List<BackupFile>> getAvailableBackups() async => const [];
}
