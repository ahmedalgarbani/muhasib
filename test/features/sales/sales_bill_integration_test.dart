import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_line_model.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'sales_return_audit_test.dart' as audit;

/// End-to-end sales-bill scenarios against a fresh SQLite database.
/// These tests verify the complete path: invoice -> journal -> balances -> stock.
void main() {
  late Database db;
  late InvoiceLocalDataSourceImpl dataSource;

  setUp(() async {
    db = await audit.createFreshTestDatabase();
    dataSource = InvoiceLocalDataSourceImpl(database: db);
  });

  tearDown(() => db.close());

  InvoiceModel invoiceFixture({
    int? id,
    int invoiceType = 1,
    required String number,
    required double amount,
    required double finalAmount,
    String statement = 'اختبار مبيعات',
    double discount = 0,
    double tax = 0,
    int customerId = 1,
    required int invoiceTransType,
    double paidAmount = 0,
    double bankPaidAmount = 0,
    required List<InvoiceLineModel> lines,
  }) {
    return InvoiceModel(
      id: id,
      invoiceType: invoiceType,
      number: number,
      date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      statement: statement,
      amount: amount,
      discountAmt: discount,
      taxAmt: tax,
      finalAmt: finalAmount,
      totalAmount: finalAmount,
      stockId: 1,
      customerId: customerId,
      invoiceTransType: invoiceTransType,
      paidAmount: paidAmount,
      bankPaidAmount: bankPaidAmount,
      paymentStatus: invoiceTransType == 1 ? 0 : 2,
      lines: lines,
    );
  }

  InvoiceLineModel lineFixture({
    int invoiceType = 1,
    double quantity = 1,
    double costPrice = 50,
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
      invoiceId: 0,
      customerId: 1,
      invoiceTransType: invoiceType == 4 ? 1 : 0,
      date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      costPrice: costPrice,
      costTotal: costPrice * quantity,
      baseQuantity: quantity,
    );
  }

  Future<List<Map<String, dynamic>>> activeJournalLines(
    String referenceType,
    int referenceId,
  ) async {
    final entries = await db.query(
      'journal_entries',
      where: 'reference_type = ? AND reference_id = ? AND status = 1',
      whereArgs: [referenceType, referenceId],
    );
    expect(entries, hasLength(1));
    expect(
      (entries.single['total_debit'] as num).toDouble(),
      closeTo((entries.single['total_credit'] as num).toDouble(), 0.01),
    );
    return db.query(
      'journal_entry_lines',
      where: 'journal_entry_id = ?',
      whereArgs: [entries.single['id']],
    );
  }

  double sumColumn(List<Map<String, dynamic>> lines, String column) => lines.fold(
        0,
        (sum, line) => sum + ((line[column] as num?)?.toDouble() ?? 0),
      );

  bool descriptionExists(List<Map<String, dynamic>> lines, String value) =>
      lines.any((line) => (line['description'] as String? ?? '').contains(value));

  Future<double> stockQuantity() async {
    final rows = await db.query(
      'warehouse_stocks',
      columns: ['quantity'],
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [1, 1],
    );
    return (rows.single['quantity'] as num).toDouble();
  }

  test('cash sale posts to cash, revenue, COGS and reduces stock', () async {
    final id = await dataSource.insertInvoice(
      invoiceFixture(
        number: 'SI-CASH',
        amount: 1000,
        finalAmount: 1000,
        invoiceTransType: 0,
        paidAmount: 1000,
        lines: [lineFixture(quantity: 2, costPrice: 50)],
      ),
    );

    final lines = await activeJournalLines('sales_invoice', id);
    expect(sumColumn(lines, 'debit_amount'), closeTo(1100, 0.01));
    expect(sumColumn(lines, 'credit_amount'), closeTo(1100, 0.01));
    expect(descriptionExists(lines, 'مبيعات نقدية'), isTrue);
    expect(descriptionExists(lines, 'تكلفة البضاعة المباعة'), isTrue);
    expect(await stockQuantity(), closeTo(8, 0.01));
  });

  test('bank sale posts the paid amount to the bank account', () async {
    final id = await dataSource.insertInvoice(
      invoiceFixture(
        number: 'SI-BANK',
        amount: 750,
        finalAmount: 750,
        statement: 'مبيعات بنك - اختبار',
        invoiceTransType: 0,
        bankPaidAmount: 750,
        lines: [lineFixture(quantity: 1, costPrice: 50)],
      ),
    );

    final lines = await activeJournalLines('sales_invoice', id);
    expect(sumColumn(lines, 'debit_amount'), closeTo(800, 0.01));
    expect(sumColumn(lines, 'credit_amount'), closeTo(800, 0.01));
    expect(descriptionExists(lines, 'مبيعات بنكية'), isTrue);
  });

  test('credit sale posts the remaining amount to customer receivable', () async {
    final id = await dataSource.insertInvoice(
      invoiceFixture(
        number: 'SI-CREDIT',
        amount: 900,
        finalAmount: 900,
        customerId: 2,
        invoiceTransType: 1,
        lines: [lineFixture(quantity: 1, costPrice: 50)],
      ),
    );

    final lines = await activeJournalLines('sales_invoice', id);
    expect(sumColumn(lines, 'debit_amount'), closeTo(950, 0.01));
    expect(sumColumn(lines, 'credit_amount'), closeTo(950, 0.01));
    expect(descriptionExists(lines, 'ذمم العملاء'), isTrue);
  });

  test('mixed cash, bank and credit payment remains balanced', () async {
    final id = await dataSource.insertInvoice(
      invoiceFixture(
        number: 'SI-MIXED',
        amount: 1000,
        finalAmount: 1000,
        customerId: 2,
        invoiceTransType: 1,
        paidAmount: 400,
        bankPaidAmount: 250,
        lines: const [],
      ),
    );

    final lines = await activeJournalLines('sales_invoice', id);
    expect(sumColumn(lines, 'debit_amount'), closeTo(1000, 0.01));
    expect(sumColumn(lines, 'credit_amount'), closeTo(1000, 0.01));
    expect(descriptionExists(lines, 'مبيعات نقدية'), isTrue);
    expect(descriptionExists(lines, 'مبيعات بنكية'), isTrue);
    expect(descriptionExists(lines, 'ذمم العملاء'), isTrue);
  });

  test('discount and VAT produce a balanced journal', () async {
    final id = await dataSource.insertInvoice(
      invoiceFixture(
        number: 'SI-TAX',
        amount: 1000,
        discount: 100,
        tax: 135,
        finalAmount: 1035,
        invoiceTransType: 0,
        paidAmount: 1035,
        lines: [lineFixture(quantity: 2, costPrice: 50)],
      ),
    );

    final lines = await activeJournalLines('sales_invoice', id);
    expect(sumColumn(lines, 'debit_amount'), closeTo(1235, 0.01));
    expect(sumColumn(lines, 'credit_amount'), closeTo(1235, 0.01));
    expect(descriptionExists(lines, 'خصم مسموح'), isTrue);
    expect(descriptionExists(lines, 'ضريبة مبيعات'), isTrue);
  });

  test('editing a sale reverses old effects before reposting new values', () async {
    final id = await dataSource.insertInvoice(
      invoiceFixture(
        number: 'SI-EDIT',
        amount: 1000,
        finalAmount: 1000,
        invoiceTransType: 0,
        paidAmount: 1000,
        lines: [lineFixture(quantity: 2, costPrice: 50)],
      ),
    );

    await dataSource.updateInvoice(
      invoiceFixture(
        id: id,
        number: 'SI-EDIT',
        amount: 500,
        finalAmount: 500,
        invoiceTransType: 0,
        paidAmount: 500,
        lines: [lineFixture(quantity: 1, costPrice: 50)],
      ),
    );

    final lines = await activeJournalLines('sales_invoice', id);
    expect(sumColumn(lines, 'credit_amount'), closeTo(550, 0.01));
    expect(await stockQuantity(), closeTo(9, 0.01));
    expect(
      (await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ? AND status = 2',
        whereArgs: ['sales_invoice', id],
      )),
      isNotEmpty,
    );
  });

  test('deleting a sale creates a reversal and restores stock', () async {
    final id = await dataSource.insertInvoice(
      invoiceFixture(
        number: 'SI-DELETE',
        amount: 500,
        finalAmount: 500,
        invoiceTransType: 0,
        paidAmount: 500,
        lines: [lineFixture(quantity: 1, costPrice: 50)],
      ),
    );

    await dataSource.deleteInvoice(id);

    expect(
      await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['sales_invoice_reversal', id],
      ),
      isNotEmpty,
    );
    expect(await stockQuantity(), closeTo(10, 0.01));
  });

  test('sales return reverses customer/revenue effects and restores stock', () async {
    final id = await dataSource.createReturnInvoice(
      invoiceFixture(
        invoiceType: 4,
        number: 'SR-INTEGRATION',
        amount: 500,
        finalAmount: 500,
        customerId: 2,
        invoiceTransType: 1,
        lines: [lineFixture(invoiceType: 4, quantity: 1, costPrice: 50)],
      ),
      0,
    );

    final lines = await activeJournalLines('sales_return', id);
    expect(sumColumn(lines, 'debit_amount'), closeTo(550, 0.01));
    expect(sumColumn(lines, 'credit_amount'), closeTo(550, 0.01));
    expect(await stockQuantity(), closeTo(11, 0.01));
  });

  test('quotation conversion posts one sale and locks the quotation', () async {
    final quotationId = await db.insert('invoices', {
      'invoice_type': 3,
      'number': 'Q-INTEGRATION',
      'date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'amount': 500,
      'stock_id': 1,
      'customer_id': 1,
      'invoice_trans_type': 0,
      'payment_status': 0,
    });

    final invoiceId = await dataSource.convertQuotationToInvoice(
      quotationId,
      invoiceFixture(
        number: 'SI-FROM-Q',
        amount: 500,
        finalAmount: 500,
        invoiceTransType: 0,
        paidAmount: 500,
        lines: [lineFixture(quantity: 1, costPrice: 50)],
      ),
    );

    expect(await activeJournalLines('sales_invoice', invoiceId), isNotEmpty);
    final quotation = await db.query(
      'invoices',
      columns: ['is_locked', 'next_invoice_id'],
      where: 'id = ?',
      whereArgs: [quotationId],
    );
    expect(quotation.single['is_locked'], 1);
    expect(quotation.single['next_invoice_id'], invoiceId);
  });

}
