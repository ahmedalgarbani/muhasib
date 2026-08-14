import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/database/database_initializer_io.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/customers_table.dart';
import 'package:muhasib/core/database/tables/classifications_table.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/customers/data/datasources/customer_data_source.dart';

class TestDatabaseService implements DatabaseService {
  final Database _testDb;
  TestDatabaseService(this._testDb);

  @override
  Future<Database> get database async => _testDb;

  @override
  Future<void> close() async {
    await _testDb.close();
  }
}

Future<Database> createFreshTestDatabase() async {
  initializeDatabaseFactory();
  final tables = <TableSchema>[
    AccountsTable(),
    AccountConnectsTable(),
    CustomersTable(),
    ClassificationsTable(),
    JournalEntriesTable(),
    JournalEntryLinesTable(),
  ];

  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = OFF');
    },
    onCreate: (db, version) async {
      for (final table in tables) {
        await db.execute(table.createTable);
        for (final index in table.indexes) {
          try {
            await db.execute(index);
          } catch (_) {}
        }
      }

      await seedDefaultAccounts(db);
      await seedDefaultAccountConnects(db);
    },
  );

  return db;
}

void main() {
  setUpAll(() {
    initializeDatabaseFactory();
  });

  late Database db;
  late CustomerDataSourceImpl dataSource;

  setUp(() async {
    db = await createFreshTestDatabase();
    dataSource = CustomerDataSourceImpl(databaseService: TestDatabaseService(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('عميل برصيد افتتاحي مدين (عليه) → حساب مدين + قيد متوازن', () async {
    final customer = await dataSource.addCustomer(
      name: 'أحمد',
      type: 1,
      openingBalance: 500,
    );

    expect(customer.currentBalance, closeTo(500, 0.01));

    final accountId = customer.accountId!;
    final account = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
    );
    expect(
      (account.first['balance'] as num).toDouble(),
      closeTo(500, 0.01),
      reason: 'رصيد حساب العميل يجب أن يكون مديناً 500',
    );

    // قيد افتتاحي متوازن: مدين حساب العميل / دائن حساب الأرصدة الافتتاحية
    final entries = await db.query(
      'journal_entries',
      where: 'reference_type = ? AND reference_id = ?',
      whereArgs: ['opening_balance', accountId],
    );
    expect(entries.length, 1);
    final entry = entries.first;
    expect(entry['is_posted'], 1);
    expect(
      (entry['total_debit'] as num).toDouble(),
      closeTo((entry['total_credit'] as num).toDouble(), 0.01),
    );

    // حساب الأرصدة الافتتاحية أصبح دائناً 500
    final obAccount = await db.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['3100'],
    );
    expect(
      (obAccount.first['balance'] as num).toDouble(),
      closeTo(-500, 0.01),
    );
  });

  test('مورد برصيد افتتاحي مستحق له → حساب دائن (سالب) ويظهر له', () async {
    final supplier = await dataSource.addCustomer(
      name: 'مورد أحمد',
      type: 2,
      openingBalance: 300, // مستحق للمورد (له)
    );

    expect(supplier.currentBalance, closeTo(-300, 0.01));

    final account = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [supplier.accountId],
    );
    expect(
      (account.first['balance'] as num).toDouble(),
      closeTo(-300, 0.01),
      reason: 'رصيد حساب المورد يجب أن يكون دائناً (سالب بالعرف المدين)',
    );

    // القيد: مدين الأرصدة الافتتاحية / دائن حساب المورد
    final lines = await db.query(
      'journal_entry_lines',
      where: 'account_id = ?',
      whereArgs: [supplier.accountId],
    );
    expect(lines.length, 1);
    expect((lines.first['debit_amount'] as num).toDouble(), closeTo(0, 0.01));
    expect((lines.first['credit_amount'] as num).toDouble(), closeTo(300, 0.01));

    // القائمة تقرأ الرصيد من الحساب المرتبط
    final suppliers = await dataSource.getSuppliers();
    expect(suppliers.first.currentBalance, closeTo(-300, 0.01));
  });

  test('عميل برصيد دائن (له) → حساب دائن (سالب)', () async {
    final customer = await dataSource.addCustomer(
      name: 'عميل برصيد',
      type: 1,
      openingBalance: -200, // رصيد لصالح العميل
    );

    expect(customer.currentBalance, closeTo(-200, 0.01));

    final account = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [customer.accountId],
    );
    expect((account.first['balance'] as num).toDouble(), closeTo(-200, 0.01));
  });

  test('إضافة عميل بدون رصيد افتتاحي → لا قيد افتتاحي', () async {
    final customer = await dataSource.addCustomer(
      name: 'عميل عادي',
      type: 1,
    );

    expect(customer.currentBalance, closeTo(0, 0.01));

    final entries = await db.query(
      'journal_entries',
      where: 'reference_type = ? AND reference_id = ?',
      whereArgs: ['opening_balance', customer.accountId],
    );
    expect(entries, isEmpty);
  });
}
