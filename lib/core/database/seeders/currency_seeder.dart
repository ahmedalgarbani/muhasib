import 'package:sqflite/sqflite.dart';

/// Seeds default currencies including the local/base currency
class CurrencySeeder {
  static Future<void> seed(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check if currencies already exist
    final currencies = await db.query('currencies');
    if (currencies.isNotEmpty) return;

    // Insert default local currency (Saudi Riyal)
    await db.insert('currencies', {
      'id': 1,
      'creator_id': 1,
      'last_modifier_id': 1,
      'creation_time': now,
      'last_modification_time': now,
      'name': 'ريال سعودي',
      'code': 'SAR',
      'symbol': 'ر.س',
      'min_exchange_rate': 1.0,
      'max_exchange_rate': 1.0,
      'exchange_rate': 1.0,
      'is_local_currency': 1, // This is the base/local currency
      'is_active': 1,
      'decimal_places': 2,
    });

    // Insert USD as a common secondary currency
    await db.insert('currencies', {
      'id': 2,
      'creator_id': 1,
      'last_modifier_id': 1,
      'creation_time': now,
      'last_modification_time': now,
      'name': 'دولار أمريكي',
      'code': 'USD',
      'symbol': '\$',
      'min_exchange_rate': 3.70,
      'max_exchange_rate': 3.80,
      'exchange_rate': 3.75,
      'is_local_currency': 0,
      'is_active': 1,
      'decimal_places': 2,
    });

    print('Default currencies seeded successfully');
  }

  /// Get the local/base currency
  static Future<Map<String, dynamic>?> getLocalCurrency(Database db) async {
    final result = await db.query(
      'currencies',
      where: 'is_local_currency = 1',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Check if a currency is the local currency
  static Future<bool> isLocalCurrency(Database db, int currencyId) async {
    final result = await db.query(
      'currencies',
      where: 'id = ? AND is_local_currency = 1',
      whereArgs: [currencyId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
