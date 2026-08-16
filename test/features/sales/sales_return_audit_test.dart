import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/database/database_initializer_io.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_limits_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/customers_table.dart';
import 'package:muhasib/core/database/tables/suppliers_table.dart';
import 'package:muhasib/core/database/tables/classifications_table.dart';
import 'package:muhasib/core/database/tables/banks_table.dart';
import 'package:muhasib/core/database/tables/stocks_table.dart';
import 'package:muhasib/core/database/tables/categories_table.dart';
import 'package:muhasib/core/database/tables/categories_groups_table.dart';
import 'package:muhasib/core/database/tables/categories_units_table.dart';
import 'package:muhasib/core/database/tables/category_sub_units_table.dart';
import 'package:muhasib/core/database/tables/invoices_table.dart';
import 'package:muhasib/core/database/tables/invoice_lines_table.dart';
import 'package:muhasib/core/database/tables/stock_movements_table.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/core/database/tables/settings_table.dart';
import 'package:muhasib/core/database/tables/taxes_table.dart';
import 'package:muhasib/core/database/tables/payment_methods_table.dart';
import 'package:muhasib/core/database/tables/unified_payments_table.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/database/seeders/settings_seeder.dart';
import 'package:muhasib/core/database/seeders/tax_seeder.dart';
import 'package:muhasib/core/database/seeders/currency_seeder.dart';
import 'package:muhasib/core/database/seeders/payment_methods_seeder.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'package:muhasib/features/sales/data/models/invoice_line_model.dart';

