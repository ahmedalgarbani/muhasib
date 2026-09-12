import 'dart:convert';

import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/plans/domain/entities/license_entity.dart';
import 'package:sqflite/sqflite.dart';

abstract class PlanLocalDataSource {
  Future<LicenseEntity?> getLicense();
  Future<void> saveLicense(LicenseEntity license);
  Future<void> clearLicense();
}

/// Persists the activation record inside the existing `settings` table
/// under the `license_info` key, so it travels with backups automatically.
class PlanLocalDataSourceImpl implements PlanLocalDataSource {
  static const String _table = 'settings';
  static const String _key = 'license_info';

  final Database database;

  PlanLocalDataSourceImpl({required this.database});

  @override
  Future<LicenseEntity?> getLicense() async {
    try {
      final rows = await database.query(
        _table,
        columns: ['setting_value'],
        where: 'setting_key = ?',
        whereArgs: [_key],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final raw = rows.first['setting_value']?.toString();
      if (raw == null || raw.isEmpty) return null;

      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      final license = LicenseEntity.fromMap(Map<String, dynamic>.from(decoded));
      return license.key.isEmpty ? null : license;
    } catch (e) {
      throw LocalStorageException('Failed to read license: $e');
    }
  }

  @override
  Future<void> saveLicense(LicenseEntity license) async {
    try {
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await database.insert(
        _table,
        {
          'creator_id': 1,
          'last_modifier_id': 1,
          'concurrency_stamp': '$nowInSeconds',
          'extra_properties': '',
          'creation_time': nowInSeconds,
          'last_modification_time': nowInSeconds,
          'setting_key': _key,
          'setting_value': json.encode(license.toMap()),
          'setting_type': 'JSON',
          'category': 'Licensing',
          'description': 'Offline activation license',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalStorageException('Failed to save license: $e');
    }
  }

  @override
  Future<void> clearLicense() async {
    try {
      await database.delete(
        _table,
        where: 'setting_key = ?',
        whereArgs: [_key],
      );
    } catch (e) {
      throw LocalStorageException('Failed to clear license: $e');
    }
  }
}
