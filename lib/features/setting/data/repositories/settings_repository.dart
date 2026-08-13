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
    await database.update(
      'settings',
      {
        'setting_value': _encodeValue(merged),
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> updateMultipleSettings(Map<String, dynamic> settings) async {
    final batch = database.batch();

    for (final entry in settings.entries) {
      final merged = await _mergeWithCurrent(entry.key, entry.value);
      batch.update(
        'settings',
        {
          'setting_value': _encodeValue(merged),
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'setting_key = ?',
        whereArgs: [entry.key],
      );
    }

    await batch.commit();
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
