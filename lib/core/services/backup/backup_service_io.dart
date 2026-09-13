import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:muhasib/core/database/database_config.dart';
import 'package:muhasib/core/services/backup/backup_file.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  Future<Directory> _backupDirectory() async {
    Directory? directory;
    try {
      directory = await getExternalStorageDirectory();
    } catch (_) {}
    directory ??= await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(directory.path, 'muhasib_backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<String?> createBackup() async {
    try {
      final dbPath = await getDatabasesPath();
      final String sourcePath = join(dbPath, DatabaseConfig.databaseName);
      final File sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        return null;
      }

      final backupDir = await _backupDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupPath = join(backupDir.path, 'backup_$timestamp.db');

      await sourceFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      return null;
    }
  }

  /// Creates a backup when auto-backup is enabled and the configured interval
  /// has elapsed. Returns the created backup path, or null when not needed.
  Future<String?> createBackupIfDue() async {
    if (!SettingsCache.backupEnabled) return null;
    if (SettingsCache.backupDeviceSaveMethod == 0) return null;
    final last = SettingsCache.backupDeviceSaveTime;
    final intervalHours = SettingsCache.backupHours;
    if (last != null &&
        intervalHours > 0 &&
        DateTime.now().difference(last).inHours < intervalHours) {
      return null;
    }
    return createBackup();
  }

  Future<bool> restoreBackup(String backupFilePath) async {
    try {
      final File backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return false;
      }

      // Close database before restore
      final dbService = DatabaseService();
      await dbService.close();

      final dbPath = await getDatabasesPath();
      final String destinationPath = join(dbPath, DatabaseConfig.databaseName);

      // Copy backup to database location
      await backupFile.copy(destinationPath);

      // Re-initialize database
      await dbService.database;

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<BackupFile>> getAvailableBackups() async {
    try {
      final backupDir = await _backupDirectory();
      final List<FileSystemEntity> files = backupDir.listSync();
      final backups = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .map(
            (file) => BackupFile(
              path: file.path,
              name: basename(file.path),
              createdAt: file.statSync().modified,
            ),
          )
          .toList()
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
      return backups;
    } catch (e) {
      return const [];
    }
  }
}
