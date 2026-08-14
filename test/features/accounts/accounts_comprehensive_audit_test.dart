import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/database/database_initializer_io.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/database/seeders/settings_seeder.dart';
import 'package:muhasib/core/database/seeders/tax_seeder.dart';
import 'package:muhasib/core/database/seeders/currency_seeder.dart';
import 'package:muhasib/core/database/seeders/payment_methods_seeder.dart';
import 'package:muhasib/core/errors/exceptions.dart';

// Accounts domain & data
import 'package:muhasib/features/accounts/data/datasources/account_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/account_connect_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/journal_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/voucher_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/opening_balance_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/account_limit_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/fiscal_period_datasource.dart';
import 'package:muhasib/features/accounts/data/models/account_model.dart';
import 'package:muhasib/features/accounts/data/models/account_connect_model.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_model.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_line_model.dart';
import 'package:muhasib/features/accounts/data/models/voucher_model.dart';
import 'package:muhasib/features/accounts/data/models/opening_balance_model.dart';
import 'package:muhasib/features/accounts/data/models/account_limit_model.dart';
import 'package:muhasib/features/accounts/data/models/fiscal_period_model.dart';
import 'package:muhasib/features/accounts/data/repositories/account_connect_repository_impl.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';
import 'package:muhasib/features/accounts/domain/services/account_connect_validator.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';
import 'package:muhasib/features/accounts/data/services/account_limit_service_impl.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';

import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/core/database/tables/app_users_table.dart';
import 'package:muhasib/core/database/tables/settings_table.dart';
import 'package:muhasib/core/database/tables/account_limits_table.dart';
import 'package:muhasib/core/database/tables/account_currencies_table.dart';
import 'package:muhasib/core/database/tables/account_limit_logs_table.dart';
import 'package:muhasib/core/database/tables/vouchers_table.dart';
import 'package:muhasib/core/database/tables/voucher_lines_table.dart';
import 'package:muhasib/core/database/tables/opening_entries_table.dart';
import 'package:muhasib/core/database/tables/opening_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/customers_table.dart';
import 'package:muhasib/core/database/tables/suppliers_table.dart';
import 'package:muhasib/core/database/tables/banks_table.dart';
import 'package:muhasib/core/database/tables/payment_methods_table.dart';
import 'package:muhasib/core/database/tables/unified_payments_table.dart';
import 'package:muhasib/core/database/tables/taxes_table.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';

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
    TaxesTable(),
    PaymentMethodTypesTable(),
    PaymentMethodsTable(),
    AccountsTable(),
    AccountLimitsTable(),
    AccountLimitLogsTable(),
    AccountCurrenciesTable(),
    AccountConnectsTable(),
    JournalEntriesTable(),
    JournalEntryLinesTable(),
    VouchersTable(),
    VoucherLinesTable(),
    OpeningEntriesTable(),
    OpeningEntryLinesTable(),
    CustomersTable(),
    SuppliersTable(),
    BanksTable(),
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

      // Create fiscal_periods table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fiscal_periods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          year INTEGER NOT NULL,
          period INTEGER NOT NULL,
          start_date INTEGER NOT NULL,
          end_date INTEGER NOT NULL,
          status INTEGER NOT NULL DEFAULT 0,
          is_closed INTEGER NOT NULL DEFAULT 0,
          closed_by INTEGER NULL,
          closed_at INTEGER NULL,
          notes TEXT NULL,
          creation_time INTEGER NOT NULL DEFAULT 0,
          last_modification_time INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Seed standard tables
      await SettingsSeeder.seed(db);
      await TaxSeeder.seed(db);
      await CurrencySeeder.seed(db);
      await PaymentMethodsSeeder.seed(db);
      await seedDefaultAccounts(db);

      // Create an open active fiscal period covering a wide range
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.insert('fiscal_periods', {
        'year': 2026,
        'period': 1,
        'start_date': nowSec - 365 * 86400,
        'end_date': nowSec + 365 * 86400,
        'is_closed': 0,
        'status': 0,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
    },
  );

  return db;
}

