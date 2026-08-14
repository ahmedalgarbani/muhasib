import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/currency_exchange_service.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/database/seeders/currency_seeder.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/currency_exchanges_table.dart';
import 'package:muhasib/core/database/tables/currency_exchange_rates_table.dart';

class _TestDatabaseService implements DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db);

  @override
  Database get databaseSync => _db;

  @override
  Future<Database> get database async => _db;

  @override
  Future<void> executeBatch(List<String> statements) async {
    final batch = _db.batch();
    for (final s in statements) {
      batch.execute(s);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> initDatabase() async {}

  @override
  Future<void> close() async => await _db.close();

  @override
  Future<void> clearAllData() async {}
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseService dbService;
  late CurrencyExchangeService exchangeService;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbService = _TestDatabaseService(db);
    exchangeService = CurrencyExchangeService(dbService);

    // Create tables
    final tables = [
      CurrenciesTable(),
      AccountsTable(),
      AccountConnectsTable(),
      JournalEntriesTable(),
      JournalEntryLinesTable(),
      CurrencyExchangesTable(),
      CurrencyExchangeRatesTable(),
    ];

    for (final t in tables) {
      await db.execute(t.createTable);
      for (final idx in t.indexes) {
        try {
          await db.execute(idx);
        } catch (_) {}
      }
    }

    // Seed default currencies and accounts
    await CurrencySeeder.seed(db);
    await seedDefaultAccounts(db);
  });

  tearDown(() async {
    await db.close();
  });

  group(
    '🔬 تدقيق محاسبي لعمليات صرف العملات (Currency Exchange Accounting Audit)',
    () {
      test(
        '1. صرف عملات بسعر الصرف الرسمي وتوليد قيد متوازن وتحديث الأرصدة',
        () async {
          // 1. Setup Accounts:
          // USD Cashbox (account 1001 - النقدية)
          final cashboxRows = await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['1001'],
          );
          final usdCashId = cashboxRows.first['id'] as int;

          // SAR Bank (account 1002 - العملاء أو بنك)
          final bankRows = await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['1002'],
          );
          final sarBankId = bankRows.first['id'] as int;

          // Currency: USD (id: 2, rate: 3.75), SAR (id: 1, rate: 1.0)
          final result = await exchangeService.createExchange(
            creditAccountId: usdCashId,
            creditCurrencyId: 2,
            creditCurrencyCode: 'USD',
            creditAmount: 100.0,
            creditExchangeRate: 3.75, // 100 USD = 375 SAR local
            debitAccountId: sarBankId,
            debitCurrencyId: 1,
            debitCurrencyCode: 'SAR',
            debitAmount: 375.0,
            debitExchangeRate: 1.0, // 375 SAR = 375 SAR local
            date: DateTime(2026, 1, 15),
            notes: 'صرف 100 دولار وإيداع المقابل بالريال في البنك',
          );

          expect(result.isRight(), isTrue);
          final exchange = result.getOrElse(() => throw Exception());
          expect(exchange.number, equals(1));
          expect(exchange.journalEntryId, isNotNull);

          // Verify Journal Entry was created and is 100% balanced
          final jeRows = await db.query(
            'journal_entries',
            where: 'id = ?',
            whereArgs: [exchange.journalEntryId],
          );
          expect(jeRows.isNotEmpty, isTrue);
          expect(jeRows.first['total_debit'], equals(375.0));
          expect(jeRows.first['total_credit'], equals(375.0));
          expect(jeRows.first['difference'], equals(0.0));

          // Verify Journal Entry Lines
          final lines = await db.query(
            'journal_entry_lines',
            where: 'journal_entry_id = ?',
            whereArgs: [exchange.journalEntryId],
            orderBy: 'line_number ASC',
          );
          expect(lines.length, equals(2));
          // Line 1: Debit SAR Bank
          expect(lines[0]['account_id'], equals(sarBankId));
          expect(lines[0]['debit_amount'], equals(375.0));
          expect(lines[0]['credit_amount'], equals(0.0));
          // Line 2: Credit USD Cash
          expect(lines[1]['account_id'], equals(usdCashId));
          expect(lines[1]['debit_amount'], equals(0.0));
          expect(lines[1]['credit_amount'], equals(375.0));

          // Verify Account Balance Deltas
          final bankAcc = await db.query(
            'accounts',
            where: 'id = ?',
            whereArgs: [sarBankId],
          );
          final cashAcc = await db.query(
            'accounts',
            where: 'id = ?',
            whereArgs: [usdCashId],
          );
          expect(bankAcc.first['balance'], equals(375.0));
          expect(cashAcc.first['balance'], equals(-375.0));
        },
      );

      test(
        '2. صرف عملات بسعر تفاوضي مع أرباح فروق صرف (Gain on Exchange)',
        () async {
          // Sold: 100 USD @ book rate 3.75 = 375.0 SAR local
          // Received: 380 SAR cash (5.0 SAR gain / profit)
          final cashbox = (await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['1001'],
          )).first;
          final bank = (await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['1002'],
          )).first;

          // Revenue / Gain Account (4001 - المبيعات/إيرادات)
          final diffAcc = (await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['4001'],
          )).first;
          final diffAccountId = diffAcc['id'] as int;

          final result = await exchangeService.createExchange(
            creditAccountId: cashbox['id'] as int,
            creditCurrencyId: 2,
            creditCurrencyCode: 'USD',
            creditAmount: 100.0,
            creditExchangeRate: 3.75, // Book value = 375.0
            debitAccountId: bank['id'] as int,
            debitCurrencyId: 1,
            debitCurrencyCode: 'SAR',
            debitAmount: 380.0, // Received = 380.0
            debitExchangeRate: 1.0,
            date: DateTime(2026, 1, 16),
            notes: 'صرف بسعر مميز 3.80 بربح 5 ريال',
            exchangeDifferenceAccountId: diffAccountId,
          );

          expect(result.isRight(), isTrue);
          final exchange = result.getOrElse(() => throw Exception());

          // Check Journal Entry
          final je = (await db.query(
            'journal_entries',
            where: 'id = ?',
            whereArgs: [exchange.journalEntryId],
          )).first;
          expect(je['total_debit'], equals(380.0));
          expect(je['total_credit'], equals(380.0));

          final lines = await db.query(
            'journal_entry_lines',
            where: 'journal_entry_id = ?',
            whereArgs: [exchange.journalEntryId],
            orderBy: 'line_number ASC',
          );
          expect(lines.length, equals(3));
          // Line 1: Debit Bank 380
          expect(lines[0]['debit_amount'], equals(380.0));
          // Line 2: Credit USD Cash 375
          expect(lines[1]['credit_amount'], equals(375.0));
          // Line 3: Credit Gain Account 5
          expect(lines[2]['account_id'], equals(diffAccountId));
          expect(lines[2]['credit_amount'], equals(5.0));
        },
      );

      test(
        '3. صرف عملات بسعر تفاوضي مع خسائر فروق صرف (Loss on Exchange)',
        () async {
          // Sold: 100 USD @ book rate 3.75 = 375.0 SAR local
          // Received: 370 SAR cash (5.0 SAR loss / expense)
          final cashbox = (await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['1001'],
          )).first;
          final bank = (await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['1002'],
          )).first;

          // Expense / Loss Account (3001 - المشتريات/مصروفات)
          final diffAcc = (await db.query(
            'accounts',
            where: 'code = ?',
            whereArgs: ['3001'],
          )).first;
          final diffAccountId = diffAcc['id'] as int;

          final result = await exchangeService.createExchange(
            creditAccountId: cashbox['id'] as int,
            creditCurrencyId: 2,
            creditCurrencyCode: 'USD',
            creditAmount: 100.0,
            creditExchangeRate: 3.75, // Book value = 375.0
            debitAccountId: bank['id'] as int,
            debitCurrencyId: 1,
            debitCurrencyCode: 'SAR',
            debitAmount: 370.0, // Received = 370.0
            debitExchangeRate: 1.0,
            date: DateTime(2026, 1, 17),
            notes: 'صرف بسعر 3.70 مع خسارة 5 ريال',
            exchangeDifferenceAccountId: diffAccountId,
          );

          expect(result.isRight(), isTrue);
          final exchange = result.getOrElse(() => throw Exception());

          // Check Journal Entry
          final je = (await db.query(
            'journal_entries',
            where: 'id = ?',
            whereArgs: [exchange.journalEntryId],
          )).first;
          expect(je['total_debit'], equals(375.0));
          expect(je['total_credit'], equals(375.0));

          final lines = await db.query(
            'journal_entry_lines',
            where: 'journal_entry_id = ?',
            whereArgs: [exchange.journalEntryId],
            orderBy: 'line_number ASC',
          );
          expect(lines.length, equals(3));
          // Line 1: Debit Bank 370
          expect(lines[0]['debit_amount'], equals(370.0));
          // Line 2: Credit USD Cash 375
          expect(lines[1]['credit_amount'], equals(375.0));
          // Line 3: Debit Loss Account 5
          expect(lines[2]['account_id'], equals(diffAccountId));
          expect(lines[2]['debit_amount'], equals(5.0));
        },
      );
    },
  );
}
