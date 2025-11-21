import 'package:sqflite/sqflite.dart';

Future<void> seedDefaultStocks(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Check if stocks already exist
  final stocks = await db.query('stocks');
  if (stocks.isNotEmpty) return;

  // Insert default main stock
  await db.insert('stocks', {
    'id': 1,
    'name': 'المخزن الرئيسي',
    'address': 'المقر الرئيسي',
    'is_main_stock': 1,
    'is_active': 1,
    'creation_time': now,
    'last_modification_time': now,
  });

  await db.insert('stocks', {
    'id': 2,
    'name': 'مخزن الفرع',
    'address': 'الفرع الأول',
    'is_main_stock': 0,
    'is_active': 1,
    'creation_time': now,
    'last_modification_time': now,
  });
}

Future<void> seedDefaultCustomers(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Check if customers already exist
  final customers = await db.query('customers');
  if (customers.isNotEmpty) return;

  // Check if classifications table exists and has data
  final classifications = await db.query('classifications');
  if (classifications.isEmpty) {
    // Create default classification
    await db.insert('classifications', {
      'id': 1,
      'name': 'عملاء عاديين',
      'singler_name': 'عميل',
      'order': 1,
      'type': 1,
      'creation_time': now,
      'last_modification_time': now,
    });
  }

  // Insert default customers
  await db.insert('customers', {
    'id': 1,
    'name': 'عميل نقدي',
    'type': 1,
    'classification': 1,
    'classification_id': 1,
    'is_active': 1,
    'credit_limit': 0.0,
    'current_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  await db.insert('customers', {
    'id': 2,
    'name': 'عميل آجل',
    'type': 2,
    'classification': 1,
    'classification_id': 1,
    'is_active': 1,
    'credit_limit': 10000.0,
    'current_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });
}

Future<void> seedDefaultAccounts(Database db) async {
  await db.delete('accounts');

  await db.execute('DELETE FROM sqlite_sequence WHERE name="accounts"');

  await _seedAssets(db);
  await _seedLiabilitiesAndEquity(db);
  await _seedExpenses(db);
  await _seedRevenues(db);
}

// أصول (Assets)
Future<void> _seedAssets(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  await db.insert('accounts', {
    'c_id': 1000,
    'code': '1',
    'name': 'الأصول',
    'is_master': 1,
    'master_id': null,
    'master_c_id': null,
    'type': 1,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 0,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // النقدية والبنوك
  await db.insert('accounts', {
    'c_id': 1110,
    'code': '111',
    'name': 'النقدية والبنوك',
    'is_master': 0,
    'master_id': 1,
    'master_c_id': 1000,
    'type': 1,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // العملاء
  await db.insert('accounts', {
    'c_id': 1120,
    'code': '112',
    'name': 'العملاء',
    'is_master': 0,
    'master_id': 1,
    'master_c_id': 1000,
    'type': 1,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // المخزون
  await db.insert('accounts', {
    'c_id': 1130,
    'code': '113',
    'name': 'المخزون',
    'is_master': 0,
    'master_id': 1,
    'master_c_id': 1000,
    'type': 1,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // الأصول الثابتة
  await db.insert('accounts', {
    'c_id': 1140,
    'code': '114',
    'name': 'الأصول الثابتة',
    'is_master': 0,
    'master_id': 1,
    'master_c_id': 1000,
    'type': 1,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // الاستثمارات
  await db.insert('accounts', {
    'c_id': 1150,
    'code': '115',
    'name': 'الاستثمارات',
    'is_master': 0,
    'master_id': 1,
    'master_c_id': 1000,
    'type': 1,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });
}

// التزامات وحقوق الملكية (Liabilities & Equity)
Future<void> _seedLiabilitiesAndEquity(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  // Main Liabilities Category
  await db.insert('accounts', {
    'c_id': 2000,
    'code': '2',
    'name': 'التزامات وحقوق الملكية',
    'is_master': 1,
    'master_id': null,
    'master_c_id': null,
    'type': 2,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 0,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // الموردون
  await db.insert('accounts', {
    'c_id': 2110,
    'code': '211',
    'name': 'الموردون',
    'is_master': 0,
    'master_id': 2,
    'master_c_id': 2000,
    'type': 2,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // رأس المال
  await db.insert('accounts', {
    'c_id': 2120,
    'code': '212',
    'name': 'رأس المال',
    'is_master': 0,
    'master_id': 2,
    'master_c_id': 2000,
    'type': 2,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // القروض والسلف
  await db.insert('accounts', {
    'c_id': 2130,
    'code': '213',
    'name': 'القروض والسلف',
    'is_master': 0,
    'master_id': 2,
    'master_c_id': 2000,
    'type': 2,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // الضرائب المستحقة
  await db.insert('accounts', {
    'c_id': 2140,
    'code': '214',
    'name': 'الضرائب المستحقة',
    'is_master': 0,
    'master_id': 2,
    'master_c_id': 2000,
    'type': 2,
    'national': 1,
    'statement': 'الميزانية العمومية',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });
}

// مصروفات (Expenses)
Future<void> _seedExpenses(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  // Main Expenses Category
  await db.insert('accounts', {
    'c_id': 3000,
    'code': '3',
    'name': 'المصروفات',
    'is_master': 1,
    'master_id': null,
    'master_c_id': null,
    'type': 3,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 0,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // المشتريات
  await db.insert('accounts', {
    'c_id': 3110,
    'code': '311',
    'name': 'المشتريات',
    'is_master': 0,
    'master_id': 3,
    'master_c_id': 3000,
    'type': 3,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // الرواتب والأجور
  await db.insert('accounts', {
    'c_id': 3120,
    'code': '312',
    'name': 'الرواتب والأجور',
    'is_master': 0,
    'master_id': 3,
    'master_c_id': 3000,
    'type': 3,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // مصاريف إدارية
  await db.insert('accounts', {
    'c_id': 3130,
    'code': '313',
    'name': 'مصاريف إدارية',
    'is_master': 0,
    'master_id': 3,
    'master_c_id': 3000,
    'type': 3,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // مصاريف تشغيلية
  await db.insert('accounts', {
    'c_id': 3140,
    'code': '314',
    'name': 'مصاريف تشغيلية',
    'is_master': 0,
    'master_id': 3,
    'master_c_id': 3000,
    'type': 3,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // الخصم المسموح به
  await db.insert('accounts', {
    'c_id': 3150,
    'code': '315',
    'name': 'الخصم المسموح به',
    'is_master': 0,
    'master_id': 3,
    'master_c_id': 3000,
    'type': 3,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });
}

// إيرادات (Revenues)
Future<void> _seedRevenues(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  // Main Revenues Category
  await db.insert('accounts', {
    'c_id': 4000,
    'code': '4',
    'name': 'الإيرادات',
    'is_master': 1,
    'master_id': null,
    'master_c_id': null,
    'type': 4,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 0,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // المبيعات
  await db.insert('accounts', {
    'c_id': 4110,
    'code': '411',
    'name': 'المبيعات',
    'is_master': 0,
    'master_id': 4,
    'master_c_id': 4000,
    'type': 4,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // إيرادات أخرى
  await db.insert('accounts', {
    'c_id': 4120,
    'code': '412',
    'name': 'إيرادات أخرى',
    'is_master': 0,
    'master_id': 4,
    'master_c_id': 4000,
    'type': 4,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // إيرادات الخدمات
  await db.insert('accounts', {
    'c_id': 4130,
    'code': '413',
    'name': 'إيرادات الخدمات',
    'is_master': 0,
    'master_id': 4,
    'master_c_id': 4000,
    'type': 4,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // الخصم المكتسب
  await db.insert('accounts', {
    'c_id': 4140,
    'code': '414',
    'name': 'الخصم المكتسب',
    'is_master': 0,
    'master_id': 4,
    'master_c_id': 4000,
    'type': 4,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // مرتجعات المبيعات (Sales Returns - Contra Revenue)
  await db.insert('accounts', {
    'c_id': 4150,
    'code': '415',
    'name': 'مرتجعات المبيعات',
    'is_master': 0,
    'master_id': 4,
    'master_c_id': 4000,
    'type': 4,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // تكلفة البضاعة المباعة (Cost of Goods Sold)
  await db.insert('accounts', {
    'c_id': 3160,
    'code': '316',
    'name': 'تكلفة البضاعة المباعة',
    'is_master': 0,
    'master_id': 3,
    'master_c_id': 3000,
    'type': 3,
    'national': 1,
    'statement': 'قائمة الدخل',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });
}
