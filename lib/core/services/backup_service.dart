import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:muhasib/core/database/database_config.dart';
import 'package:muhasib/core/services/database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  Future<String?> createBackup() async {
    try {
      final dbPath = await getDatabasesPath();
      final String sourcePath = join(dbPath, DatabaseConfig.databaseName);
      final File sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        return null;
      }

      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final backupDir = Directory(join(directory.path, 'muhasib_backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupPath = join(backupDir.path, 'backup_$timestamp.db');

      await sourceFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      print('Backup Error: $e');
      return null;
    }
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
      print('Restore Error: $e');
      return false;
    }
  }

  Future<List<File>> getAvailableBackups() async {
    try {
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final backupDir = Directory(join(directory.path, 'muhasib_backups'));

      if (!await backupDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = backupDir.listSync();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
    } catch (e) {
      print('List Backups Error: $e');
      return [];
    }
  }
}
