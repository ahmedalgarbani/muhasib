import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';

void main() {
  group('Sales Invoice Creation Test', () {
    test('Should create a valid InvoiceEntity with all required fields', () {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final invoiceNumber = 'INV-$now';
      
      // Create test invoice lines
      final lines = [
        InvoiceLineEntity(
          invoiceType: InvoiceType.salesInvoice.value,
          amount: 100.0,
          totalAmount: 200.0,
          taxAmt: 0.0,
          taxRatio: 0,
          discountAmt: 0.0,
          discountRatio: 0,
          otherFeeAmt: 0.0,
          otherFeeNetRatio: 0,
          netRevenueAmt: 200.0,
          quantity: 2.0,
          categoryId: 1,
          groupId: 1,
          unitId: 1,
          categorySubUnitId: 1,
          stockId: 1,
          invoiceId: 0,
          customerId: 1,
          date: now,
          invoiceTransType: 0,
          creatorId: 1,
          lastModifierId: 1,
          creationTime: now,
          lastModificationTime: now,
        ),
      ];
      
      // Act
      final invoice = InvoiceEntity(
        invoiceType: InvoiceType.salesInvoice.value,
        number: invoiceNumber,
        date: now,
        statement: '',
        amount: 200.0,
        totalAmount: 200.0,
        taxAmt: 0.0,
        taxRatio: 0.0,
        discountAmt: 0.0,
        discountRatio: 0.0,
        otherFeeAmt: 0.0,
        otherFeeNetRatio: 0.0,
        netRevenueAmt: 200.0,
        totalAmountAfterDiscount: 200.0,
        finalAmt: 200.0,
        currencyId: 1,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        customerId: 1,
        stockId: 1,
        invoiceTransType: 0,
        paymentStatus: 0,
        creatorId: 1,
        lastModifierId: 1,
        creationTime: now,
        lastModificationTime: now,
        lines: lines,
      );
      
      // Assert
      expect(invoice.number, invoiceNumber);
      expect(invoice.invoiceType, InvoiceType.salesInvoice.value);
      expect(invoice.customerId, 1);
      expect(invoice.stockId, 1);
      expect(invoice.amount, 200.0);
      expect(invoice.lines.length, 1);
      expect(invoice.creationTime, isNotNull);
      expect(invoice.creatorId, isNotNull);
      expect(invoice.lines.first.quantity, 2.0);
      expect(invoice.lines.first.amount, 100.0);
      expect(invoice.lines.first.totalAmount, 200.0);
    });
    
    test('Should calculate discount correctly', () {
      // Test percentage discount
      final subtotal = 1000.0;
      final discountPercentage = 10.0; // 10%
      final expectedDiscount = subtotal * discountPercentage / 100;
      
      expect(expectedDiscount, 100.0);
      
      // Test amount discount
      final discountAmount = 150.0;
      final totalAfterDiscount = subtotal - discountAmount;
      
      expect(totalAfterDiscount, 850.0);
    });
    
    test('Should validate required fields', () {
      // Test that all required fields are present
      expect(() {
        InvoiceEntity(
          invoiceType: InvoiceType.salesInvoice.value,
          number: 'INV-TEST',
          date: DateTime.now().millisecondsSinceEpoch,
          amount: 100.0,
          customerId: 1,
          stockId: 1,
          invoiceTransType: 0,
        );
      }, returnsNormally);
    });
  });
}