void main() {
  setUpAll(() {
    initializeDatabaseFactory();
  });

  group('🔬 التدقيق المحاسبي والبرمجي المكثف لقسم الحسابات (Accounting & Engineering Audit)', () {
    late Database db;
    late TestDatabaseService dbService;
    late AccountLocalDataSource accountDataSource;
    late AccountConnectLocalDataSource connectDataSource;
    late JournalLocalDataSource journalDataSource;
    late VoucherLocalDataSource voucherDataSource;
    late OpeningBalanceLocalDataSource openingBalanceDataSource;
    late AccountLimitLocalDataSource limitDataSource;
    late AccountLimitService limitService;
    late AccountLimitInterceptor limitInterceptor;
    late AccountConnectValidator connectValidator;
    late FiscalPeriodDataSource fiscalPeriodDataSource;

    setUp(() async {
      db = await createFreshTestDatabase();
      dbService = TestDatabaseService(db);
      accountDataSource = AccountLocalDataSourceImpl(db);
      connectDataSource = AccountConnectLocalDataSourceImpl(database: db);
      journalDataSource = JournalLocalDataSourceImpl(database: db);
      voucherDataSource = VoucherLocalDataSourceImpl(database: db);
      openingBalanceDataSource = OpeningBalanceLocalDataSourceImpl(databaseService: dbService);
      limitDataSource = AccountLimitLocalDataSourceImpl(databaseService: dbService);
      limitService = AccountLimitServiceImpl(localDataSource: limitDataSource);
      limitInterceptor = AccountLimitInterceptor(limitService: limitService);
      fiscalPeriodDataSource = FiscalPeriodDataSourceImpl(database: db);
      
      final connectRepo = AccountConnectRepositoryImpl(localDataSource: connectDataSource);
      connectValidator = AccountConnectValidator(repository: connectRepo);
    });

    tearDown(() async {
      await db.close();
    });

    // =========================================================================
    // 1. دليل الحسابات (Chart of Accounts)
    // =========================================================================
    group('1. دليل الحسابات (Chart of Accounts)', () {
      test('تحقق من وجود الحسابات الرئيسية الخمسة القياسية (أصول، خصوم، حقوق ملكية، إيرادات، مصروفات)', () async {
        final accounts = await accountDataSource.getAllAccounts();
        expect(accounts.isNotEmpty, isTrue);

        final masterAccounts = await accountDataSource.getMasterAccounts();
        final masterNames = masterAccounts.map((a) => a.name).toList();

        // Verify fundamental master account types
        expect(masterNames.any((n) => n.contains('الأصول')), isTrue);
        expect(masterNames.any((n) => n.contains('التزامات') || n.contains('خصوم') || n.contains('الملكية')), isTrue);
        expect(masterNames.any((n) => n.contains('الإيرادات') || n.contains('المبيعات')), isTrue);
        expect(masterNames.any((n) => n.contains('المصروفات') || n.contains('التكاليف')), isTrue);
      });

      test('إضافة حساب فرعي جديد وربطه بالحساب الرئيسي بنجاح', () async {
        final masters = await accountDataSource.getMasterAccounts();
        final assetMaster = masters.firstWhere((a) => a.type == 1); // الأصول

        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final newAccount = AccountModel(
          cId: 11199,
          code: '1001099',
          name: 'صندوق الفرع الثاني - نقدية',
          isMaster: false,
          masterId: assetMaster.id,
          type: 1, // أصول
          national: 1,
          balance: 0.0,
          localBalance: 0.0,
          isActive: true,
          creationTime: nowSec,
          lastModificationTime: nowSec,
        );

        final insertedId = await accountDataSource.insertAccount(newAccount);
        expect(insertedId, isPositive);

        final retrieved = await accountDataSource.getAccountById(insertedId);
        expect(retrieved.name, 'صندوق الفرع الثاني - نقدية');
        expect(retrieved.masterId, assetMaster.id);
        expect(retrieved.type, 1);
      });

      test('البحث في دليل الحسابات بالاسم أو الرمز (Code/Name search)', () async {
        final results = await accountDataSource.searchAccounts('النقدية');
        expect(results.isNotEmpty, isTrue);
        expect(results.any((a) => a.name.contains('النقدية')), isTrue);
      });
    });

    // =========================================================================
    // 2. ربط الحسابات (Account Mapping / Linking)
    // =========================================================================
    group('2. ربط الحسابات (Account Mapping / Linking)', () {
      test('فحص ربط الحسابات التلقائي والتحقق من اكتمال الـ 11 رابط محاسبي قياسي', () async {
        final allConnects = await connectDataSource.getAllAccountConnects();
        expect(allConnects.length, 11);

        // Check if Sales & Cash are connected
        final isCashConnected = await connectValidator.isAccountTypeConnected(1);
        expect(isCashConnected.getOrElse(() => false), isTrue);

        final isCustomerConnected = await connectValidator.isAccountTypeConnected(2);
        expect(isCustomerConnected.getOrElse(() => false), isTrue);

        // Validation result should be valid
        final validationResult = await connectValidator.validateAllConnections();
        expect(validationResult.isRight(), isTrue);
        validationResult.fold(
          (failure) => fail('Validation should succeed'),
          (result) {
            expect(result.isValid, isTrue);
            expect(result.connectedCount, 11);
            expect(result.missingConnections.isEmpty, isTrue);
          },
        );

        // Verify operations validation
        final salesValidation = await connectValidator.validateForSalesOperation();
        expect(salesValidation.getOrElse(() => false), isTrue);

        final purchaseValidation = await connectValidator.validateForPurchaseOperation();
        expect(purchaseValidation.getOrElse(() => false), isTrue);

        final paymentValidation = await connectValidator.validateForPaymentOperation();
        expect(paymentValidation.getOrElse(() => false), isTrue);
      });

      test('التحقق من اعتراض العمليات المحاسبية عند حذف ربط حساب مطلوب', () async {
        // Delete customers mapping (connectType: 2)
        final allConnects = await connectDataSource.getAllAccountConnects();
        final customerConnect = allConnects.firstWhere((c) => c.accountConnectType == 2);
        await connectDataSource.deleteAccountConnect(customerConnect.id!);

        connectValidator.clearCache();

        final salesValidation = await connectValidator.validateForSalesOperation();
        expect(salesValidation.isLeft(), isTrue); // Should be blocked because Customer account is not mapped!
      });
    });

    // =========================================================================
    // 3. القيود اليومية (Journal Entries - Double-Entry Bookkeeping)
    // =========================================================================
    group('3. القيود اليومية وقاعدة القيد المزدوج (Double-Entry Journal System)', () {
      test('رفض القيد غير المتوازن (Debits != Credits) بحزم محاسبي', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final acc1 = accounts[0];
        final acc2 = accounts[1];

        final unbalancedEntry = JournalEntryModel(
          number: 'JV-00001',
          entryDate: DateTime.now(),
          description: 'قيد غير متوازن',
          referenceType: 'manual',
          totalDebit: 1000.0,
          totalCredit: 950.0,
          difference: 50.0,
          lines: [
            JournalEntryLineModel(
              lineNumber: 1,
              accountId: acc1.id,
              accountCode: acc1.code,
              accountName: acc1.name,
              currencyCode: 'SAR',
              debit: 1000.0,
              credit: 0.0,
            ),
            JournalEntryLineModel(
              lineNumber: 2,
              accountId: acc2.id,
              accountCode: acc2.code,
              accountName: acc2.name,
              currencyCode: 'SAR',
              debit: 0.0,
              credit: 950.0, // Unbalanced! Difference = 50.0
            ),
          ],
        );

        expect(
          () async => await journalDataSource.insertJournalEntry(unbalancedEntry),
          throwsA(isA<LocalStorageException>()),
        );
      });

      test('إدخال قيد يومية متوازن وتحديث أرصدة الحسابات بدقة متناهية (Double-Entry Balance Update)', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final debitAcc = accounts.firstWhere((a) => !a.isMaster && a.type == 1); // Asset/Cash
        final creditAcc = accounts.firstWhere((a) => !a.isMaster && (a.type == 4 || a.type == 2)); // Revenue/Liability

        final initialDebitBal = debitAcc.balance;
        final initialCreditBal = creditAcc.balance;

        final balancedEntry = JournalEntryModel(
          number: 'JV-00002',
          entryDate: DateTime.now(),
          description: 'مبيعات نقدية مباشرة',
          referenceType: 'manual',
          isPosted: true,
          totalDebit: 500.0,
          totalCredit: 500.0,
          difference: 0.0,
          lines: [
            JournalEntryLineModel(
              lineNumber: 1,
              accountId: debitAcc.id,
              accountCode: debitAcc.code,
              accountName: debitAcc.name,
              currencyCode: 'SAR',
              debit: 500.0,
              credit: 0.0,
            ),
            JournalEntryLineModel(
              lineNumber: 2,
              accountId: creditAcc.id,
              accountCode: creditAcc.code,
              accountName: creditAcc.name,
              currencyCode: 'SAR',
              debit: 0.0,
              credit: 500.0,
            ),
          ],
        );

        final entryId = await journalDataSource.insertJournalEntry(balancedEntry);
        expect(entryId, isPositive);

        // Check account balances after entry
        final updatedDebitAcc = await accountDataSource.getAccountById(debitAcc.id!);
        final updatedCreditAcc = await accountDataSource.getAccountById(creditAcc.id!);

        expect(updatedDebitAcc.balance, closeTo(initialDebitBal + 500.0, 0.001));
        expect(updatedCreditAcc.balance, closeTo(initialCreditBal - 500.0, 0.001));
      });

      test('عكس وتعديل القيد اليومي (Reversal & Update) وضبط الأرصدة بدون تسريب مالي', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final debitAcc = accounts.firstWhere((a) => !a.isMaster && a.type == 1);
        final creditAcc = accounts.firstWhere((a) => !a.isMaster && a.id != debitAcc.id);

        final balBefore = (await accountDataSource.getAccountById(debitAcc.id!)).balance;

        // 1. Insert entry of 300
        final entry = JournalEntryModel(
          number: 'JV-00003',
          entryDate: DateTime.now(),
          description: 'قيد قابل للتعديل',
          isPosted: false,
          totalDebit: 300.0,
          totalCredit: 300.0,
          difference: 0.0,
          lines: [
            JournalEntryLineModel(
              lineNumber: 1,
              accountId: debitAcc.id,
              accountCode: debitAcc.code,
              accountName: debitAcc.name,
              currencyCode: 'SAR',
              debit: 300.0,
              credit: 0.0,
            ),
            JournalEntryLineModel(
              lineNumber: 2,
              accountId: creditAcc.id,
              accountCode: creditAcc.code,
              accountName: creditAcc.name,
              currencyCode: 'SAR',
              debit: 0.0,
              credit: 300.0,
            ),
          ],
        );

        final entryId = await journalDataSource.insertJournalEntry(entry);
        expect((await accountDataSource.getAccountById(debitAcc.id!)).balance, closeTo(balBefore + 300.0, 0.001));

        // 2. Update entry to 450
        final updatedEntry = JournalEntryModel(
          id: entryId,
          number: 'JV-00003',
          entryDate: DateTime.now(),
          description: 'قيد معدل',
          isPosted: false,
          totalDebit: 450.0,
          totalCredit: 450.0,
          difference: 0.0,
          lines: [
            JournalEntryLineModel(
              lineNumber: 1,
              accountId: debitAcc.id,
              accountCode: debitAcc.code,
              accountName: debitAcc.name,
              currencyCode: 'SAR',
              debit: 450.0,
              credit: 0.0,
            ),
            JournalEntryLineModel(
              lineNumber: 2,
              accountId: creditAcc.id,
              accountCode: creditAcc.code,
              accountName: creditAcc.name,
              currencyCode: 'SAR',
              debit: 0.0,
              credit: 450.0,
            ),
          ],
        );

        await journalDataSource.updateJournalEntry(updatedEntry);
        expect((await accountDataSource.getAccountById(debitAcc.id!)).balance, closeTo(balBefore + 450.0, 0.001));

        // 3. Delete entry -> balances must revert back to initial state
        await journalDataSource.deleteJournalEntry(entryId);
        expect((await accountDataSource.getAccountById(debitAcc.id!)).balance, closeTo(balBefore, 0.001));
      });
    });

    // =========================================================================
    // 4. السندات (Vouchers: Receipt & Payment)
    // =========================================================================
    group('4. دورة السندات المحاسبية (Receipt & Payment Vouchers)', () {
      test('سند قبض (Receipt Voucher): زيادة النقدية/البنك ودائنية الحساب المقابل مع إنشاء قيد آلي RV', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final bankAcc = accounts.firstWhere((a) => !a.isMaster && a.type == 1);
        final customerAcc = accounts.firstWhere((a) => !a.isMaster && a.id != bankAcc.id);

        final bankBalBefore = (await accountDataSource.getAccountById(bankAcc.id!)).balance;
        final custBalBefore = (await accountDataSource.getAccountById(customerAcc.id!)).balance;

        final voucher = VoucherModel(
          type: VoucherType.receipt, // سند قبض
          number: 101,
          date: DateTime.now(),
          accountId: bankAcc.id!, // الصندوق أو البنك المستلم (مدين)
          amount: 1500.0,
          statement: 'سند قبض دفعة من عميل',
          isPosted: true,
          lines: [
            VoucherLineModel(
              accountId: customerAcc.id!, // العميل المسدد (دائن)
              amount: 1500.0,
              statement: 'دفعة نقدية تحت الحساب',
            ),
          ],
        );

        final voucherId = await voucherDataSource.insertVoucher(voucher);
        expect(voucherId, isPositive);

        // Assert Bank account is Debited (+1500) and Customer is Credited (-1500)
        final bankBalAfter = (await accountDataSource.getAccountById(bankAcc.id!)).balance;
        final custBalAfter = (await accountDataSource.getAccountById(customerAcc.id!)).balance;

        expect(bankBalAfter, closeTo(bankBalBefore + 1500.0, 0.001));
        expect(custBalAfter, closeTo(custBalBefore - 1500.0, 0.001));

        // Verify Journal Entry was created with RV prefix
        final journalEntries = await journalDataSource.getJournalEntries();
        final relatedJournal = journalEntries.firstWhere((j) => j.referenceType == 'voucher_receipt' && j.referenceId == voucherId);
        expect(relatedJournal.number, contains('RV-'));
        expect(relatedJournal.totalDebit, 1500.0);
        expect(relatedJournal.totalCredit, 1500.0);
      });

      test('سند صرف (Payment Voucher): نقص النقدية/البنك ومدينية حساب المصروف مع إنشاء قيد آلي PV', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final bankAcc = accounts.firstWhere((a) => !a.isMaster && a.type == 1);
        final expenseAcc = accounts.firstWhere((a) => !a.isMaster && (a.type == 5 || a.id != bankAcc.id));

        final bankBalBefore = (await accountDataSource.getAccountById(bankAcc.id!)).balance;
        final expBalBefore = (await accountDataSource.getAccountById(expenseAcc.id!)).balance;

        final voucher = VoucherModel(
          type: VoucherType.payment, // سند صرف
          number: 202,
          date: DateTime.now(),
          accountId: bankAcc.id!, // الصندوق أو البنك الدافع (دائن)
          amount: 800.0,
          statement: 'سند صرف إيجار الفرع',
          isPosted: true,
          lines: [
            VoucherLineModel(
              accountId: expenseAcc.id!, // المصروف المدفوع (مدين)
              amount: 800.0,
              statement: 'إيجار شهر محرم',
            ),
          ],
        );

        final voucherId = await voucherDataSource.insertVoucher(voucher);
        expect(voucherId, isPositive);

        // Bank is Credited (-800), Expense is Debited (+800)
        final bankBalAfter = (await accountDataSource.getAccountById(bankAcc.id!)).balance;
        final expBalAfter = (await accountDataSource.getAccountById(expenseAcc.id!)).balance;

        expect(bankBalAfter, closeTo(bankBalBefore - 800.0, 0.001));
        expect(expBalAfter, closeTo(expBalBefore + 800.0, 0.001));

        // Verify Journal Entry was created with PV prefix
        final journalEntries = await journalDataSource.getJournalEntries();
        final relatedJournal = journalEntries.firstWhere((j) => j.referenceType == 'voucher_payment' && j.referenceId == voucherId);
        expect(relatedJournal.number, contains('PV-'));
        expect(relatedJournal.totalDebit, 800.0);
        expect(relatedJournal.totalCredit, 800.0);
      });

      test('حذف السند وعكس الأثر المالي والقيود آلياً وتاماً (Voucher deletion & atomic rollback)', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final bankAcc = accounts.firstWhere((a) => !a.isMaster && a.type == 1);
        final expenseAcc = accounts.firstWhere((a) => !a.isMaster && a.id != bankAcc.id);

        final initialBankBal = (await accountDataSource.getAccountById(bankAcc.id!)).balance;

        final voucher = VoucherModel(
          type: VoucherType.payment,
          number: 303,
          date: DateTime.now(),
          accountId: bankAcc.id!,
          amount: 600.0,
          statement: 'سند صرف تجريبي للحذف',
          lines: [
            VoucherLineModel(
              accountId: expenseAcc.id!,
              amount: 600.0,
              statement: 'مصروف تجريبي',
            ),
          ],
        );

        final voucherId = await voucherDataSource.insertVoucher(voucher);
        expect((await accountDataSource.getAccountById(bankAcc.id!)).balance, closeTo(initialBankBal - 600.0, 0.001));

        // Delete the voucher
        await voucherDataSource.deleteVoucher(voucherId);

        // Balances must revert exactly
        expect((await accountDataSource.getAccountById(bankAcc.id!)).balance, closeTo(initialBankBal, 0.001));

        // Related journal entry must be deleted
        final journalEntries = await journalDataSource.getJournalEntries();
        expect(journalEntries.any((j) => j.referenceId == voucherId), isFalse);
      });
    });

    // =========================================================================
    // 5. الأرصدة الافتتاحية (Opening Balances)
    // =========================================================================
    group('5. الأرصدة الافتتاحية (Opening Balances)', () {
      test('تسجيل وترحيل قيد رصيد افتتاحي متوازن وتوليد قيد OB-xxxxxx', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final cashAcc = accounts.firstWhere((a) => !a.isMaster && a.type == 1);
        final equityAcc = accounts.firstWhere((a) => !a.isMaster && (a.type == 3 || a.type == 2));

        final cashInitial = cashAcc.balance;
        final equityInitial = equityAcc.balance;

        final openingBalance = OpeningBalanceModel(
          number: '000001',
          entryDate: DateTime.now(),
          description: 'افتتاح السنة المالية الأولى',
          currencyId: 1,
          currencyCode: 'SAR',
          totalDebit: 50000.0,
          totalCredit: 50000.0,
          isPosted: true,
          lines: [
            OpeningBalanceLineModel(
              lineNumber: 1,
              accountId: cashAcc.id!,
              accountCode: cashAcc.code,
              accountName: cashAcc.name,
              currencyId: 1,
              currencyCode: 'SAR',
              debit: 50000.0,
              credit: 0.0,
            ),
            OpeningBalanceLineModel(
              lineNumber: 2,
              accountId: equityAcc.id!,
              accountCode: equityAcc.code,
              accountName: equityAcc.name,
              currencyId: 1,
              currencyCode: 'SAR',
              debit: 0.0,
              credit: 50000.0,
            ),
          ],
        );

        final entryId = await openingBalanceDataSource.createOpeningBalance(openingBalance);
        expect(entryId, isPositive);

        // Verify account balance updates
        final updatedCash = await accountDataSource.getAccountById(cashAcc.id!);
        final updatedEquity = await accountDataSource.getAccountById(equityAcc.id!);

        expect(updatedCash.balance, closeTo(cashInitial + 50000.0, 0.001));
        expect(updatedEquity.balance, closeTo(equityInitial - 50000.0, 0.001));

        // Verify opening journal entry
        final journalEntries = await journalDataSource.getJournalEntries();
        final obJournal = journalEntries.firstWhere((j) => j.referenceType == 'opening_entry' && j.referenceId == entryId);
        expect(obJournal.number, contains('OB-'));
        expect(obJournal.totalDebit, 50000.0);
        expect(obJournal.totalCredit, 50000.0);
      });

      test('حماية الرصيد الافتتاحي: منع تعديل أو حذف الرصيد الافتتاحي عند وجود عمليات مالية لاحقة', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final acc1 = accounts.firstWhere((a) => !a.isMaster);
        final acc2 = accounts.firstWhere((a) => !a.isMaster && a.id != acc1.id);

        final pastDate = DateTime.now().subtract(const Duration(days: 10));

        final openingBalance = OpeningBalanceModel(
          number: '000002',
          entryDate: pastDate,
          description: 'رصيد افتتاحي محمي',
          currencyId: 1,
          currencyCode: 'SAR',
          totalDebit: 10000.0,
          totalCredit: 10000.0,
          isPosted: true,
          lines: [
            OpeningBalanceLineModel(
              lineNumber: 1,
              accountId: acc1.id!,
              accountCode: acc1.code,
              accountName: acc1.name,
              currencyId: 1,
              currencyCode: 'SAR',
              debit: 10000.0,
              credit: 0.0,
            ),
            OpeningBalanceLineModel(
              lineNumber: 2,
              accountId: acc2.id!,
              accountCode: acc2.code,
              accountName: acc2.name,
              currencyId: 1,
              currencyCode: 'SAR',
              debit: 0.0,
              credit: 10000.0,
            ),
          ],
        );

        final obId = await openingBalanceDataSource.createOpeningBalance(openingBalance);

        // Add subsequent manual journal entry
        final laterEntry = JournalEntryModel(
          number: 'JV-00099',
          entryDate: DateTime.now(),
          description: 'معاملة مالية لاحقة للرصيد الافتتاحي',
          referenceType: 'manual',
          isPosted: true,
          totalDebit: 200.0,
          totalCredit: 200.0,
          difference: 0.0,
          lines: [
            JournalEntryLineModel(
              lineNumber: 1,
              accountId: acc1.id,
              accountCode: acc1.code,
              accountName: acc1.name,
              currencyCode: 'SAR',
              debit: 200.0,
              credit: 0.0,
            ),
            JournalEntryLineModel(
              lineNumber: 2,
              accountId: acc2.id,
              accountCode: acc2.code,
              accountName: acc2.name,
              currencyCode: 'SAR',
              debit: 0.0,
              credit: 200.0,
            ),
          ],
        );
        await journalDataSource.insertJournalEntry(laterEntry);

        // Attempting to delete the posted opening balance MUST be rejected to preserve ledger continuity
        expect(
          () async => await openingBalanceDataSource.deleteOpeningBalance(obId),
          throwsA(isA<Exception>()),
        );
      });
    });

    // =========================================================================
    // 6. سقف الحسابات (Account Limits & Financial Ceilings)
    // =========================================================================
    group('6. سقف الحسابات والرقابة المالية (Account Limits & Controls)', () {
      test('تحديد سقف مدين ودائن لحساب ومنع العمليات المتجاوزة للسقف (Limit Enforcement)', () async {
        final accounts = await accountDataSource.getAllAccounts();
        final customerAcc = accounts.firstWhere((a) => !a.isMaster && a.type == 1);

        // Set debit limit of 5,000 SAR for customer
        final limitEntity = AccountLimitEntity(
          accountId: customerAcc.id!,
          accountName: customerAcc.name,
          accountCode: customerAcc.code,
          currencyId: 1,
          currencyCode: 'SAR',
          debitLimit: 5000.0,
          creditLimit: 10000.0,
          currentDebit: 4000.0, // 4,000 already used
          currentCredit: 0.0,
          isActive: true,
        );

        await limitService.saveAccountLimit(limitEntity);

        // 1. Transaction of 800 should be allowed (4000 + 800 <= 5000)
        final validCheck = await limitService.canDebit(
          accountId: customerAcc.id!,
          amount: 800.0,
          currencyId: 1,
        );
        expect(validCheck.getOrElse(() => false), isTrue);

        // 2. Transaction of 1500 should be BLOCKED (4000 + 1500 > 5000)
        final invalidCheck = await limitService.canDebit(
          accountId: customerAcc.id!,
          amount: 1500.0,
          currencyId: 1,
        );
        expect(invalidCheck.getOrElse(() => true), isFalse);

        // 3. Interceptor must return validation failure on exceeding limit
        final interceptorResult = await limitInterceptor.validateJournalEntry(
          lines: [
            JournalEntryLineValidation(
              accountId: customerAcc.id!,
              currencyId: 1,
              debitAmount: 1500.0,
              creditAmount: 0.0,
            ),
          ],
        );
        expect(interceptorResult.isLeft(), isTrue);
      });

      test('حساب مستويات الاستخدام (UsageLevel: Safe, Warning, Critical) بدقة', () async {
        final safeLimit = AccountLimitEntity(
          accountId: 1,
          accountName: 'Test',
          accountCode: '101',
          currencyId: 1,
          currencyCode: 'SAR',
          debitLimit: 10000.0,
          creditLimit: 0,
          currentDebit: 5000.0, // 50% -> Safe
        );
        expect(safeLimit.usageLevel, UsageLevel.safe);

        final warningLimit = safeLimit.copyWith(currentDebit: 7500.0); // 75% -> Warning
        expect(warningLimit.usageLevel, UsageLevel.warning);

        final criticalLimit = safeLimit.copyWith(currentDebit: 9500.0); // 95% -> Critical
        expect(criticalLimit.usageLevel, UsageLevel.critical);
      });
    });
  });
}
