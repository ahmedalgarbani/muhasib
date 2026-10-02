import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_line_model.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import '../reports/reports_accounting_audit_test.dart' show MockDatabaseService;
import '../sales/sales_return_audit_test.dart' as audit;

/// Perpetual weighted-average inventory: the inventory GL account must move by
/// exactly the same amount as the stock valuation (quantity x avg_cost).
void main() {
  late Database db;
  late InvoiceLocalDataSourceImpl ds;
  late int inventoryAccountId;
  late int cogsAccountId;

  setUp(() async {
    db = await audit.createFreshTestDatabase();
    ds = InvoiceLocalDataSourceImpl(database: db);
    inventoryAccountId = await audit.accountIdByCId(db, 1130);
    cogsAccountId = await audit.accountIdByCId(db, 3190);
  });

  tearDown(() => db.close());

  int nowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  InvoiceLineModel line({
    int invoiceType = 1,
    int productId = 1,
    double quantity = 1,
    double price = 100,
    double? costPrice,
  }) {
    return InvoiceLineModel(
      invoiceType: invoiceType,
      amount: price * quantity,
      totalAmount: price * quantity,
      netRevenueAmt: price * quantity,
      quantity: quantity,
      baseQuantity: quantity,
      price: price,
      categoryId: productId,
      groupId: 1,
      unitId: 1,
      categorySubUnitId: 1,
      stockId: 1,
      invoiceId: 0,
      customerId: 1,
      invoiceTransType: 0,
      date: nowSec(),
      costPrice: costPrice,
      costTotal: costPrice == null ? null : costPrice * quantity,
    );
  }

  InvoiceModel invoice({
    int invoiceType = 1,
    required String number,
    required double amount,
    int? date,
    required List<InvoiceLineModel> lines,
  }) {
    return InvoiceModel(
      invoiceType: invoiceType,
      number: number,
      date: date ?? nowSec(),
      statement: 'اختبار تقييم المخزون',
      amount: amount,
      discountAmt: 0,
      taxAmt: 0,
      finalAmt: amount,
      totalAmount: amount,
      stockId: 1,
      customerId: 1,
      invoiceTransType: 0,
      paidAmount: amount,
      paymentStatus: 2,
      lines: lines,
    );
  }

  Future<Map<String, double>> stock([int productId = 1]) async {
    final rows = await db.query(
      'warehouse_stocks',
      where: 'product_id = ? AND warehouse_id = 1',
      whereArgs: [productId],
    );
    if (rows.isEmpty) return {'qty': 0, 'avg': 0, 'value': 0};
    final qty = (rows.single['quantity'] as num).toDouble();
    final avg = (rows.single['avg_cost'] as num).toDouble();
    return {'qty': qty, 'avg': avg, 'value': qty * avg};
  }

  Future<double> debitTo(String referenceType, int id, int accountId) async {
    final lines = await audit.journalLinesFor(db, referenceType, id);
    return lines
        .where((l) => l['account_id'] == accountId)
        .fold<double>(
          0,
          (s, l) =>
              s +
              (l['debit_amount'] as num).toDouble() -
              (l['credit_amount'] as num).toDouble(),
        );
  }

  test('COGS uses the warehouse average cost, not a stale line cost', () async {
    // The product master cost (30) is stale; the warehouse WAC is 50.
    final id = await ds.insertInvoice(
      invoice(
        number: 'SI-WAC',
        amount: 200,
        lines: [line(quantity: 2, costPrice: 30)],
      ),
    );

    expect(await debitTo('sales_invoice', id, cogsAccountId), closeTo(100, 0.01));
    expect(
      await debitTo('sales_invoice', id, inventoryAccountId),
      closeTo(-100, 0.01),
    );

    final saved = await db.query(
      'invoice_lines',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    expect((saved.single['cost_price'] as num).toDouble(), closeTo(50, 0.001));
    expect((saved.single['cost_total'] as num).toDouble(), closeTo(100, 0.01));
  });

  test(
    'sales return re-enters stock at the original sale cost and keeps '
    'inventory GL equal to stock valuation (create + delete)',
    () async {
      final saleId = await ds.insertInvoice(
        invoice(number: 'SI-RET', amount: 200, lines: [line(quantity: 2)]),
      );

      // A later purchase moved the average cost to 80.
      await db.update(
        'warehouse_stocks',
        {'avg_cost': 80.0},
        where: 'product_id = 1 AND warehouse_id = 1',
      );
      final before = await stock();

      // The form may send the selling price as cost; the original cost wins.
      final returnId = await ds.createReturnInvoice(
        invoice(
          invoiceType: 4,
          number: 'SR-1',
          amount: 100,
          lines: [line(invoiceType: 4, quantity: 1, costPrice: 100)],
        ),
        saleId,
      );

      final glDelta = await debitTo('sales_return', returnId, inventoryAccountId);
      final after = await stock();
      expect(glDelta, closeTo(50, 0.01));
      expect(after['value']! - before['value']!, closeTo(glDelta, 0.01));
      expect(after['qty'], closeTo(before['qty']! + 1, 0.0001));

      await ds.deleteInvoice(returnId);
      final afterDelete = await stock();
      expect(afterDelete['qty'], closeTo(before['qty']!, 0.0001));
      expect(afterDelete['value'], closeTo(before['value']!, 0.01));
    },
  );

  test('returning a service item posts no COGS reversal and no stock', () async {
    await db.insert('categories', {
      'name': 'خدمة تركيب',
      'statement': 'خدمة',
      'barcode_no': 'SRV-001',
      'stock_id': 1,
      'quantity': 0,
      'track_inventory': 0,
      'creation_time': nowSec(),
      'last_modification_time': nowSec(),
    });

    final saleId = await ds.insertInvoice(
      invoice(
        number: 'SI-SRV',
        amount: 100,
        lines: [line(productId: 2, quantity: 1, costPrice: 40)],
      ),
    );
    expect(await debitTo('sales_invoice', saleId, cogsAccountId), 0);

    final returnId = await ds.createReturnInvoice(
      invoice(
        invoiceType: 4,
        number: 'SR-SRV',
        amount: 100,
        lines: [line(invoiceType: 4, productId: 2, quantity: 1, costPrice: 40)],
      ),
      saleId,
    );

    expect(await debitTo('sales_return', returnId, cogsAccountId), 0);
    expect(await debitTo('sales_return', returnId, inventoryAccountId), 0);
    expect((await stock(2))['qty'], 0);
  });

  group('reports', () {
    late ReportsLocalDataSourceImpl reports;

    setUp(() {
      reports = ReportsLocalDataSourceImpl(
        databaseService: MockDatabaseService(db),
      );
    });

    test('balance sheet ignores entries dated after the as-of date', () async {
      final asOf = DateTime.now();
      final future = asOf.add(const Duration(days: 30));
      await ds.insertInvoice(
        invoice(
          number: 'SI-FUTURE',
          amount: 100,
          date: future.millisecondsSinceEpoch ~/ 1000,
          lines: [line(quantity: 1)],
        ),
      );

      final rows = await reports.getBalanceSheetAccounts(
        asOfSeconds: asOf.millisecondsSinceEpoch ~/ 1000,
      );
      expect(rows, isEmpty);
    });

    test('ledger opening balance of an expense account is debit-positive', () async {
      final past = DateTime.now().subtract(const Duration(days: 10));
      await ds.insertInvoice(
        invoice(
          number: 'SI-PAST',
          amount: 200,
          date: past.millisecondsSinceEpoch ~/ 1000,
          lines: [line(quantity: 2)],
        ),
      );

      final opening = await reports.getGeneralLedgerOpeningBalance(
        accountId: cogsAccountId,
        beforeDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(opening, closeTo(100, 0.01));
    });
  });
}
