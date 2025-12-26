import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_entry_entity.dart';
import 'package:muhasib/features/sales/domain/entities/journal_line_entity.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';
import 'package:muhasib/core/services/account_config_service.dart';

/// قالب محاسبي محسّن للمبيعات
/// يدعم جميع سيناريوهات الدفع والترحيل المحاسبي
class ImprovedSalesAccountingTemplate {
  
  /// إنشاء قيود محاسبية لفاتورة مبيعات مع دفعات متعددة
  static List<JournalEntryEntity> createSalesInvoiceEntries({
    required InvoiceEntity invoice,
    required List<Payment> payments,
    required Customer customer,
    required SalesAccountConfig config,
    double? inventoryCost,
  }) {
    final entries = <JournalEntryEntity>[];
    final lines = <JournalLineEntity>[];
    
    // حساب المبالغ
    final subtotal = invoice.amount;
    final discountAmount = invoice.discountAmt ?? 0;
    final taxAmount = invoice.taxAmt ?? 0;
    final totalAmount = invoice.finalAmt ?? subtotal;
    
    // تجميع الدفعات حسب النوع
    double cashPayments = 0;
    double bankPayments = 0;
    double deferredPayments = 0;
    
    for (final payment in payments) {
      switch (payment.method) {
        case PaymentMethod.cash:
          cashPayments += payment.amount;
          break;
        case PaymentMethod.bank:
          bankPayments += payment.amount;
          break;
        case PaymentMethod.deferred:
          deferredPayments += payment.amount;
          break;
      }
    }
    
    final totalPaid = cashPayments + bankPayments;
    final remainingAmount = totalAmount - totalPaid;
    
    // 1. قيد المبيعات الرئيسي
    
    // الجانب المدين - النقد والبنك والعملاء
    if (cashPayments > 0) {
      lines.add(JournalLineEntity(
        accountId: config.cashAccountId,
        debit: cashPayments,
        credit: 0,
        description: 'مبيعات نقدية - فاتورة ${invoice.number}',
        referenceType: 'sales_invoice',
        referenceId: invoice.id,
      ));
    }
    
    if (bankPayments > 0) {
      lines.add(JournalLineEntity(
        accountId: config.bankAccountId,
        debit: bankPayments,
        credit: 0,
        description: 'مبيعات بنكية - فاتورة ${invoice.number}',
        referenceType: 'sales_invoice',
        referenceId: invoice.id,
      ));
    }
    
    if (remainingAmount > 0 || deferredPayments > 0) {
      // مبلغ آجل أو متبقي
      final deferredAmount = remainingAmount > 0 ? remainingAmount : deferredPayments;
      lines.add(JournalLineEntity(
        accountId: config.customersAccountId,
        debit: deferredAmount,
        credit: 0,
        description: 'ذمة مدينة للعميل ${customer.name}',
        referenceType: 'sales_invoice',
        referenceId: invoice.id,
        partnerId: int.tryParse(customer.id),
        partnerType: 'customer',
      ));
    }
    
    // الجانب الدائن - المبيعات والضريبة
    lines.add(JournalLineEntity(
      accountId: config.salesAccountId,
      debit: 0,
      credit: subtotal,
      description: 'إيراد مبيعات - فاتورة ${invoice.number}',
      referenceType: 'sales_invoice',
      referenceId: invoice.id,
    ));
    
    if (taxAmount > 0) {
      lines.add(JournalLineEntity(
        accountId: config.taxAccountId,
        debit: 0,
        credit: taxAmount,
        description: 'ضريبة مبيعات ${invoice.taxRatio ?? 15}%',
        referenceType: 'sales_invoice',
        referenceId: invoice.id,
      ));
    }
    
    // الخصم المسموح (إن وجد)
    if (discountAmount > 0) {
      lines.add(JournalLineEntity(
        accountId: config.discountAllowedAccountId,
        debit: discountAmount,
        credit: 0,
        description: 'خصم مسموح به على المبيعات',
        referenceType: 'sales_invoice',
        referenceId: invoice.id,
      ));
    }
    
    entries.add(JournalEntryEntity(
      date: invoice.date,
      description: 'قيد مبيعات - فاتورة ${invoice.number}',
      referenceType: 'sales_invoice',
      referenceId: invoice.id,
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    ));
    
    // 2. قيد تكلفة البضاعة المباعة (إن وجد)
    if (inventoryCost != null && inventoryCost > 0) {
      entries.add(JournalEntryEntity(
        date: invoice.date,
        description: 'قيد تكلفة البضاعة المباعة - فاتورة ${invoice.number}',
        referenceType: 'sales_invoice_cost',
        referenceId: invoice.id,
        lines: [
          JournalLineEntity(
            accountId: config.costOfGoodsSoldAccountId,
            debit: inventoryCost,
            credit: 0,
            description: 'تكلفة البضاعة المباعة',
            referenceType: 'sales_invoice_cost',
            referenceId: invoice.id,
          ),
          JournalLineEntity(
            accountId: config.inventoryAccountId,
            debit: 0,
            credit: inventoryCost,
            description: 'تخفيض المخزون',
            referenceType: 'sales_invoice_cost',
            referenceId: invoice.id,
          ),
        ],
        isAutomatic: true,
        status: 'posted',
      ));
    }
    
    // 3. معالجة الدفعة الزائدة (إن وجدت)
    if (totalPaid > totalAmount) {
      final overpayment = totalPaid - totalAmount;
      entries.add(JournalEntryEntity(
        date: invoice.date,
        description: 'قيد دفعة زائدة - فاتورة ${invoice.number}',
        referenceType: 'customer_overpayment',
        referenceId: invoice.id,
        lines: [
          JournalLineEntity(
            accountId: config.customersAccountId,
            debit: 0,
            credit: overpayment,
            description: 'رصيد دائن للعميل ${customer.name}',
            referenceType: 'customer_overpayment',
            referenceId: invoice.id,
            partnerId: int.tryParse(customer.id),
            partnerType: 'customer',
          ),
          JournalLineEntity(
            accountId: cashPayments > totalAmount ? config.cashAccountId : config.bankAccountId,
            debit: overpayment,
            credit: 0,
            description: 'دفعة زائدة مرحلة لرصيد العميل',
            referenceType: 'customer_overpayment',
            referenceId: invoice.id,
          ),
        ],
        isAutomatic: true,
        status: 'posted',
      ));
    }
    
    return entries;
  }