Future<Database> createFreshTestDatabase() async {
  initializeDatabaseFactory();
  final tables = <TableSchema>[
    CurrenciesTable(),
    SettingsTable(),
    TaxesTable(),
    PaymentMethodTypesTable(),
    PaymentMethodsTable(),
    AccountsTable(),
    AccountLimitsTable(),
    AccountConnectsTable(),
    JournalEntriesTable(),
    JournalEntryLinesTable(),
    CustomersTable(),
    SuppliersTable(),
    ClassificationsTable(),
    BanksTable(),
    StocksTable(),
    CategoriesGroupsTable(),
    CategoriesUnitsTable(),
    CategoriesTable(),
    CategorySubUnitsTable(),
    InvoicesTable(),
    InvoiceLinesTable(),
    StockMovementsTable(),
    WarehouseStocksTable(),
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
      await TaxSeeder.seed(db);
      await CurrencySeeder.seed(db);
      await PaymentMethodsSeeder.seed(db);
      await seedDefaultStocks(db);
      await seedDefaultCustomers(db);
      await seedDefaultAccounts(db);
      await seedDefaultAccountConnects(db);

      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.insert('categories', {
        'name': 'منتج اختبار',
        'statement': 'منتج',
        'barcode_no': 'TEST-001',
        'stock_id': 1,
        'quantity': 0,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
      await db.insert('warehouse_stocks', {
        'product_id': 1,
        'warehouse_id': 1,
        'quantity': 10,
        'avg_cost': 50,
        'last_cost': 50,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
    },
  );

  return db;
}

Future<int> accountIdByCId(Database db, int cId) async {
  final rows = await db.query(
    'accounts',
    columns: ['id'],
    where: 'c_id = ?',
    whereArgs: [cId],
    limit: 1,
  );
  return rows.first['id'] as int;
}

Future<double> accountBalance(Database db, int accountId) async {
  final rows = await db.query(
    'accounts',
    columns: ['balance'],
    where: 'id = ?',
    whereArgs: [accountId],
    limit: 1,
  );
  return (rows.first['balance'] as num?)?.toDouble() ?? 0.0;
}

Future<List<Map<String, dynamic>>> journalLinesFor(
  Database db,
  String referenceType,
  int referenceId,
) async {
  final entries = await db.query(
    'journal_entries',
    where: 'reference_type = ? AND reference_id = ? AND status = 1',
    whereArgs: [referenceType, referenceId],
  );
  expect(entries.length, 1, reason: 'يجب وجود قيد فعال واحد فقط لـ $referenceType/$referenceId');
  final entry = entries.first;
  expect(
    (entry['total_debit'] as num).toDouble(),
    closeTo((entry['total_credit'] as num).toDouble(), 0.01),
    reason: 'القيد غير متوازن',
  );
  return db.query(
    'journal_entry_lines',
    where: 'journal_entry_id = ?',
    whereArgs: [entry['id']],
  );
}

Future<Map<String, double>> debitCreditMap(
  List<Map<String, dynamic>> lines,
) async {
  final result = <String, double>{};
  for (final line in lines) {
    final accountId = (line['account_id'] as int).toString();
    final debit = (line['debit_amount'] as num?)?.toDouble() ?? 0.0;
    final credit = (line['credit_amount'] as num?)?.toDouble() ?? 0.0;
    result['D$accountId'] = (result['D$accountId'] ?? 0) + debit;
    result['C$accountId'] = (result['C$accountId'] ?? 0) + credit;
  }
  return result;
}

InvoiceLineModel testLine({
  required int invoiceType,
  int invoiceId = 0,
  double quantity = 2,
  double? costPrice,
}) {
  return InvoiceLineModel(
    invoiceType: invoiceType,
    amount: 500,
    totalAmount: 500 * quantity,
    netRevenueAmt: 500 * quantity,
    quantity: quantity,
    categoryId: 1,
    groupId: 1,
    unitId: 1,
    categorySubUnitId: 1,
    stockId: 1,
    invoiceId: invoiceId,
    customerId: 1,
    invoiceTransType: 1,
    date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    costPrice: costPrice,
  );
}

void main() {
  setUpAll(() {
    initializeDatabaseFactory();
  });

  late Database db;
  late InvoiceLocalDataSourceImpl dataSource;

  setUp(() async {
    db = await createFreshTestDatabase();
    dataSource = InvoiceLocalDataSourceImpl(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('فاتورة المبيعات - القيد المحاسبي', () {
    test('خصم + ضريبة + دفع مقسم (كاش/بنك/آجل) → قيد متوازن وخطوط صحيحة', () async {
      final invoice = InvoiceModel(
        invoiceType: 1,
        number: 'SI-1',
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: 1000,
        discountAmt: 100,
        taxAmt: 135,
        finalAmt: 1035,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 1, // آجل
        paidAmount: 500, // كاش
        bankPaidAmount: 200, // بنك
        currencyCode: 'SAR',
        lines: [testLine(invoiceType: 1)],
      );

      final id = await dataSource.insertInvoice(invoice);

      final lines = await journalLinesFor(db, 'sales_invoice', id);
      final cashId = await accountIdByCId(db, 1110);
      final customersId = await accountIdByCId(db, 1120);
      final salesId = await accountIdByCId(db, 4110);
      final taxId = await accountIdByCId(db, 2140);
      final discountId = await accountIdByCId(db, 3150);

      final totals = await debitCreditMap(lines);
      // مدين: كاش 500 (البنك مربوط على نفس حساب الصندوق الافتراضي)
      expect(totals['D$cashId'] ?? 0, closeTo(700, 0.01));
      // مدين: ذمة العميل 335
      expect(totals['D$customersId'] ?? 0, closeTo(335, 0.01));
      // دائن: المبيعات (الإجمالي قبل الخصم)
      expect(totals['C$salesId'] ?? 0, closeTo(1000, 0.01));
      // دائن: الضريبة
      expect(totals['C$taxId'] ?? 0, closeTo(135, 0.01));
      // مدين: الخصم المسموح
      expect(totals['D$discountId'] ?? 0, closeTo(100, 0.01));

      // المخزون انخفض بالكمية المباعة (2)
      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(8, 0.01));
    });

    test('تعديل الفاتورة → عكس القيد القديم والمخزون وإعادة الترحيل', () async {
      final invoice = InvoiceModel(
        invoiceType: 1,
        number: 'SI-1',
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: 1000,
        finalAmt: 1000,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 0, // نقدي
        paidAmount: 1000,
        lines: [testLine(invoiceType: 1, quantity: 2)],
      );
      final id = await dataSource.insertInvoice(invoice);
      final salesId = await accountIdByCId(db, 4110);
      // المبيعات حساب دائن: الرصيد بالسالب حسب عرف النظام (مدين - دائن)
      expect(await accountBalance(db, salesId), closeTo(-1000, 0.01));

      final updated = InvoiceModel(
        id: id,
        invoiceType: 1,
        number: 'SI-1',
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: 500,
        finalAmt: 500,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 0,
        paidAmount: 500,
        lines: [testLine(invoiceType: 1, quantity: 1)],
      );
      await dataSource.updateInvoice(updated);

      // قيد واحد فقط بالقيم الجديدة
      final lines = await journalLinesFor(db, 'sales_invoice', id);
      final totals = await debitCreditMap(lines);
      expect(totals['C$salesId'] ?? 0, closeTo(500, 0.01));
      expect(await accountBalance(db, salesId), closeTo(-500, 0.01));

      // المخزون: 10 - 2 + 2 - 1 = 9
      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(9, 0.01));
    });

    test('حذف الفاتورة → عكس القيد بالكامل وإرجاع المخزون', () async {
      final invoice = InvoiceModel(
        invoiceType: 1,
        number: 'SI-1',
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: 1000,
        finalAmt: 1000,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 0,
        paidAmount: 1000,
        lines: [testLine(invoiceType: 1, quantity: 2)],
      );
      final id = await dataSource.insertInvoice(invoice);
      final salesId = await accountIdByCId(db, 4110);
      // المبيعات حساب دائن: الرصيد بالسالب حسب عرف النظام (مدين - دائن)
      expect(await accountBalance(db, salesId), closeTo(-1000, 0.01));

      await dataSource.deleteInvoice(id);

      final entries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['sales_invoice', id],
      );
      // مسار التدقيق: القيد الأصلي يبقى محفوظاً بحالة معكوس (status = 2)
      expect(entries.isNotEmpty, isTrue);
      expect(entries.first['status'], equals(2));

      // التحقق من وجود القيد العكسي
      final revEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['sales_invoice_reversal', id],
      );
      expect(revEntries.isNotEmpty, isTrue);
      expect(await accountBalance(db, salesId), closeTo(0, 0.01));

      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(10, 0.01));
    });
  });

  group('مرتجع المبيعات - القيد المحاسبي والمخزون', () {
    test('مرتجع آجل بضريبة وخصم → قيد متوازن وزيادة مخزون', () async {
      final returnInvoice = InvoiceModel(
        invoiceType: 4,
        number: 'SR-1',
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: 400,
        discountAmt: 40,
        taxAmt: 54,
        finalAmt: 414,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 1, // آجل → تخفيض ذمة العميل
        lines: [testLine(invoiceType: 4, quantity: 1)],
      );

      final id = await dataSource.createReturnInvoice(returnInvoice, 0);

      final lines = await journalLinesFor(db, 'sales_return', id);
      final returnsId = await accountIdByCId(db, 4150);
      final customersId = await accountIdByCId(db, 1120);
      final taxId = await accountIdByCId(db, 2140);
      final discountId = await accountIdByCId(db, 3150);

      final totals = await debitCreditMap(lines);
      expect(totals['D$returnsId'] ?? 0, closeTo(400, 0.01));
      expect(totals['D$taxId'] ?? 0, closeTo(54, 0.01));
      expect(totals['C$customersId'] ?? 0, closeTo(414, 0.01));
      expect(totals['C$discountId'] ?? 0, closeTo(40, 0.01));

      // المخزون زاد بالكمية المرتجعة
      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(11, 0.01));
    });

    test('مرتجع نقدي ببنك → دائن البنك بالقيمة كاملة', () async {
      final returnInvoice = InvoiceModel(
        invoiceType: 4,
        number: 'SR-2',
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: 400,
        finalAmt: 400,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 0, // نقدي
        bankPaidAmount: 400, // إرجاع بنكي
        lines: const [],
      );

      final id = await dataSource.createReturnInvoice(returnInvoice, 0);
      final lines = await journalLinesFor(db, 'sales_return', id);
      final totals = await debitCreditMap(lines);
      final cashId = await accountIdByCId(db, 1110);
      expect(totals['C$cashId'] ?? 0, closeTo(400, 0.01));
    });

    test('حذف المرتجع → عكس القيد وإنقاص المخزون', () async {
      final returnInvoice = InvoiceModel(
        invoiceType: 4,
        number: 'SR-1',
        date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: 400,
        finalAmt: 400,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 1,
        lines: [testLine(invoiceType: 4, quantity: 1)],
      );
      final id = await dataSource.createReturnInvoice(returnInvoice, 0);

      await dataSource.deleteInvoice(id);

      final entries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['sales_return', id],
      );
      // مسار التدقيق: القيد الأصلي يبقى بحالة معكوس (status = 2)
      expect(entries.isNotEmpty, isTrue);
      expect(entries.first['status'], equals(2));

      // التحقق من وجود القيد العكسي
      final revEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['sales_return_reversal', id],
      );
      expect(revEntries.isNotEmpty, isTrue);

      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(10, 0.01));
    });
  });

  group('عروض الأسعار', () {
    test('تحويل عرض السعر → قيد مبيعات واحد + خصم مخزون', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final quotationId = await db.insert('invoices', {
        'invoice_type': 3,
        'number': 'Q-1',
        'date': nowSec,
        'amount': 0,
        'stock_id': 1,
        'customer_id': 1,
        'invoice_trans_type': 0,
        'payment_status': 0,
      });

      final salesInvoice = InvoiceModel(
        invoiceType: 1,
        number: 'SI-Q1',
        date: nowSec,
        amount: 800,
        finalAmt: 800,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 0,
        paidAmount: 800,
        lines: [testLine(invoiceType: 1, quantity: 2)],
      );

      final id = await dataSource.convertQuotationToInvoice(
        quotationId,
        salesInvoice,
      );

      // قيد واحد
      final lines = await journalLinesFor(db, 'sales_invoice', id);
      final totals = await debitCreditMap(lines);
      final salesId = await accountIdByCId(db, 4110);
      expect(totals['C$salesId'] ?? 0, closeTo(800, 0.01));

      // المخزون انخفض
      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(8, 0.01));

      // عرض السعر أصبح مقفلاً ومحوّلاً
      final quotation = await db.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [quotationId],
      );
      expect(quotation.first['is_locked'], 1);
      expect(quotation.first['next_invoice_id'], id);
    });
  });
}
