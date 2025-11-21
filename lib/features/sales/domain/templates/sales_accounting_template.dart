import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';

/// Accounting Entry Template for Sales Operations
/// 
/// This class provides templates for generating accounting journal entries
/// for various sales operations (invoices, returns, etc.)
/// 
/// Usage:
/// ```dart
/// final template = SalesAccountingTemplate();
/// final entries = await template.generateSalesInvoiceEntries(invoice);
/// await saveJournalEntries(entries);
/// ```

class SalesAccountingTemplate {
  // Account codes from the chart of accounts seeder
  static const String accountCodeCustomers = '112';      // العملاء (A/R)
  static const String accountCodeSales = '411';          // المبيعات
  static const String accountCodeSalesReturns = '415';   // مرتجعات المبيعات
  static const String accountCodeInventory = '113';      // المخزون
  static const String accountCodeCOGS = '316';           // تكلفة البضاعة المباعة
  static const String accountCodeCash = '111';           // النقدية والبنوك
  static const String accountCodeTaxPayable = '214';     // الضرائب المستحقة

  /// Generate accounting entries for a sales invoice
  /// 
  /// Journal Entry for Cash Sale:
  /// Dr. Cash/Bank          XXX
  ///     Cr. Sales Revenue      XXX
  /// 
  /// Journal Entry for Credit Sale:
  /// Dr. Customers (A/R)    XXX
  ///     Cr. Sales Revenue      XXX
  /// 
  /// If tax is included:
  /// Dr. Cash/Customers     XXX
  ///     Cr. Sales Revenue      XXX
  ///     Cr. Tax Payable        XXX
  /// 
  /// COGS Entry (Perpetual Inventory):
  /// Dr. COGS               XXX
  ///     Cr. Inventory          XXX
  Map<String, dynamic> generateSalesInvoiceEntries({
    required int customerId,
    required String customerName,
    required String invoiceNumber,
    required int invoiceDate,
    required double totalAmount,
    required double taxAmount,
    required double netAmount, // Amount before tax
    required bool isCash, // true for cash, false for credit
    required List<InvoiceLineEntry> lines,
  }) {
    final entries = <Map<String, dynamic>>[];
    
    // Entry 1: Record the sale
    // Debit: Cash or Customer Account
    entries.add({
      'line_number': 1,
      'account_code': isCash ? accountCodeCash : accountCodeCustomers,
      'account_name': isCash ? 'النقدية والبنوك' : 'العملاء - $customerName',
      'debit': totalAmount,
      'credit': 0.0,
      'notes': 'فاتورة مبيعات رقم $invoiceNumber',
    });
    
    // Credit: Sales Revenue
    entries.add({
      'line_number': 2,
      'account_code': accountCodeSales,
      'account_name': 'المبيعات',
      'debit': 0.0,
      'credit': netAmount,
      'notes': 'فاتورة مبيعات رقم $invoiceNumber',
    });
    
    // Credit: Tax Payable (if tax exists)
    if (taxAmount > 0) {
      entries.add({
        'line_number': 3,
        'account_code': accountCodeTaxPayable,
        'account_name': 'الضرائب المستحقة',
        'debit': 0.0,
        'credit': taxAmount,
        'notes': 'ضريبة فاتورة رقم $invoiceNumber',
      });
    }
    
    // Entry 2: Record Cost of Goods Sold (Perpetual Inventory System)
    double totalCost = lines.fold(0.0, (sum, line) => sum + line.costAmount);
    
    if (totalCost > 0) {
      entries.add({
        'line_number': entries.length + 1,
        'account_code': accountCodeCOGS,
        'account_name': 'تكلفة البضاعة المباعة',
        'debit': totalCost,
        'credit': 0.0,
        'notes': 'تكلفة فاتورة رقم $invoiceNumber',
      });
      
      entries.add({
        'line_number': entries.length + 1,
        'account_code': accountCodeInventory,
        'account_name': 'المخزون',
        'debit': 0.0,
        'credit': totalCost,
        'notes': 'تكلفة فاتورة رقم $invoiceNumber',
      });
    }
    
    return {
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'description': 'قيد فاتورة مبيعات رقم $invoiceNumber',
      'reference_number': invoiceNumber,
      'entries': entries,
      'total_debit': totalAmount + totalCost,
      'total_credit': totalAmount + totalCost,
    };
  }

