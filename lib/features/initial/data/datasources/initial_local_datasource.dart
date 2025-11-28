import 'dart:convert';

import 'package:sqflite/sqflite.dart';

abstract class InitialLocalDataSource {
  Future<bool> isInitialSetupComplete();
  Future<void> setInitialSetupComplete();
}

class InitialLocalDataSourceImpl implements InitialLocalDataSource {
  final Database database;

  static const String _settingsTable = 'settings';
  static const String _initialKey = 'initial_setup_done';

  InitialLocalDataSourceImpl({required this.database});

  @override
  Future<bool> isInitialSetupComplete() async {
    final rows = await database.query(
      _settingsTable,
      where: 'setting_key = ?',
      whereArgs: [_initialKey],
      limit: 1,
    );

    if (rows.isEmpty) {
      await _ensureInitialFlagExists();
      return false;
    }

    final rawValue = rows.first['setting_value']?.toString() ?? 'false';
    return _parseBool(rawValue);
  }

  @override
  Future<void> setInitialSetupComplete() async {
    await _ensureInitialFlagExists();
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await database.update(
      _settingsTable,
      {
        'setting_value': jsonEncode(true),
        'last_modification_time': timestamp,
        'concurrency_stamp': timestamp.toString(),
      },
      where: 'setting_key = ?',
      whereArgs: [_initialKey],
    );
  }

  Future<void> _ensureInitialFlagExists() async {
    final existing = await database.query(
      _settingsTable,
      where: 'setting_key = ?',
      whereArgs: [_initialKey],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await database.insert(
      _settingsTable,
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': now.toString(),
        'extra_properties': '',
        'creation_time': now,
        'last_modification_time': now,
        'setting_key': _initialKey,
        'setting_value': jsonEncode(false),
        'setting_type': 'BOOLEAN',
        'description': 'Flag that indicates whether initial onboarding is complete',
        'category': 'General',
      },
    );
  }

  bool _parseBool(String rawValue) {
    final normalized = rawValue.trim().toLowerCase();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is bool) return decoded;
    } catch (_) {
      // ignore
    }

    return false;
  }
}

