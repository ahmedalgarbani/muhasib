import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/purchases/domain/templates/purchases_accounting_template.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/templates/sales_accounting_template.dart';

void main() {
  group('Accounting templates', () {
    test('sales invoice balances revenue, VAT, receivable and COGS', () {
      final template = SalesAccountingTemplate();
      final result = template.generateSalesInvoiceEntries(
        customerId: 1,
        customerName: 'عميل',
        invoiceNumber: 'SI-1',
        invoiceDate: 1,
        totalAmount: 1150,
        taxAmount: 150,
        netAmount: 1000,
        isCash: false,
        lines: [
          InvoiceLineEntry.fromInvoiceLine(
            categoryId: 1,
            productName: 'منتج',
            quantity: 10,
            unitPrice: 100,
            costPerUnit: 70,
          ),
        ],
      );

      expect(template.validateEntries(result), isTrue);
      expect(result['total_debit'], 1850);
      expect(result['total_credit'], 1850);
    });

    test('sales return reverses revenue, VAT and COGS', () {
      final template = SalesAccountingTemplate();
      final result = template.generateSalesReturnEntries(
        customerId: 1,
        customerName: 'عميل',
        returnNumber: 'SR-1',
        originalInvoiceNumber: 'SI-1',
        returnDate: 1,
        totalAmount: 575,
        taxAmount: 75,
        netAmount: 500,
        lines: [
          InvoiceLineEntry.fromInvoiceLine(
            categoryId: 1,
            productName: 'منتج',
            quantity: 5,
            unitPrice: 100,
            costPerUnit: 70,
          ),
        ],
      );

      expect(template.validateEntries(result), isTrue);
      expect(result['total_debit'], 925.0);
      expect(result['total_credit'], 925.0);
    });

    test('cash and credit purchase entries remain balanced', () {
      final invoice = InvoiceEntity(
        invoiceType: 2,
        number: 'PI-1',
        date: 1,
        amount: 1000,
        taxAmt: 150,
        discountAmt: 50,
        finalAmt: 1100,
        stockId: 1,
        customerId: 1,
        invoiceTransType: 1,
      );

      expect(
        PurchasesAccountingTemplate.validateJournalEntry(
          PurchasesAccountingTemplate.createCashPurchaseEntry(
            invoice,
            config: PurchaseAccountConfig.defaults,
          ),
        ),
        isTrue,
      );
      expect(
        PurchasesAccountingTemplate.validateJournalEntry(
          PurchasesAccountingTemplate.createCreditPurchaseEntry(
            invoice,
            config: PurchaseAccountConfig.defaults,
          ),
        ),
        isTrue,
      );
    });

    test('sales return with discount preview remains balanced', () {
      final template = SalesAccountingTemplate();
      // net 1000 - discount 50 + tax 150 = final 1100
      final result = template.generateSalesReturnEntries(
        customerId: 1,
        customerName: 'عميل',
        returnNumber: 'SR-2',
        originalInvoiceNumber: 'SI-2',
        returnDate: 1,
        totalAmount: 1100,
        taxAmount: 150,
        netAmount: 1000,
        discountAmount: 50,
        lines: [
          InvoiceLineEntry.fromInvoiceLine(
            categoryId: 1,
            productName: 'منتج',
            quantity: 5,
            unitPrice: 200,
            costPerUnit: 70,
          ),
        ],
      );

      // Debit: 1000 (returns) + 150 (VAT) + 350 (COGS) = 1500
      // Credit: 1100 (customer) + 50 (discount reverse) + 350 (COGS) = 1500
      expect(template.validateEntries(result), isTrue);
      expect(result['total_debit'], 1500.0);
      expect(result['total_credit'], 1500.0);

      final entries = result['entries'] as List;
      final discountLine = entries.where(
        (e) => (e as Map<String, dynamic>)['account_code'] == '315',
      );
      expect(discountLine.length, 1);
      expect(discountLine.first['credit'], 50.0);
    });

    test('unbalanced entries are rejected', () {
      final template = SalesAccountingTemplate();
      expect(
        template.validateEntries({'total_debit': 100.0, 'total_credit': 99.0}),
        isFalse,
      );
    });
  });
}