  /// Generate accounting entries for a sales return invoice
  /// 
  /// This reverses the original sale entry and returns goods to inventory
  /// 
  /// Journal Entry:
  /// Dr. Sales Returns      XXX
  /// Dr. Tax Payable        XXX (if applicable)
  ///     Cr. Customers (A/R)    XXX
  /// 
  /// Inventory Entry:
  /// Dr. Inventory          XXX
  ///     Cr. COGS               XXX
  Map<String, dynamic> generateSalesReturnEntries({
    required int customerId,
    required String customerName,
    required String returnNumber,
    required String originalInvoiceNumber,
    required int returnDate,
    required double totalAmount,
    required double taxAmount,
    required double netAmount,
    required List<InvoiceLineEntry> lines,
  }) {
    final entries = <Map<String, dynamic>>[];
    
    // Entry 1: Reverse the sale
    // Debit: Sales Returns (Contra Revenue)
    entries.add({
      'line_number': 1,
      'account_code': accountCodeSalesReturns,
      'account_name': 'مرتجعات المبيعات',
      'debit': netAmount,
      'credit': 0.0,
      'notes': 'مرتجع فاتورة رقم $originalInvoiceNumber',
    });
    
    // Debit: Tax Payable (reverse the tax)
    if (taxAmount > 0) {
      entries.add({
        'line_number': 2,
        'account_code': accountCodeTaxPayable,
        'account_name': 'الضرائب المستحقة',
        'debit': taxAmount,
        'credit': 0.0,
        'notes': 'ضريبة مرتجع رقم $returnNumber',
      });
    }
    
    // Credit: Customer Account (reduce accounts receivable)
    entries.add({
      'line_number': entries.length + 1,
      'account_code': accountCodeCustomers,
      'account_name': 'العملاء - $customerName',
      'debit': 0.0,
      'credit': totalAmount,
      'notes': 'مرتجع فاتورة رقم $originalInvoiceNumber',
    });
    
    // Entry 2: Return goods to inventory
    double totalCost = lines.fold(0.0, (sum, line) => sum + line.costAmount);
    
    if (totalCost > 0) {
      // Debit: Inventory (increase stock)
      entries.add({
        'line_number': entries.length + 1,
        'account_code': accountCodeInventory,
        'account_name': 'المخزون',
        'debit': totalCost,
        'credit': 0.0,
        'notes': 'إرجاع بضاعة للمخزون - مرتجع $returnNumber',
      });
      
      // Credit: COGS (reverse cost)
      entries.add({
        'line_number': entries.length + 1,
        'account_code': accountCodeCOGS,
        'account_name': 'تكلفة البضاعة المباعة',
        'debit': 0.0,
        'credit': totalCost,
        'notes': 'إرجاع تكلفة - مرتجع $returnNumber',
      });
    }
    
    return {
      'invoice_number': returnNumber,
      'invoice_date': returnDate,
      'description': 'قيد مرتجع مبيعات رقم $returnNumber - الفاتورة الأصلية $originalInvoiceNumber',
      'reference_number': originalInvoiceNumber,
      'entries': entries,
      'total_debit': totalAmount + totalCost,
      'total_credit': totalAmount + totalCost,
    };
  }

  /// Generate accounting entries for payment received
  /// 
  /// Journal Entry:
  /// Dr. Cash/Bank          XXX
  ///     Cr. Customers (A/R)    XXX
  Map<String, dynamic> generatePaymentReceivedEntries({
    required int customerId,
    required String customerName,
    required String receiptNumber,
    required int receiptDate,
    required double amount,
    required String paymentMethod, // 'cash' or 'bank'
  }) {
    final entries = <Map<String, dynamic>>[];
    
    entries.add({
      'line_number': 1,
      'account_code': accountCodeCash,
      'account_name': paymentMethod == 'bank' ? 'البنك' : 'الصندوق',
      'debit': amount,
      'credit': 0.0,
      'notes': 'سداد من العميل $customerName',
    });
    
    entries.add({
      'line_number': 2,
      'account_code': accountCodeCustomers,
      'account_name': 'العملاء - $customerName',
      'debit': 0.0,
      'credit': amount,
      'notes': 'سداد إيصال رقم $receiptNumber',
    });
    
    return {
      'invoice_number': receiptNumber,
      'invoice_date': receiptDate,
      'description': 'قيد سداد من العميل $customerName',
      'reference_number': receiptNumber,
      'entries': entries,
      'total_debit': amount,
      'total_credit': amount,
    };
  }

