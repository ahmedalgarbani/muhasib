import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_line_entity.dart';
import 'package:muhasib/core/services/account_config_service.dart';

/// قالب محاسبي للمشتريات
/// يحتوي على القواعد المحاسبية لتسجيل عمليات الشراء
class PurchasesAccountingTemplate {
  
  /// إنشاء قيد محاسبي لفاتورة مشتريات نقدية (Perpetual IAS2: صافي)
  static JournalEntryEntity createCashPurchaseEntry(
    InvoiceEntity invoice, {
    required PurchaseAccountConfig config,
  }) {
    final lines = <JournalLineEntity>[];
    // IAS2 صافي: المخزون يُسجّل بعد خصم الخصم التجاري وتحميل الرسوم القابلة للرسملة
    final discount = invoice.discountAmt ?? 0;
    final otherFee = invoice.otherFeeAmt ?? 0;
    final isFeeForInventory = invoice.otherFeeAccountId == null;
    final netInventory = (invoice.amount - discount + (isFeeForInventory ? otherFee : 0)).clamp(0, double.infinity) as double;
    
    // 1. مدين: المخزون بالصافي
    if (netInventory > 0.005) {
      lines.add(JournalLineEntity(
        accountId: config.inventoryAccountId,
        debit: netInventory,
        credit: 0,
        description: 'مخزون - مشتريات نقدية صافي - فاتورة رقم ${invoice.number}',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    // رسوم منفصلة لحساب مستقل
    if (otherFee > 0 && !isFeeForInventory) {
      lines.add(JournalLineEntity(
        accountId: invoice.otherFeeAccountId!,
        debit: otherFee,
        credit: 0,
        description: 'رسوم شراء - ${invoice.number}',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // 2. مدين: ضريبة مدخلات قابلة للاسترداد (إن وجدت)
    if (invoice.taxAmt != null && invoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: config.taxAccountId,
        debit: invoice.taxAmt!,
        credit: 0,
        description: 'ضريبة مدخلات ${invoice.taxRatio ?? 15}%',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // لا نسجّل الخصم كإيراد منفصل – تم تنتيه من المخزون (IAS2)
    
    // 4. دائن: حساب الصندوق
    lines.add(JournalLineEntity(
      accountId: config.cashAccountId,
      debit: 0,
      credit: invoice.finalAmt ?? (netInventory + (invoice.taxAmt ?? 0) + (isFeeForInventory ? 0 : otherFee)),
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

  /// إنشاء قيد محاسبي لفاتورة مشتريات آجلة (Perpetual صافي)
  static JournalEntryEntity createCreditPurchaseEntry(
    InvoiceEntity invoice, {
    required PurchaseAccountConfig config,
  }) {
    final lines = <JournalLineEntity>[];
    final discount = invoice.discountAmt ?? 0;
    final otherFee = invoice.otherFeeAmt ?? 0;
    final isFeeForInventory = invoice.otherFeeAccountId == null;
    final netInventory = (invoice.amount - discount + (isFeeForInventory ? otherFee : 0)).clamp(0, double.infinity) as double;
    
    // 1. مدين: المخزون بالصافي
    if (netInventory > 0.005) {
      lines.add(JournalLineEntity(
        accountId: config.inventoryAccountId,
        debit: netInventory,
        credit: 0,
        description: 'مخزون - مشتريات آجلة صافي - فاتورة رقم ${invoice.number}',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    if (otherFee > 0 && !isFeeForInventory) {
      lines.add(JournalLineEntity(
        accountId: invoice.otherFeeAccountId!,
        debit: otherFee,
        credit: 0,
        description: 'رسوم شراء - ${invoice.number}',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // 2. مدين: ضريبة مدخلات
    if (invoice.taxAmt != null && invoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: config.taxAccountId,
        debit: invoice.taxAmt!,
        credit: 0,
        description: 'ضريبة مدخلات ${invoice.taxRatio ?? 15}%',
        referenceType: 'purchase_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // 4. دائن: حساب الموردين
    lines.add(JournalLineEntity(
      accountId: config.suppliersAccountId,
      debit: 0,
      credit: invoice.finalAmt ?? (netInventory + (invoice.taxAmt ?? 0) + (isFeeForInventory ? 0 : otherFee)),
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

  /// إنشاء قيد محاسبي لمردود مشتريات (عكس صافي المخزون)
  static JournalEntryEntity createPurchaseReturnEntry(
    InvoiceEntity returnInvoice, {
    required PurchaseAccountConfig config,
  }) {
    final lines = <JournalLineEntity>[];
    final discount = returnInvoice.discountAmt ?? 0;
    final otherFee = returnInvoice.otherFeeAmt ?? 0;
    final isFeeForInventory = returnInvoice.otherFeeAccountId == null;
    final netInventoryReturn = (returnInvoice.amount - discount + (isFeeForInventory ? otherFee : 0)).clamp(0, double.infinity) as double;
    
    // 1. مدين: الموردين أو الصندوق
    final isCredit = returnInvoice.invoiceTransType == 1;
    if (isCredit) {
      lines.add(JournalLineEntity(
        accountId: config.suppliersAccountId,
        debit: returnInvoice.finalAmt ?? (netInventoryReturn + (returnInvoice.taxAmt ?? 0) + (isFeeForInventory ? 0 : otherFee)),
        credit: 0,
        description: 'عكس ذمة المورد - مردود ${returnInvoice.number}',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
        partnerId: returnInvoice.customerId,
        partnerType: 'supplier',
      ));
    } else {
      lines.add(JournalLineEntity(
        accountId: config.cashAccountId,
        debit: returnInvoice.finalAmt ?? (netInventoryReturn + (returnInvoice.taxAmt ?? 0) + (isFeeForInventory ? 0 : otherFee)),
        credit: 0,
        description: 'استرداد نقدي لمردود مشتريات',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    // 2. دائن: عكس المخزون بالصافي (Perpetual)
    if (netInventoryReturn > 0.005) {
      lines.add(JournalLineEntity(
        accountId: config.inventoryAccountId,
        debit: 0,
        credit: netInventoryReturn,
        description: 'عكس مخزون - مردود مشتريات ${returnInvoice.number}',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
      ));
    }
    if (otherFee > 0 && !isFeeForInventory) {
      lines.add(JournalLineEntity(
        accountId: returnInvoice.otherFeeAccountId!,
        debit: 0,
        credit: otherFee,
        description: 'عكس رسوم - ${returnInvoice.number}',
        referenceType: 'purchase_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    // 3. دائن: عكس ضريبة مدخلات
    if (returnInvoice.taxAmt != null && returnInvoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: config.taxAccountId,
        debit: 0,
        credit: returnInvoice.taxAmt!,
        description: 'عكس ضريبة مدخلات',
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
    required PurchaseAccountConfig config,
    String? referenceNumber,
    String? notes,
  }) {
    final lines = <JournalLineEntity>[];
    
    // 1. مدين: حساب الموردين
    lines.add(JournalLineEntity(
      accountId: config.suppliersAccountId,
      debit: amount,
      credit: 0,
      description: 'سداد للمورد #$supplierId',
      referenceType: 'supplier_payment',
      partnerId: supplierId,
      partnerType: 'supplier',
    ));
    
    // 2. دائن: حساب الصندوق/البنك
    final paymentAccountId = paymentMethod == 'bank' ? config.bankAccountId : config.cashAccountId;
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
