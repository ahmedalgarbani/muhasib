import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:muhasib/core/database/seeders/settings_seeder.dart';
import 'package:muhasib/features/setting/domain/models/setting_model.dart';

abstract class ISettingsRepository {
  Future<Map<String, dynamic>> getAllSettings();
  Future<dynamic> getSetting(String key);
  Future<void> updateSetting(String key, dynamic value);
  Future<void> updateMultipleSettings(Map<String, dynamic> settings);
  Future<void> initializeDefaultSettings();
}

class SettingsRepository implements ISettingsRepository {
  final Database database;

  SettingsRepository({required this.database});

  @override
  Future<Map<String, dynamic>> getAllSettings() async {
    final results = await database.query('settings');
    final settings = <String, dynamic>{};
    
    for (final row in results) {
      final model = SettingModel.fromMap(row);
      settings[model.settingKey] = model.settingValue;
    }
    
    return settings;
  }

  @override
  Future<dynamic> getSetting(String key) async {
    final results = await database.query(
      'settings',
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    final model = SettingModel.fromMap(results.first);
    return model.settingValue;
  }

  @override
  Future<void> updateSetting(String key, dynamic value) async {
    final merged = await _mergeWithCurrent(key, value);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final encoded = _encodeValue(merged);
    final updated = await database.update(
      'settings',
      {
        'setting_value': encoded,
        'last_modification_time': now,
      },
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    if (updated == 0) {
      await database.insert(
        'settings',
        {
          'setting_key': key,
          'setting_value': encoded,
          'setting_type': 'STRING',
          'category': 'General',
          'creation_time': now,
          'last_modification_time': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> updateMultipleSettings(Map<String, dynamic> settings) async {
    // Sequential upserts: setting rows are few and this guarantees keys
    // missing from the table are created instead of silently dropped.
    for (final entry in settings.entries) {
      await updateSetting(entry.key, entry.value);
    }
  }

  /// Keeps existing fields that the caller did not provide, so partial
  /// saves never wipe keys from a JSON setting row.
  Future<dynamic> _mergeWithCurrent(String key, dynamic newValue) async {
    if (newValue is! Map) {
      return newValue;
    }
    final current = await getSetting(key);
    if (current is Map) {
      final merged = Map<String, dynamic>.from(current);
      merged.addAll(Map<String, dynamic>.from(newValue));
      return merged;
    }
    return newValue;
  }

  String _encodeValue(dynamic value) {
    return value is Map || value is List ? jsonEncode(value) : value.toString();
  }

  @override
  Future<void> initializeDefaultSettings() async {
    final batch = database.batch();
    for (final setting in SettingsSeeder.defaultSettings) {
      batch.insert(
        'settings',
        setting,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit();
  }
}