  /// Validate that accounting entries are balanced
  /// Returns true if total debits equal total credits
  bool validateEntries(Map<String, dynamic> template) {
    final totalDebit = template['total_debit'] as double;
    final totalCredit = template['total_credit'] as double;
    
    // Allow for small floating point differences
    return (totalDebit - totalCredit).abs() < 0.01;
  }

  /// Get account by code from database
  /// Returns account details needed for journal entry
  Future<Map<String, dynamic>?> getAccountByCode(
    String code,
    Future<Map<String, dynamic>?> Function(String) dbQuery,
  ) async {
    return await dbQuery(code);
  }

  /// Preview accounting entries as human-readable text
  /// Useful for UI display before saving
  String previewEntries(Map<String, dynamic> template) {
    final StringBuffer buffer = StringBuffer();
    
    buffer.writeln('القيد المحاسبي: ${template['description']}');
    buffer.writeln('التاريخ: ${_formatDate(template['invoice_date'])}');
    buffer.writeln('المرجع: ${template['reference_number']}');
    buffer.writeln('${'=' * 60}');
    buffer.writeln('');
    
    final entries = template['entries'] as List<Map<String, dynamic>>;
    
    for (final entry in entries) {
      final debit = entry['debit'] as double;
      final credit = entry['credit'] as double;
      final accountName = entry['account_name'] as String;
      
      if (debit > 0) {
        buffer.writeln('من ح/ $accountName');
        buffer.writeln('    ${_formatAmount(debit)} (مدين)');
      } else if (credit > 0) {
        buffer.writeln('    إلى ح/ $accountName');
        buffer.writeln('    ${_formatAmount(credit)} (دائن)');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('${'=' * 60}');
    buffer.writeln('إجمالي المدين: ${_formatAmount(template['total_debit'])}');
    buffer.writeln('إجمالي الدائن: ${_formatAmount(template['total_credit'])}');
    buffer.writeln('');
    
    if (validateEntries(template)) {
      buffer.writeln('✓ القيد متوازن');
    } else {
      buffer.writeln('✗ تحذير: القيد غير متوازن!');
    }
    
    return buffer.toString();
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Invoice Line Entry for COGS calculation
class InvoiceLineEntry {
  final int categoryId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double costPerUnit;
  final double lineTotal;
  final double costAmount;

  InvoiceLineEntry({
    required this.categoryId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.costPerUnit,
    required this.lineTotal,
    required this.costAmount,
  });

  factory InvoiceLineEntry.fromInvoiceLine({
    required int categoryId,
    required String productName,
    required double quantity,
    required double unitPrice,
    required double costPerUnit,
  }) {
    return InvoiceLineEntry(
      categoryId: categoryId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      costPerUnit: costPerUnit,
      lineTotal: quantity * unitPrice,
      costAmount: quantity * costPerUnit,
    );
  }
}

/// Example Usage:
/// 
/// ```dart
/// // For Sales Invoice
/// final template = SalesAccountingTemplate();
/// final entries = template.generateSalesInvoiceEntries(
///   customerId: 1,
///   customerName: 'محمد أحمد',
///   invoiceNumber: 'INV-2025-001',
///   invoiceDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
///   totalAmount: 1150.0,
///   taxAmount: 150.0,
///   netAmount: 1000.0,
///   isCash: false,
///   lines: [
///     InvoiceLineEntry.fromInvoiceLine(
///       categoryId: 1,
///       productName: 'منتج أ',
///       quantity: 10.0,
///       unitPrice: 100.0,
///       costPerUnit: 70.0,
///     ),
///   ],
/// );
/// 
/// // Preview before saving
/// print(template.previewEntries(entries));
/// 
/// // Validate
/// if (template.validateEntries(entries)) {
///   // Save to database
///   await saveToJournalEntries(entries);
/// }
/// 
/// // For Sales Return
/// final returnEntries = template.generateSalesReturnEntries(
///   customerId: 1,
///   customerName: 'محمد أحمد',
///   returnNumber: 'RET-2025-001',
///   originalInvoiceNumber: 'INV-2025-001',
///   returnDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
///   totalAmount: 575.0,
///   taxAmount: 75.0,
///   netAmount: 500.0,
///   lines: [
///     InvoiceLineEntry.fromInvoiceLine(
///       categoryId: 1,
///       productName: 'منتج أ',
///       quantity: 5.0,
///       unitPrice: 100.0,
///       costPerUnit: 70.0,
///     ),
///   ],
/// );
/// ```
