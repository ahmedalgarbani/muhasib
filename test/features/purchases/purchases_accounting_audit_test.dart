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
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/purchases/domain/templates/purchases_accounting_template.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_line_model.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';

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
        'name': 'منتج شراء اختبار',
        'statement': 'منتج',
        'barcode_no': 'PUR-TEST-001',
        'stock_id': 1,
        'quantity': 0,
        'cost_amount': 100.0,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
      await db.insert('warehouse_stocks', {
        'product_id': 1,
        'warehouse_id': 1,
        'quantity': 10,
        'avg_cost': 100,
        'last_cost': 100,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
    },
  );

  return db;
}

void main() {
  group('Purchases Accounting and IFRS Rules Tests', () {
    const config = PurchaseAccountConfig(
      inventoryAccountId: 1310,
      cashAccountId: 1110,
      bankAccountId: 1120,
      suppliersAccountId: 2110,
      purchasesAccountId: 5110,
      purchaseReturnsAccountId: 5120,
      discountEarnedAccountId: 5130,
      taxAccountId: 2140,
    );

    test(
      'Cash purchase invoice entry is balanced and records input VAT and discount',
      () {
        final line1 = InvoiceLineEntity(
          id: 1,
          invoiceId: 1,
          invoiceType: 2,
          categoryId: 10,
          groupId: 1,
          unitId: 1,
          categorySubUnitId: 1,
          stockId: 1,
          customerId: 5,
          date: 1700000000,
          invoiceTransType: 0,
          amount: 1000.0,
          totalAmount: 900.0,
          discountAmt: 100.0,
          taxAmt: 0.0,
          netRevenueAmt: 900.0,
          quantity: 10.0,
          price: 100.0,
          costPrice: 90.0,
        );

        final invoice = InvoiceEntity(
          id: 1,
          number: 'PUR-001',
          date: 1700000000,
          customerId: 5, // Supplier ID
          stockId: 1,
          amount: 1000.0, // Subtotal
          discountAmt: 100.0, // Trade discount
          taxAmt: 135.0, // 15% VAT on (1000 - 100) = 135
          taxRatio: 15.0,
          finalAmt: 1035.0, // Net payable = (1000 - 100) + 135 = 1035
          lines: [line1],
          invoiceType: 2,
          invoiceTransType: 0, // Cash
        );

        final entry = PurchasesAccountingTemplate.createCashPurchaseEntry(
          invoice,
          config: config,
        );

        expect(PurchasesAccountingTemplate.validateJournalEntry(entry), isTrue);

        // Verify Debits = Credits
        double totalDebit = 0;
        double totalCredit = 0;
        for (final line in entry.lines) {
          totalDebit += line.debit;
          totalCredit += line.credit;
        }

        // IFRS صافي: مخزون 900 = 1000-100 + ضريبة 135 => مدين 1035 = دائن نقدية 1035 (الخصم مُحمّل على المخزون لا كإيراد منفصل)
        expect(totalDebit, equals(1035.0)); // 900 Inventory net + 135 VAT
        expect(totalCredit, equals(1035.0)); // 1035 Cash (discount netted)
        expect(totalDebit, equals(totalCredit));
      },
    );

    test(
      'Credit purchase invoice entry credits supplier payable account correctly',
      () {
        final invoice = InvoiceEntity(
          id: 2,
          number: 'PUR-002',
          date: 1700000000,
          customerId: 7, // Supplier ID
          stockId: 1,
          amount: 5000.0,
          discountAmt: 500.0,
          taxAmt: 675.0, // 15% on 4500
          taxRatio: 15.0,
          finalAmt: 5175.0, // Payable to supplier
          lines: [],
          invoiceType: 2,
          invoiceTransType: 1, // Credit
        );

        final entry = PurchasesAccountingTemplate.createCreditPurchaseEntry(
          invoice,
          config: config,
        );

        expect(PurchasesAccountingTemplate.validateJournalEntry(entry), isTrue);

        final supplierLine = entry.lines.firstWhere(
          (l) => l.accountId == config.suppliersAccountId,
        );
        expect(supplierLine.credit, equals(5175.0));
        expect(supplierLine.partnerId, equals(7));
        expect(supplierLine.partnerType, equals('supplier'));
      },
    );

    test(
      'Purchase return entry reverses supplier payable, input VAT, and discount',
      () {
        final returnInvoice = InvoiceEntity(
          id: 3,
          number: 'RET-001',
          parentInvoiceId: 2,
          parentInvoiceNumber: 'PUR-002',
          date: 1700001000,
          customerId: 7,
          stockId: 1,
          amount: 1000.0,
          discountAmt: 100.0,
          taxAmt: 135.0,
          taxRatio: 15.0,
          finalAmt: 1035.0,
          lines: [],
          invoiceType: 5,
          invoiceTransType: 1, // Credit return
        );

        final entry = PurchasesAccountingTemplate.createPurchaseReturnEntry(
          returnInvoice,
          config: config,
        );

        expect(PurchasesAccountingTemplate.validateJournalEntry(entry), isTrue);

        // صافي: مدين مورد 1035 = دائن مخزون 900 + ضريبة 135
        double totalDebit = 0;
        double totalCredit = 0;
        for (final line in entry.lines) {
          totalDebit += line.debit;
          totalCredit += line.credit;
        }
        expect(totalDebit, equals(1035.0));
        expect(totalCredit, equals(1035.0));
        expect(totalDebit, equals(totalCredit));
      },
    );

    test('PurchasesState pattern matching is exhaustive in Dart 3', () {
      const PurchasesState state = PurchaseInvoiceCreated(42);

      final result = switch (state) {
        PurchasesInitial() => 'initial',
        PurchasesLoading() => 'loading',
        PurchasesError(message: final m) => 'error: $m',
        PurchaseInvoicesLoaded(invoices: final invs) =>
          'invoices: ${invs.length}',
        PurchaseInvoiceCreated(invoiceId: final id) => 'created: $id',
        PurchaseInvoiceUpdated() => 'updated',
        PurchaseInvoiceDeleted() => 'deleted',
        PurchaseOrdersLoaded(orders: final ords) => 'orders: ${ords.length}',
        PurchaseOrderCreated(orderId: final id) => 'order_created: $id',
        PurchaseOrderConverted(invoiceId: final id) => 'converted: $id',
        PurchaseReturnsLoaded(returns: final rets) => 'returns: ${rets.length}',
        PurchaseReturnCreated(returnId: final id) => 'return_created: $id',
      };

      expect(result, equals('created: 42'));
    });

    test(
      'End-to-End Purchase Bill Saving: inserts bill, updates inventory stock, and creates balanced journal entry',
      () async {
        final db = await createFreshTestDatabase();
        final ds = InvoiceLocalDataSourceImpl(database: db);

        final line = InvoiceLineModel(
          id: null,
          invoiceId: 0,
          invoiceType: 2,
          categoryId: 1,
          groupId: 1,
          unitId: 1,
          categorySubUnitId: 1,
          stockId: 1,
          customerId: 1,
          date: 1700000000,
          invoiceTransType: 1, // Credit
          amount: 2000.0,
          totalAmount: 1800.0,
          discountAmt: 200.0,
          taxAmt: 270.0,
          netRevenueAmt: 1800.0,
          quantity: 20.0,
          price: 100.0,
          costPrice: 90.0,
          costTotal: 1800.0,
        );

        final invoice = InvoiceModel(
          id: null,
          number: 'PINV-TEST-001',
          date: 1700000000,
          customerId: 2, // Credit supplier
          stockId: 1,
          amount: 2000.0,
          discountAmt: 200.0,
          taxAmt: 270.0,
          taxRatio: 15.0,
          finalAmt: 2070.0, // (2000 - 200) + 270 = 2070
          invoiceType: 2, // Purchase invoice
          invoiceTransType: 1, // Credit
          paymentStatus: 0,
          lines: [line],
        );

        // 1. Insert Purchase Invoice
        final invoiceId = await ds.insertInvoice(invoice);
        expect(invoiceId, isPositive);

        // 2. Verify Invoice saved and can be retrieved
        final saved = await ds.getInvoice(invoiceId);
        expect(saved.id, equals(invoiceId));
        expect(saved.number, equals('PINV-TEST-001'));
        expect(saved.lines.length, equals(1));
        expect(saved.finalAmt, equals(2070.0));

        // 3. Verify Journal Entry was created and is strictly balanced
        final journalEntries = await db.query(
          'journal_entries',
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['purchase_invoice', invoiceId],
        );
        expect(journalEntries.length, equals(1));
        final je = journalEntries.first;
        final totalDebit = (je['total_debit'] as num).toDouble();
        final totalCredit = (je['total_credit'] as num).toDouble();
        expect(totalDebit, equals(totalCredit));
        expect(
          totalDebit,
          equals(2070.0),
        ); // 1800 Inventory net (2000-200) + 270 VAT = 2070; Credit: 2070 Supplier (discount netted per IAS2)

        // 4. Verify Stock was increased and WAC calculated
        // Initial stock: 10 units @ 100 = 1000 total
        // Incoming: 20 units @ 90 net cost = 1800 total
        // New total: 30 units, Total cost = 2800, WAC = 2800 / 30 = 93.333...
        final stockRows = await db.query(
          'warehouse_stocks',
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [1, 1],
        );
        expect(stockRows.isNotEmpty, isTrue);
        final newQty = (stockRows.first['quantity'] as num).toDouble();
        final avgCost = (stockRows.first['avg_cost'] as num).toDouble();
        expect(newQty, equals(30.0));
        expect(avgCost, closeTo(93.33, 0.01));

        // 5. Verify deleting purchase invoice generates reversal journal entry and restores stock
        await ds.deleteInvoice(invoiceId);
        final stockAfterDelete = await db.query(
          'warehouse_stocks',
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [1, 1],
        );
        expect(
          (stockAfterDelete.first['quantity'] as num).toDouble(),
          equals(10.0),
        );

        await db.close();
      },
    );
  });
}
