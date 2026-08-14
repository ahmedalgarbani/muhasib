import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class TaxSeeder {
  static Future<void> seed(Database db) async {
    final settingsRows = await db.query(
      'settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['stock_setting'],
      limit: 1,
    );
    if (settingsRows.isEmpty) return;

    Map<String, dynamic> stockSetting;
    try {
      final decoded = json.decode(settingsRows.first['setting_value'] as String);
      if (decoded is! Map) return;
      stockSetting = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    final rate = (stockSetting['default_tax_rate'] as num?)?.toDouble() ?? 15;
    final name = stockSetting['tax_name'] as String? ?? 'ضريبة القيمة المضافة';

    final existing = await db.query(
      'taxes',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert(
      'taxes',
      {
        'name': name,
        'ratio': rate,
        'is_active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
