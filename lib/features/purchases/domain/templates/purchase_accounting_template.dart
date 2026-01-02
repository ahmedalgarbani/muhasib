import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_line_entity.dart';
import 'package:muhasib/core/services/account_config_service.dart';

class PurchaseAccountingTemplate {
  static JournalEntryEntity createPurchaseInvoiceEntry({
    required InvoiceEntity invoice,
    required PurchaseAccountConfig config,
  }) {
    final lines = <JournalLineEntity>[];
    
    // Debit: Purchases (Cost)
    lines.add(JournalLineEntity(
      accountId: config.purchasesAccountId,
      debit: invoice.amount, // Subtotal
      credit: 0,
      description: 'مشتريات - فاتورة ${invoice.number}',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
    ));

    // Debit: Tax
    if (invoice.taxAmt != null && invoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: config.taxAccountId,
        debit: invoice.taxAmt!,
        credit: 0,
        description: 'ضريبة مشتريات',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }

    // Credit: Supplier or Cash/Bank
    final isCredit = invoice.invoiceTransType == 1;
    final totalAmount = invoice.finalAmt ?? invoice.amount;

    if (isCredit) {
      lines.add(JournalLineEntity(
        accountId: config.suppliersAccountId,
        debit: 0,
        credit: totalAmount,
        description: 'استحقاق للمورد',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
        partnerId: invoice.customerId, // Supplier ID
        partnerType: 'supplier',
      ));
    } else {
      // Assuming Cash for now if not credit. Could be Bank if we had that info.
      lines.add(JournalLineEntity(
        accountId: config.cashAccountId,
        debit: 0,
        credit: totalAmount,
        description: 'سداد نقدي للمشتريات',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }

    return JournalEntryEntity(
      date: invoice.date,
      description: 'قيد مشتريات - فاتورة ${invoice.number}',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    );
  }
}
