import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/database/database_initializer_io.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/database/seeders/settings_seeder.dart';
import 'package:muhasib/core/database/seeders/currency_seeder.dart';
import 'package:muhasib/core/database/seeders/payment_methods_seeder.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/core/database/tables/app_users_table.dart';
import 'package:muhasib/core/database/tables/settings_table.dart';
import 'package:muhasib/core/database/tables/customers_table.dart';
import 'package:muhasib/core/database/tables/suppliers_table.dart';
import 'package:muhasib/core/database/tables/classifications_table.dart';
import 'package:muhasib/features/customers/data/datasources/customer_data_source.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';

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
    CurrenciesTable(),
    AppUsersTable(),
    SettingsTable(),
    AccountsTable(),
    AccountConnectsTable(),
    JournalEntriesTable(),
    JournalEntryLinesTable(),
    CustomersTable(),
    SuppliersTable(),
    ClassificationsTable(),
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

      await SettingsSeeder.seed(db);
      await CurrencySeeder.seed(db);
      await seedDefaultAccounts(db);
    },
  );

  return db;
}

void main() {
  late Database db;
  late DatabaseService databaseService;
  late CustomerDataSource customerDataSource;

  setUpAll(() {
    initializeDatabaseFactory();
  });

  setUp(() async {
    db = await createFreshTestDatabase();
    databaseService = TestDatabaseService(db);
    customerDataSource = CustomerDataSourceImpl(databaseService: databaseService);
  });

  tearDown(() async {
    await db.close();
  });

  group('🔬 تدقيق إضافة العميل والمورد والرصيد الافتتاحي (Opening Balance & Profile Audit)', () {
    test('1. إضافة عميل برصيد افتتاحي مدين (عليه) → قيد مرحل ومدين لحساب العميل', () async {
      final customer = await customerDataSource.addCustomer(
        name: 'عميل آجل مدين',
        type: 1,
        contact: '777111222',
        address: 'صنعاء - شارع الستين',
        creditLimit: 5000.0,
        openingBalance: 1500.0, // عليه (مدين)
      );

      expect(customer.name, 'عميل آجل مدين');
      expect(customer.currentBalance, 1500.0);
      expect(customer.creditLimit, 5000.0);
      expect(customer.address, 'صنعاء - شارع الستين');
      expect(customer.accountId, isNotNull);

      // Verify journal entry created and posted
      final journalEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['opening_balance', customer.accountId],
      );

      expect(journalEntries.length, 1);
      final je = journalEntries.first;
      expect(je['is_posted'], 1); // Must be posted
      expect(je['total_debit'], 1500.0);
      expect(je['total_credit'], 1500.0);
      expect((je['description'] as String).contains('مدين (عليه)'), isTrue);

      // Verify journal lines: Line 1 = Debit Customer, Line 2 = Credit OB (3100)
      final lines = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [je['id']],
        orderBy: 'line_number ASC',
      );
      expect(lines.length, 2);
      expect(lines[0]['account_id'], customer.accountId);
      expect(lines[0]['debit_amount'], 1500.0);
      expect(lines[0]['credit_amount'], 0.0);

      expect(lines[1]['account_code'], '3100');
      expect(lines[1]['debit_amount'], 0.0);
      expect(lines[1]['credit_amount'], 1500.0);
    });

    test('2. إضافة عميل برصيد افتتاحي دائن (له / دفع مقدماً) → قيد مرحل ودائن لحساب العميل', () async {
      final customer = await customerDataSource.addCustomer(
        name: 'عميل دائن مقدماً',
        type: 1,
        contact: '777333444',
        openingBalance: -800.0, // له (دائن)
      );

      expect(customer.name, 'عميل دائن مقدماً');
      expect(customer.currentBalance, -800.0);

      // Verify journal entry
      final journalEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['opening_balance', customer.accountId],
      );

      expect(journalEntries.length, 1);
      final je = journalEntries.first;
      expect(je['is_posted'], 1);
      expect(je['total_debit'], 800.0);
      expect(je['total_credit'], 800.0);
      expect((je['description'] as String).contains('دائن (له)'), isTrue);

      // Verify lines: Line 1 = Debit OB (3100), Line 2 = Credit Customer
      final lines = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [je['id']],
        orderBy: 'line_number ASC',
      );
      expect(lines.length, 2);
      expect(lines[0]['account_code'], '3100');
      expect(lines[0]['debit_amount'], 800.0);
      expect(lines[0]['credit_amount'], 0.0);

      expect(lines[1]['account_id'], customer.accountId);
      expect(lines[1]['debit_amount'], 0.0);
      expect(lines[1]['credit_amount'], 800.0);
    });

    test('3. إضافة مورد برصيد افتتاحي دائن (له / مستحق له) → قيد مرحل ودائن لحساب المورد', () async {
      final supplier = await customerDataSource.addCustomer(
        name: 'شركة النور للمواد الغذائية',
        type: 2, // supplier
        contact: '777555666',
        openingBalance: 3000.0, // له (دائن)
      );

      expect(supplier.name, 'شركة النور للمواد الغذائية');
      // العرف المحاسبي (مدين - دائن): مستحق للمورد = دائن = سالب
      expect(supplier.currentBalance, -3000.0);

      final journalEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['opening_balance', supplier.accountId],
      );

      expect(journalEntries.length, 1);
      final je = journalEntries.first;
      expect(je['is_posted'], 1);
      expect(je['total_debit'], 3000.0);
      expect(je['total_credit'], 3000.0);
      expect((je['description'] as String).contains('دائن (له)'), isTrue);

      // Verify lines: Line 1 = Debit OB (3100), Line 2 = Credit Supplier
      final lines = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [je['id']],
        orderBy: 'line_number ASC',
      );
      expect(lines.length, 2);
      expect(lines[0]['account_code'], '3100');
      expect(lines[0]['debit_amount'], 3000.0);
      expect(lines[0]['credit_amount'], 0.0);

      expect(lines[1]['account_id'], supplier.accountId);
      expect(lines[1]['debit_amount'], 0.0);
      expect(lines[1]['credit_amount'], 3000.0);
    });

    test('4. إضافة مورد برصيد افتتاحي مدين (عليه / دفعة مقدمة) → قيد مرحل ومدين لحساب المورد', () async {
      final supplier = await customerDataSource.addCustomer(
        name: 'مؤسسة التقنية للمعدات',
        type: 2,
        contact: '777999000',
        openingBalance: -1200.0, // عليه (دفعة مقدمة / مدين)
      );

      expect(supplier.name, 'مؤسسة التقنية للمعدات');
      // دفعة مقدمة للمورد = مدين = موجب بالعرف المحاسبي
      expect(supplier.currentBalance, 1200.0);

      final journalEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['opening_balance', supplier.accountId],
      );

      expect(journalEntries.length, 1);
      final je = journalEntries.first;
      expect(je['is_posted'], 1);
      expect(je['total_debit'], 1200.0);
      expect(je['total_credit'], 1200.0);
      expect((je['description'] as String).contains('مدين (عليه)'), isTrue);

      // Verify lines: Line 1 = Debit Supplier, Line 2 = Credit OB (3100)
      final lines = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [je['id']],
        orderBy: 'line_number ASC',
      );
      expect(lines.length, 2);
      expect(lines[0]['account_id'], supplier.accountId);
      expect(lines[0]['debit_amount'], 1200.0);
      expect(lines[0]['credit_amount'], 0.0);

      expect(lines[1]['account_code'], '3100');
      expect(lines[1]['debit_amount'], 0.0);
      expect(lines[1]['credit_amount'], 1200.0);
    });

    test('5. التحقق من دقة حساب وعرض معلومات الرصيد (PartyBalanceInfo)', () {
      // Customer checks
      final customerDebit = PartyBalanceInfo.fromBalance(balance: 1000, isSupplier: false);
      expect(customerDebit.label, 'عليه (مدين)');
      expect(customerDebit.formattedAmount, '1000.00 ر.س');
      expect(customerDebit.isZero, false);

      final customerCredit = PartyBalanceInfo.fromBalance(balance: -500, isSupplier: false);
      expect(customerCredit.label, 'له (دائن)');
      expect(customerCredit.formattedAmount, '500.00 ر.س');
      expect(customerCredit.isZero, false);

      final customerZero = PartyBalanceInfo.fromBalance(balance: 0, isSupplier: false);
      expect(customerZero.label, 'متوازن');
      expect(customerZero.formattedAmount, '0.00 ر.س');
      expect(customerZero.isZero, true);

      // Supplier checks (debit-normal convention)
      final supplierCredit = PartyBalanceInfo.fromBalance(balance: -2000, isSupplier: true);
      expect(supplierCredit.label, 'له (دائن)');
      expect(supplierCredit.formattedAmount, '2000.00 ر.س');
      expect(supplierCredit.isZero, false);

      final supplierDebit = PartyBalanceInfo.fromBalance(balance: 300, isSupplier: true);
      expect(supplierDebit.label, 'عليه (مدين)');
      expect(supplierDebit.formattedAmount, '300.00 ر.س');
      expect(supplierDebit.isZero, false);

      final supplierZero = PartyBalanceInfo.fromBalance(balance: 0, isSupplier: true);
      expect(supplierZero.label, 'متوازن');
      expect(supplierZero.formattedAmount, '0.00 ر.س');
      expect(supplierZero.isZero, true);
    });

    test('6. تعديل بيانات العميل ومزامنة الاسم في الحساب المرتبط', () async {
      final customer = await customerDataSource.addCustomer(
        name: 'عميل للتعديل',
        type: 1,
        contact: '777000111',
        address: 'العنوان القديم',
        creditLimit: 1000,
      );

      final updated = await customerDataSource.updateCustomer(
        customerId: customer.id,
        name: 'عميل معدل بالكامل',
        contact: '777999888',
        address: 'العنوان الجديد - شارع حده',
        creditLimit: 2500,
      );

      expect(updated.name, 'عميل معدل بالكامل');
      expect(updated.contact, '777999888');
      expect(updated.address, 'العنوان الجديد - شارع حده');
      expect(updated.creditLimit, 2500);

      // Verify account name updated in accounts table
      final accountRow = await db.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [customer.accountId],
      );
      expect(accountRow.first['name'], 'عميل معدل بالكامل');
    });

    test('7. حذف (إلغاء تفعيل) العميل بنجاح', () async {
      final customer = await customerDataSource.addCustomer(
        name: 'عميل للحذف',
        type: 1,
      );

      await customerDataSource.deleteCustomer(customer.id);

      final listActive = await customerDataSource.getCustomers(includeInactive: false);
      expect(listActive.any((c) => c.id == customer.id), isFalse);

      final listAll = await customerDataSource.getCustomers(includeInactive: true);
      expect(listAll.any((c) => c.id == customer.id && !c.isActive), isTrue);
    });
  });
}
