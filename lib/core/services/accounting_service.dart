import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';
import 'package:sqflite/sqflite.dart';

class AccountingService {
  final DatabaseService _databaseService;

  AccountingService(this._databaseService);

  /// Process a sales invoice and record all accounting entries
  Future<bool> processSalesInvoice({
    required Invoice invoice,
    required int userId,
  }) async {
    try {
      final db = await _databaseService.database;
      
      return await db.transaction((txn) async {
        // 1. Create the sales invoice record
        final invoiceId = await _createSalesInvoice(txn, invoice, userId);
        
        // 2. Create invoice items
        await _createInvoiceItems(txn, invoiceId, invoice.items);
        
        // 3. Process payments and create journal entries
        await _processPayments(txn, invoiceId, invoice);
        
        // 4. Update customer balance if needed
        if (invoice.customer != null) {
          await _updateCustomerBalance(txn, invoice);
        }
        
        // 5. Update inventory
        await _updateInventory(txn, invoice.items);
        
        // 6. Create accounting journal entries
        await _createJournalEntries(txn, invoice, invoiceId);
        
        return true;
      });
    } catch (e) {
      print('Error processing sales invoice: $e');
      return false;
    }
  }

  Future<int> _createSalesInvoice(
    Transaction txn,
    Invoice invoice,
    int userId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    return await txn.insert('sales_invoices', {
      'invoice_number': invoice.number,
      'customer_id': invoice.customer?.id != null ? int.parse(invoice.customer!.id) : null,
      'invoice_date': invoice.date.millisecondsSinceEpoch ~/ 1000,
      'subtotal': invoice.subtotal,
      'discount_type': invoice.discount.type == DiscountType.percent ? 'percent' : 'amount',
      'discount_value': invoice.discount.value,
      'discount_amount': invoice.discountAmount,
      'other_charges': invoice.otherCharges,
      'total_amount': invoice.total,
      'paid_amount': invoice.paid,
      'remaining_amount': invoice.remaining,
      'payment_status': invoice.isFullyPaid ? 2 : (invoice.isPartiallyPaid ? 1 : 0),
      'notes': invoice.notes,
      'warehouse': invoice.warehouse,
      'currency': invoice.currency,
      'creator_id': userId,
      'creation_time': now,
      'last_modification_time': now,
    });
  }

  Future<void> _createInvoiceItems(
    Transaction txn,
    int invoiceId,
    List<InvoiceItem> items,
  ) async {
    for (final item in items) {
      await txn.insert('sales_invoice_items', {
        'invoice_id': invoiceId,
        'product_id': int.parse(item.id),
        'product_name': item.name,
        'barcode': item.barcode,
        'quantity': item.quantity,
        'unit_price': item.price,
        'total_price': item.total,
        'unit': item.unit,
      });
    }
  }

  Future<void> _processPayments(
    Transaction txn,
    int invoiceId,
    Invoice invoice,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    for (final payment in invoice.payments) {
      // Create payment record
      await txn.insert('payments', {
        'invoice_id': invoiceId,
        'payment_method': _getPaymentMethodString(payment.method),
        'amount': payment.amount,
        'payment_date': now,
        'details': payment.details?.toString(),
        'creation_time': now,
      });
      
      // Update cash box or bank account based on payment method
      if (payment.method == PaymentMethod.cash) {
        await _updateCashBox(txn, payment);
      } else if (payment.method == PaymentMethod.bank) {
        await _updateBankAccount(txn, payment);
      }
    }
    
    // Handle overpayment (add to customer credit)
    if (invoice.paid > invoice.total) {
      final overpayment = invoice.paid - invoice.total;
      await _addCustomerCredit(txn, invoice.customer!, overpayment);
    }
    
    // Handle underpayment (add to customer debt)
    if (invoice.remaining > 0) {
      await _addCustomerDebt(txn, invoice.customer!, invoice.remaining);
    }
  }

