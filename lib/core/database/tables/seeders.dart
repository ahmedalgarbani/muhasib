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
  
  // Seed account connections after accounts are created
  await seedDefaultAccountConnects(db);
}

Future<void> seedDefaultAccountConnects(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  
  // Check if account connects already exist
  final connects = await db.query('account_connects');
  if (connects.isNotEmpty) return;
  
  // Default account connections based on common accounting setup
  final defaultConnections = [
    {'type': 0, 'cId': 1110, 'name': 'البنوك'},         // Banks -> النقدية في البنوك
    {'type': 1, 'cId': 1110, 'name': 'الصناديق'},       // Cash -> الصندوق
    {'type': 2, 'cId': 1120, 'name': 'العملاء'},        // Customers -> العملاء
    {'type': 3, 'cId': 2110, 'name': 'الموردون'},       // Suppliers -> الموردون
    {'type': 4, 'cId': 2140, 'name': 'الضرائب'},        // Taxes -> ضرائب مستحقة
    {'type': 5, 'cId': 1130, 'name': 'المخزون'},        // Inventory -> المخزون
    {'type': 6, 'cId': 1130, 'name': 'البضاعة'},        // Goods -> المخزون (same as inventory)
    {'type': 7, 'cId': 4110, 'name': 'المبيعات'},       // Sales -> المبيعات
    {'type': 8, 'cId': 3150, 'name': 'الخصم المسموح به'}, // Discount Allowed -> خصومات ممنوحة
    {'type': 9, 'cId': 4140, 'name': 'الخصم المكتسب'},   // Discount Received -> خصومات مكتسبة
    {'type': 10, 'cId': 3110, 'name': 'المشتريات'},     // Purchases -> المشتريات
  ];
  
  for (final connection in defaultConnections) {
    // Check if the account exists before creating connection
    final accounts = await db.query(
      'accounts',
      where: 'c_id = ?',
      whereArgs: [connection['cId']],
      limit: 1,
    );
    
    if (accounts.isNotEmpty) {
      await db.insert('account_connects', {
        'account_connect_type': connection['type'],
        'c_id': connection['cId'],
        'creation_time': now,
        'last_modification_time': now,
        'creator_id': 1,
      });
      
      print('Created account connection: ${connection['name']} -> cId: ${connection['cId']}');
    } else {
      print('Warning: Account with cId ${connection['cId']} not found for ${connection['name']}');
    }
  }
  
  print('Default account connections seeded successfully');
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
    'code': '1001',
    'name': 'النقدية والبنوك',
    'is_master': 1,
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
    'code': '1002',
    'name': 'العملاء',
    'is_master': 1,
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
    'code': '1003',
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
    'code': '1004',
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
    'code': '1005',
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
    'code': '2001',
    'name': 'الموردون',
    'is_master': 1,
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
    'code': '2002',
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
    'code': '2003',
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
    'code': '2004',
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
    'code': '3001',
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
    'code': '3002',
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
    'code': '3003',
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
    'code': '3004',
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
    'code': '3005',
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

  // خسائر فروق صرف العملات (Exchange Rate Losses)
  await db.insert('accounts', {
    'c_id': 3170,
    'code': '3006',
    'name': 'خسائر فروق صرف العملات',
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

  // عمولات المبيعات (Sales Commission Expense)
  await db.insert('accounts', {
    'c_id': 3180,
    'code': '3007',
    'name': 'عمولات المبيعات',
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

  // عمولات مستحقة الدفع (Commission Payables)
  await db.insert('accounts', {
    'c_id': 2160,
    'code': '2005',
    'name': 'عمولات مستحقة الدفع',
    'is_master': 0,
    'master_id': 2,
    'master_c_id': 2000,
    'type': 2,
    'national': 1,
    'statement': 'قائمة المركز المالي',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // ضريبة القيمة المضافة - مدخلات (Input VAT - Recoverable)
  await db.insert('accounts', {
    'c_id': 1170,
    'code': '1006',
    'name': 'ضريبة مدخلات قابلة للاسترداد',
    'is_master': 0,
    'master_id': 1,
    'master_c_id': 1000,
    'type': 1,
    'national': 1,
    'statement': 'قائمة المركز المالي',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // ضريبة القيمة المضافة - مخرجات (Output VAT - Payable)
  await db.insert('accounts', {
    'c_id': 2170,
    'code': '2006',
    'name': 'ضريبة مخرجات مستحقة',
    'is_master': 0,
    'master_id': 2,
    'master_c_id': 2000,
    'type': 2,
    'national': 1,
    'statement': 'قائمة المركز المالي',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // المخزون (Inventory Asset)
  await db.insert('accounts', {
    'c_id': 1180,
    'code': '1007',
    'name': 'المخزون',
    'is_master': 0,
    'master_id': 1,
    'master_c_id': 1000,
    'type': 1,
    'national': 1,
    'statement': 'قائمة المركز المالي',
    'is_active': 1,
    'allow_update_delete': 1,
    'balance': 0.0,
    'local_balance': 0.0,
    'creation_time': now,
    'last_modification_time': now,
  });

  // تكلفة البضاعة المباعة (Cost of Goods Sold)
  await db.insert('accounts', {
    'c_id': 3190,
    'code': '3008',
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
    'code': '4001',
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
    'code': '4002',
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
    'code': '4003',
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
    'code': '4004',
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

  // أرباح فروق صرف العملات (Exchange Rate Gains)
  await db.insert('accounts', {
    'c_id': 4160,
    'code': '4005',
    'name': 'أرباح فروق صرف العملات',
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
    'code': '4006',
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
    'code': '3009',
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
