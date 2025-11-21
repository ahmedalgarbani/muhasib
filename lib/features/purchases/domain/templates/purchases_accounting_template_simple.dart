import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart';

/// Simplified template for generating journal entries for purchase transactions
class PurchasesAccountingTemplate {
  /// Generate journal entry for a purchase invoice
  static JournalEntryEntity generatePurchaseEntry({
    required InvoiceEntity purchase,
    required int inventoryAccountId,
    required int cashAccountId,
    required int payableAccountId,
    required String currencyCode,
  }) {
    final lines = <JournalEntryLineEntity>[];

    // Calculate amounts with null safety
    final subtotal = purchase.amount ?? 0;
    final taxAmount = purchase.taxAmt ?? 0;
    final totalAmount = purchase.finalAmt ?? 0;
    final isCashPurchase = purchase.invoiceTransType == 0;

    // 1. Debit: Inventory/Purchases Account (including tax)
    lines.add(
      JournalEntryLineEntity(
        lineNumber: 1,
        accountId: inventoryAccountId,
        accountCode: 'INV',
        accountName: 'المخزون/المشتريات',
        currencyId: purchase.currencyId,
        currencyCode: currencyCode,
        debit: totalAmount,
        credit: 0,
        notes: 'مشتريات - فاتورة رقم ${purchase.number}',
      ),
    );

    // 2. Credit: Cash/Bank or Accounts Payable
    if (isCashPurchase) {
      lines.add(
        JournalEntryLineEntity(
          lineNumber: 2,
          accountId: cashAccountId,
          accountCode: 'CASH',
          accountName: 'النقدية/البنك',
          currencyId: purchase.currencyId,
          currencyCode: currencyCode,
          debit: 0,
          credit: totalAmount,
          notes: 'دفع نقدي - فاتورة رقم ${purchase.number}',
        ),
      );
    } else {
      lines.add(
        JournalEntryLineEntity(
          lineNumber: 2,
          accountId: payableAccountId,
          accountCode: 'AP',
          accountName: 'الموردون',
          currencyId: purchase.currencyId,
          currencyCode: currencyCode,
          debit: 0,
          credit: totalAmount,
          notes: 'مورد آجل - فاتورة رقم ${purchase.number}',
        ),
      );
    }

    return JournalEntryEntity(
      number: 'PUR-${purchase.number}',
      entryDate: DateTime.fromMillisecondsSinceEpoch(purchase.date * 1000),
      description: 'قيد مشتريات - ${purchase.statement ?? purchase.number}',
      referenceNumber: purchase.number,
      totalDebit: totalAmount,
      totalCredit: totalAmount,
      difference: 0,
      status: 0,
      isPosted: false,
      lines: lines,
    );
  }
}