  Future<void> _updateCustomerBalance(
    Transaction txn,
    Invoice invoice,
  ) async {
    if (invoice.customer == null) return;
    
    final customerId = int.parse(invoice.customer!.id);
    
    // Get current customer balance
    final customerData = await txn.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    
    if (customerData.isNotEmpty) {
      final currentBalance = (customerData.first['current_balance'] as num?)?.toDouble() ?? 0.0;
      double newBalance = currentBalance;
      
      // Add debt if invoice is not fully paid
      if (invoice.remaining > 0) {
        newBalance += invoice.remaining;
      }
      
      // Subtract credit if overpaid
      if (invoice.paid > invoice.total) {
        newBalance -= (invoice.paid - invoice.total);
      }
      
      // Update customer balance
      await txn.update(
        'customers',
        {
          'current_balance': newBalance,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
      // Update account balance
      if (customerData.first['account_id'] != null) {
        await txn.update(
          'accounts',
          {
            'balance': newBalance,
            'local_balance': newBalance,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
          where: 'id = ?',
          whereArgs: [customerData.first['account_id']],
        );
      }
    }
  }

  Future<void> _updateInventory(
    Transaction txn,
    List<InvoiceItem> items,
  ) async {
    for (final item in items) {
      final productId = int.parse(item.id);
      
      // Get current stock
      final productData = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      
      if (productData.isNotEmpty) {
        final currentStock = (productData.first['quantity'] as num?)?.toDouble() ?? 0.0;
        final newStock = currentStock - item.quantity;
        
        // Update product quantity
        await txn.update(
          'products',
          {
            'quantity': newStock,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
        
        // Create inventory transaction record
        await txn.insert('inventory_transactions', {
          'product_id': productId,
          'transaction_type': 'sale',
          'quantity': -item.quantity,
          'unit_price': item.price,
          'total_amount': item.total,
          'balance_after': newStock,
          'reference_type': 'sales_invoice',
          'reference_id': item.id,
          'transaction_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
    }
  }

  Future<void> _createJournalEntries(
    Transaction txn,
    Invoice invoice,
    int invoiceId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create journal entry header
    final journalId = await txn.insert('journal_entries', {
      'entry_date': invoice.date.millisecondsSinceEpoch ~/ 1000,
      'description': 'فاتورة مبيعات رقم ${invoice.number}',
      'reference_type': 'sales_invoice',
      'reference_id': invoiceId,
      'total_debit': invoice.total,
      'total_credit': invoice.total,
      'creation_time': now,
    });
    
    // Debit entries (what we receive)
    if (invoice.paid > 0) {
      // Cash/Bank account (debit)
      for (final payment in invoice.payments) {
        int accountId;
        if (payment.method == PaymentMethod.cash) {
          accountId = await _getCashAccountId(txn, payment.details?['cashBox']);
        } else if (payment.method == PaymentMethod.bank) {
          accountId = await _getBankAccountId(txn, payment.details?['bank']);
        } else {
          continue; // Skip deferred payments for now
        }
        
        await txn.insert('journal_entry_lines', {
          'journal_entry_id': journalId,
          'account_id': accountId,
          'debit_amount': payment.amount,
          'credit_amount': 0,
          'description': 'دفعة ${_getPaymentMethodString(payment.method)}',
        });
      }
    }
    
    // Customer account (debit) for remaining amount
    if (invoice.remaining > 0 && invoice.customer != null) {
      final customerAccountId = await _getCustomerAccountId(txn, invoice.customer!);
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': journalId,
        'account_id': customerAccountId,
        'debit_amount': invoice.remaining,
        'credit_amount': 0,
        'description': 'ذمم مدينة - ${invoice.customer!.name}',
      });
    }
    
    // Credit entries (what we give)
    // Sales revenue account (credit)
    final salesAccountId = await _getSalesAccountId(txn);
    await txn.insert('journal_entry_lines', {
      'journal_entry_id': journalId,
      'account_id': salesAccountId,
      'debit_amount': 0,
      'credit_amount': invoice.subtotal,
      'description': 'إيرادات مبيعات',
    });
    
    // Discount account (debit) if applicable
    if (invoice.discountAmount > 0) {
      final discountAccountId = await _getDiscountAccountId(txn);
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': journalId,
        'account_id': discountAccountId,
        'debit_amount': invoice.discountAmount,
        'credit_amount': 0,
        'description': 'خصومات ممنوحة',
      });
    }
    
    // Other charges account (credit) if applicable
    if (invoice.otherCharges > 0) {
      final otherChargesAccountId = await _getOtherChargesAccountId(txn);
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': journalId,
        'account_id': otherChargesAccountId,
        'debit_amount': 0,
        'credit_amount': invoice.otherCharges,
        'description': 'رسوم إضافية',
      });
    }
  }

  Future<void> _updateCashBox(Transaction txn, Payment payment) async {
    final cashBoxName = payment.details?['cashBox'] ?? 'الصندوق الرئيسي';
    final accountId = await _getCashAccountId(txn, cashBoxName);
    
    // Update cash account balance
    await txn.rawUpdate('''
      UPDATE accounts 
      SET balance = balance + ?, 
          local_balance = local_balance + ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [payment.amount, payment.amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, accountId]);
  }

  Future<void> _updateBankAccount(Transaction txn, Payment payment) async {
    final bankName = payment.details?['bank'] ?? 'الراجحي';
    final accountId = await _getBankAccountId(txn, bankName);
    
    // Update bank account balance
    await txn.rawUpdate('''
      UPDATE accounts 
      SET balance = balance + ?, 
          local_balance = local_balance + ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [payment.amount, payment.amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, accountId]);
  }

  Future<void> _addCustomerCredit(Transaction txn, Customer customer, double amount) async {
    final customerId = int.parse(customer.id);
    
    // Update customer balance (negative means credit)
    await txn.rawUpdate('''
      UPDATE customers 
      SET current_balance = current_balance - ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, customerId]);
  }

  Future<void> _addCustomerDebt(Transaction txn, Customer customer, double amount) async {
    final customerId = int.parse(customer.id);
    
    // Update customer balance (positive means debt)
    await txn.rawUpdate('''
      UPDATE customers 
      SET current_balance = current_balance + ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, customerId]);
  }

  Future<int> _getCashAccountId(Transaction txn, String? cashBoxName) async {
    final name = cashBoxName ?? 'الصندوق الرئيسي';
    final accounts = await txn.query(
      'accounts',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    
    if (accounts.isNotEmpty) {
      return accounts.first['id'] as int;
    }
    
    // Create cash account if not exists
    return await txn.insert('accounts', {
      'c_id': 111,
      'code': '111',
      'name': name,
      'is_master': 0,
      'master_id': 11, // Cash parent account
      'type': 1, // Assets
      'national': 1,
      'is_active': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<int> _getBankAccountId(Transaction txn, String? bankName) async {
    final name = bankName ?? 'الراجحي';
    final accounts = await txn.query(
      'accounts',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    
    if (accounts.isNotEmpty) {
      return accounts.first['id'] as int;
    }
    
    // Create bank account if not exists
    return await txn.insert('accounts', {
      'c_id': 112,
      'code': '112',
      'name': name,
      'is_master': 0,
      'master_id': 11, // Banks parent account
      'type': 1, // Assets
      'national': 1,
      'is_active': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<int> _getCustomerAccountId(Transaction txn, Customer customer) async {
    final customerId = int.parse(customer.id);
    final customerData = await txn.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    
    if (customerData.isNotEmpty && customerData.first['account_id'] != null) {
      return customerData.first['account_id'] as int;
    }
    
    throw Exception('Customer account not found');
  }

  Future<int> _getSalesAccountId(Transaction txn) async {
    final accounts = await txn.query(
      'accounts',
      where: 'name = ?',
      whereArgs: ['إيرادات المبيعات'],
      limit: 1,
    );
    
    if (accounts.isNotEmpty) {
      return accounts.first['id'] as int;
    }
    
    // Create sales revenue account if not exists
    return await txn.insert('accounts', {
      'c_id': 411,
      'code': '411',
      'name': 'إيرادات المبيعات',
      'is_master': 0,
      'master_id': 41, // Revenue parent account
      'type': 4, // Revenue
      'national': 1,
      'is_active': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<int> _getDiscountAccountId(Transaction txn) async {
    final accounts = await txn.query(
      'accounts',
      where: 'name = ?',
      whereArgs: ['خصومات ممنوحة'],
      limit: 1,
    );
    
    if (accounts.isNotEmpty) {
      return accounts.first['id'] as int;
    }
    
    // Create discount account if not exists
    return await txn.insert('accounts', {
      'c_id': 412,
      'code': '412',
      'name': 'خصومات ممنوحة',
      'is_master': 0,
      'master_id': 41, // Revenue parent account
      'type': 4, // Revenue (contra)
      'national': 1,
      'is_active': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<int> _getOtherChargesAccountId(Transaction txn) async {
    final accounts = await txn.query(
      'accounts',
      where: 'name = ?',
      whereArgs: ['إيرادات أخرى'],
      limit: 1,
    );
    
    if (accounts.isNotEmpty) {
      return accounts.first['id'] as int;
    }
    
    // Create other charges account if not exists
    return await txn.insert('accounts', {
      'c_id': 419,
      'code': '419',
      'name': 'إيرادات أخرى',
      'is_master': 0,
      'master_id': 41, // Revenue parent account
      'type': 4, // Revenue
      'national': 1,
      'is_active': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bank:
        return 'bank';
      case PaymentMethod.deferred:
        return 'deferred';
    }
  }
}
