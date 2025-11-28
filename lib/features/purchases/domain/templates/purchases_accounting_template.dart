import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_line_entity.dart';

/// قالب محاسبي للمشتريات
/// يحتوي على القواعد المحاسبية لتسجيل عمليات الشراء
class PurchasesAccountingTemplate {
  // معرفات الحسابات الافتراضية
  static const int purchasesAccountId = 501; // حساب المشتريات
  static const int inventoryAccountId = 141; // حساب المخزون
  static const int cashAccountId = 121; // حساب الصندوق
  static const int bankAccountId = 122; // حساب البنك
  static const int suppliersAccountId = 201; // حساب الموردين
  static const int taxPayableAccountId = 221; // حساب ضريبة المشتريات المستحقة
  static const int purchaseReturnsAccountId = 502; // حساب مردودات المشتريات
  static const int discountReceivedAccountId = 503; // حساب الخصم المكتسب

  /// إنشاء قيد محاسبي لفاتورة مشتريات نقدية
  static JournalEntryEntity createCashPurchaseEntry(InvoiceEntity invoice) {
    final lines = <JournalLineEntity>[];
    
    // 1. مدين: حساب المشتريات أو المخزون
    lines.add(JournalLineEntity(
      accountId: inventoryAccountId,
      debit: invoice.amount,
      credit: 0,
      description: 'مشتريات نقدية - فاتورة رقم ${invoice.number}',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
    ));
    
    // 2. مدين: حساب ضريبة المشتريات (إن وجدت)
    if (invoice.taxAmt != null && invoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: taxPayableAccountId,
        debit: invoice.taxAmt!,
        credit: 0,
        description: 'ضريبة مشتريات ${invoice.taxRatio ?? 15}%',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // 3. دائن: حساب الخصم المكتسب (إن وجد)
    if (invoice.discountAmt != null && invoice.discountAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: discountReceivedAccountId,
        debit: 0,
        credit: invoice.discountAmt!,
        description: 'خصم مكتسب على المشتريات',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // 4. دائن: حساب الصندوق (لا يوجد حقل لطريقة الدفع، نفترض الصندوق)
    lines.add(JournalLineEntity(
      accountId: cashAccountId,
      debit: 0,
      credit: invoice.finalAmt ?? invoice.amount,
      description: 'دفع نقدي للمشتريات',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
    ));
    
    return JournalEntryEntity(
      date: invoice.date,
      description: 'قيد مشتريات نقدية - فاتورة رقم ${invoice.number}',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    );
  }

  /// إنشاء قيد محاسبي لفاتورة مشتريات آجلة
  static JournalEntryEntity createCreditPurchaseEntry(InvoiceEntity invoice) {
    final lines = <JournalLineEntity>[];
    
    // 1. مدين: حساب المشتريات أو المخزون
    lines.add(JournalLineEntity(
      accountId: inventoryAccountId,
      debit: invoice.amount,
      credit: 0,
      description: 'مشتريات آجلة - فاتورة رقم ${invoice.number}',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
    ));
    
    // 2. مدين: حساب ضريبة المشتريات (إن وجدت)
    if (invoice.taxAmt != null && invoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: taxPayableAccountId,
        debit: invoice.taxAmt!,
        credit: 0,
        description: 'ضريبة مشتريات ${invoice.taxRatio ?? 15}%',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // 3. دائن: حساب الخصم المكتسب (إن وجد)
    if (invoice.discountAmt != null && invoice.discountAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: discountReceivedAccountId,
        debit: 0,
        credit: invoice.discountAmt!,
        description: 'خصم مكتسب على المشتريات',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // 4. دائن: حساب الموردين
    lines.add(JournalLineEntity(
      accountId: suppliersAccountId,
      debit: 0,
      credit: invoice.finalAmt ?? invoice.amount,
      description: 'ذمة دائنة للمورد #${invoice.customerId}',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
      partnerId: invoice.customerId,
      partnerType: 'supplier',
    ));
    
    return JournalEntryEntity(
      date: invoice.date,
      description: 'قيد مشتريات آجلة - فاتورة رقم ${invoice.number}',
      referenceType: 'purchase_invoice',
      referenceId: invoice.id,
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    );
  }

  /// إنشاء قيد محاسبي لمردود مشتريات
  static JournalEntryEntity createPurchaseReturnEntry(InvoiceEntity returnInvoice) {
    final lines = <JournalLineEntity>[];
    
    // 1. مدين: حساب الموردين (أو الصندوق في حالة الإرجاع النقدي)
    final isCredit = returnInvoice.invoiceTransType == 1;
    if (isCredit) {
      lines.add(JournalLineEntity(
        accountId: suppliersAccountId,
        debit: returnInvoice.finalAmt ?? returnInvoice.amount,
        credit: 0,
        description: 'مردود مشتريات من المورد #${returnInvoice.customerId}',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
        partnerId: returnInvoice.customerId,
        partnerType: 'supplier',
      ));
    } else {
      lines.add(JournalLineEntity(
        accountId: cashAccountId,
        debit: returnInvoice.finalAmt ?? returnInvoice.amount,
        credit: 0,
        description: 'استرداد نقدي لمردود مشتريات',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    // 2. دائن: حساب مردودات المشتريات
    lines.add(JournalLineEntity(
      accountId: purchaseReturnsAccountId,
      debit: 0,
      credit: returnInvoice.amount,
      description: 'مردودات مشتريات - فاتورة رقم ${returnInvoice.number}',
      referenceType: 'purchase_return',
      referenceId: returnInvoice.id,
    ));
    
    // 3. دائن: حساب ضريبة المشتريات (عكس الضريبة)
    if (returnInvoice.taxAmt != null && returnInvoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: taxPayableAccountId,
        debit: 0,
        credit: returnInvoice.taxAmt!,
        description: 'عكس ضريبة مشتريات',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    // 4. مدين: حساب الخصم المكتسب (عكس الخصم)
    if (returnInvoice.discountAmt != null && returnInvoice.discountAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: discountReceivedAccountId,
        debit: returnInvoice.discountAmt!,
        credit: 0,
        description: 'عكس خصم مكتسب',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    return JournalEntryEntity(
      date: returnInvoice.date,
      description: 'قيد مردود مشتريات - فاتورة رقم ${returnInvoice.number}',
      referenceType: 'purchase_return',
      referenceId: returnInvoice.id,
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    );
  }

  /// إنشاء قيد سداد للموردين
  static JournalEntryEntity createSupplierPaymentEntry({
    required int supplierId,
    required double amount,
    required int date,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
  }) {
    final lines = <JournalLineEntity>[];
    
    // 1. مدين: حساب الموردين
    lines.add(JournalLineEntity(
      accountId: suppliersAccountId,
      debit: amount,
      credit: 0,
      description: 'سداد للمورد #$supplierId',
      referenceType: 'supplier_payment',
      partnerId: supplierId,
      partnerType: 'supplier',
    ));
    
    // 2. دائن: حساب الصندوق/البنك
    final paymentAccountId = paymentMethod == 'bank' ? bankAccountId : cashAccountId;
    lines.add(JournalLineEntity(
      accountId: paymentAccountId,
      debit: 0,
      credit: amount,
      description: 'دفعة للمورد ${referenceNumber != null ? '- رقم مرجعي: $referenceNumber' : ''}',
      referenceType: 'supplier_payment',
    ));
    
    return JournalEntryEntity(
      date: date,
      description: 'قيد سداد للمورد #$supplierId ${notes != null ? '- $notes' : ''}',
      referenceType: 'supplier_payment',
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    );
  }

  /// التحقق من صحة القيد المحاسبي
  static bool validateJournalEntry(JournalEntryEntity entry) {
    // التحقق من توازن القيد (مجموع المدين = مجموع الدائن)
    double totalDebit = 0;
    double totalCredit = 0;
    
    for (final line in entry.lines) {
      totalDebit += line.debit;
      totalCredit += line.credit;
    }
    
    // السماح بفرق بسيط بسبب التقريب
    return (totalDebit - totalCredit).abs() < 0.01;
  }

  /// حساب تأثير الفاتورة على المخزون
  static Map<String, dynamic> calculateInventoryImpact(InvoiceEntity invoice) {
    final impact = <String, dynamic>{};
    
    for (final line in invoice.lines) {
      impact['item_${line.groupId}'] = {
        'quantity': line.quantity,
        'cost': line.amount / line.quantity,
        'total_cost': line.amount,
        'warehouse_id': invoice.stockId,
        'action': invoice.invoiceType == 5 ? 'decrease' : 'increase', // 5 = purchase return
      };
    }
    
    return impact;
  }

  /// حساب رصيد المورد
  static double calculateSupplierBalance(List<InvoiceEntity> invoices, int supplierId) {
    double balance = 0;
    
    for (final invoice in invoices) {
      if (invoice.customerId != supplierId) continue;
      
      // فواتير المشتريات الآجلة تزيد الرصيد الدائن
      if (invoice.invoiceType == 2 && invoice.invoiceTransType == 1) {
        balance += invoice.finalAmt ?? invoice.amount;
      }
      // المردودات تقلل الرصيد الدائن
      else if (invoice.invoiceType == 5) {
        balance -= invoice.finalAmt ?? invoice.amount;
      }
      // المدفوعات تقلل الرصيد الدائن
      // TODO: Add payment tracking
    }
    
    return balance;
  }
}