  /// إنشاء قيد محاسبي لمردود مبيعات
  static JournalEntryEntity createSalesReturnEntry({
    required InvoiceEntity returnInvoice,
    required Customer customer,
    required SalesAccountConfig config,
    double? inventoryCost,
  }) {
    final lines = <JournalLineEntity>[];
    
    // مدين: حساب مردودات المبيعات
    lines.add(JournalLineEntity(
      accountId: config.salesReturnsAccountId,
      debit: returnInvoice.amount,
      credit: 0,
      description: 'مردودات مبيعات - فاتورة ${returnInvoice.number}',
      referenceType: 'sales_return',
      referenceId: returnInvoice.id,
    ));
    
    // مدين: حساب الضريبة (عكس الضريبة)
    if (returnInvoice.taxAmt != null && returnInvoice.taxAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: config.taxAccountId,
        debit: returnInvoice.taxAmt!,
        credit: 0,
        description: 'عكس ضريبة مبيعات',
        referenceType: 'sales_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    // دائن: حساب العملاء أو الصندوق
    final isCredit = returnInvoice.invoiceTransType == 1;
    if (isCredit) {
      lines.add(JournalLineEntity(
        accountId: config.customersAccountId,
        debit: 0,
        credit: returnInvoice.finalAmt ?? returnInvoice.amount,
        description: 'تخفيض ذمة العميل ${customer.name}',
        referenceType: 'sales_return',
        referenceId: returnInvoice.id,
        partnerId: int.tryParse(customer.id),
        partnerType: 'customer',
      ));
    } else {
      lines.add(JournalLineEntity(
        accountId: config.cashAccountId,
        debit: 0,
        credit: returnInvoice.finalAmt ?? returnInvoice.amount,
        description: 'إرجاع نقدي للعميل',
        referenceType: 'sales_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    // دائن: حساب الخصم المسموح (عكس الخصم)
    if (returnInvoice.discountAmt != null && returnInvoice.discountAmt! > 0) {
      lines.add(JournalLineEntity(
        accountId: config.discountAllowedAccountId,
        debit: 0,
        credit: returnInvoice.discountAmt!,
        description: 'عكس خصم مسموح',
        referenceType: 'sales_return',
        referenceId: returnInvoice.id,
      ));
    }
    
    return JournalEntryEntity(
      date: returnInvoice.date,
      description: 'قيد مردود مبيعات - فاتورة ${returnInvoice.number}',
      referenceType: 'sales_return',
      referenceId: returnInvoice.id,
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    );
  }

  /// إنشاء قيد تحصيل من العملاء
  static JournalEntryEntity createCustomerPaymentEntry({
    required int customerId,
    required String customerName,
    required double amount,
    required int date,
    required PaymentMethod paymentMethod,
    required SalesAccountConfig config,
    String? referenceNumber,
    String? notes,
  }) {
    final lines = <JournalLineEntity>[];
    
    // مدين: حساب النقد/البنك
    final paymentAccountId = paymentMethod == PaymentMethod.bank ? config.bankAccountId : config.cashAccountId;
    lines.add(JournalLineEntity(
      accountId: paymentAccountId,
      debit: amount,
      credit: 0,
      description: 'تحصيل من العميل $customerName ${referenceNumber != null ? '- مرجع: $referenceNumber' : ''}',
      referenceType: 'customer_payment',
      partnerId: customerId,
      partnerType: 'customer',
    ));
    
    // دائن: حساب العملاء
    lines.add(JournalLineEntity(
      accountId: config.customersAccountId,
      debit: 0,
      credit: amount,
      description: 'سداد من العميل $customerName',
      referenceType: 'customer_payment',
      partnerId: customerId,
      partnerType: 'customer',
    ));
    
    return JournalEntryEntity(
      date: date,
      description: 'قيد تحصيل من العميل $customerName ${notes != null ? '- $notes' : ''}',
      referenceType: 'customer_payment',
      lines: lines,
      isAutomatic: true,
      status: 'posted',
    );
  }

  /// حساب رصيد العميل
  static double calculateCustomerBalance({
    required List<InvoiceEntity> invoices,
    required List<JournalEntryEntity> payments,
    required int customerId,
    required SalesAccountConfig config,
  }) {
    double balance = 0;
    
    // فواتير المبيعات الآجلة تزيد الرصيد المدين
    for (final invoice in invoices) {
      if (invoice.customerId == customerId) {
        if (invoice.invoiceType == 1 && invoice.invoiceTransType == 1) {
          // فاتورة مبيعات آجلة
          balance += invoice.finalAmt ?? invoice.amount;
        } else if (invoice.invoiceType == 4) {
          // مردود مبيعات يقلل الرصيد
          balance -= invoice.finalAmt ?? invoice.amount;
        }
      }
    }
    
    // المدفوعات تقلل الرصيد المدين
    for (final payment in payments) {
      for (final line in payment.lines) {
        if (line.partnerId == customerId && 
            line.partnerType == 'customer' &&
            line.accountId == config.customersAccountId) {
          if (line.credit > 0) {
            balance -= line.credit; // سداد من العميل
          } else if (line.debit > 0) {
            balance += line.debit; // زيادة في الذمة
          }
        }
      }
    }
    
    return balance;
  }

  /// التحقق من صحة القيد المحاسبي
  static bool validateJournalEntry(JournalEntryEntity entry) {
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
        'warehouse_id': invoice.stockId,
        'action': invoice.invoiceType == 4 ? 'increase' : 'decrease', // 4 = sales return
      };
    }
    
    return impact;
  }
}
