import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:sqflite/sqflite.dart';

/// ⚠️ LEGACY / UNUSED: هذا المحرك المحاسبي غير مربوط بأي مسار إنتاجي.
/// مسار الترحيل الفعلي هو `_postSalesInvoiceToJournal` في
/// `lib/features/sales/data/datasources/invoice_local_datasource.dart`.
/// لا تُعدّل هذا الملف لتصحيح السلوك المحاسبي، ولا تربطه بالخطأ.
/// (يُستخدم فقط في `test/accounting_fixes_test.dart` كاختبارات تاريخية.)
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
        final invoiceId = await _createSalesInvoice(txn, invoice, userId);
        await _createInvoiceItems(txn, invoiceId, invoice.items);
        await _processPayments(txn, invoiceId, invoice);
        
        if (invoice.customer != null) {
          await _updateCustomerBalance(txn, invoice);
        }
        
        await _updateInventory(txn, invoice.items);
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
      if (payment.amount <= 0) {
        throw Exception('مبلغ الدفعة يجب أن يكون أكبر من صفر');
      }
      await txn.insert('payments', {
        'invoice_id': invoiceId,
        'payment_method': _getPaymentMethodString(payment.method),
        'amount': payment.amount,
        'payment_date': now,
        'details': payment.details?.toString(),
        'creation_time': now,
      });
      
      if (payment.method == PaymentMethod.cash) {
        await _updateCashBox(txn, payment);
      } else if (payment.method == PaymentMethod.bank) {
        await _updateBankAccount(txn, payment);
      }
      // deferred payments are not applied to cash/bank here; they remain as receivable
    }
    // CRITICAL FIX: Removed duplicate _addCustomerDebt/_addCustomerCredit.
    // Customer balance is now updated only once in _updateCustomerBalance
    // to prevent double-counting.
  }

  Future<void> _updateCustomerBalance(
    Transaction txn,
    Invoice invoice,
  ) async {
    if (invoice.customer == null) return;
    
    final customerId = int.parse(invoice.customer!.id);
    
    final customerData = await txn.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    
    if (customerData.isNotEmpty) {
      final currentBalance = (customerData.first['current_balance'] as num?)?.toDouble() ?? 0.0;
      double newBalance = currentBalance;
      
      if (invoice.remaining > 0) {
        newBalance += invoice.remaining;
      }
      
      if (invoice.paid > invoice.total) {
        newBalance -= (invoice.paid - invoice.total);
      }
      
      await txn.update(
        'customers',
        {
          'current_balance': newBalance,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
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
      
      final productData = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      
      if (productData.isNotEmpty) {
        final currentStock = (productData.first['quantity'] as num?)?.toDouble() ?? 0.0;
        if (item.trackInventory) {
          final requiredQty = item.inventoryQuantity;
          if (currentStock < requiredQty) {
            throw Exception('الكمية غير كافية للصنف ${item.name}: المتاح $currentStock، المطلوب $requiredQty');
          }
        }
        final newStock = currentStock - item.inventoryQuantity;
        
        await txn.update(
          'products',
          {
            'quantity': newStock,
            'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
        
        await txn.insert('inventory_transactions', {
          'product_id': productId,
          'transaction_type': 'sale',
          'quantity': -item.inventoryQuantity,
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
    
    // Validate fiscal period is open
    await _validateFiscalPeriod(txn, invoice.date);

    // Build balanced journal lines first, then insert header with correct totals
    final lines = <Map<String, dynamic>>[];
    
    // Debit: cash/bank payments
    if (invoice.paid > 0) {
      for (final payment in invoice.payments) {
        int accountId;
        if (payment.method == PaymentMethod.cash) {
          accountId = await _getCashAccountId(txn, payment.details?['cashBox']);
        } else if (payment.method == PaymentMethod.bank) {
          accountId = await _getBankAccountId(txn, payment.details?['bank']);
        } else {
          continue;
        }
        lines.add({
          'account_id': accountId,
          'debit_amount': payment.amount,
          'credit_amount': 0.0,
          'description': 'دفعة ${_getPaymentMethodString(payment.method)}',
        });
      }
    }
    
    // Debit: receivable for remaining
    if (invoice.remaining > 0 && invoice.customer != null) {
      final customerAccountId = await _getCustomerAccountId(txn, invoice.customer!);
      lines.add({
        'account_id': customerAccountId,
        'debit_amount': invoice.remaining,
        'credit_amount': 0.0,
        'description': 'ذمم مدينة - ${invoice.customer!.name}',
      });
    }

    // Debit: overpayment -> will be credited as customer advance (liability) below, keep debit side for cash already added
    double overpayment = 0;
    if (invoice.paid > invoice.total) {
      overpayment = invoice.paid - invoice.total;
    }
    
    // Credit: sales revenue (gross subtotal)
    final salesAccountId = await _getSalesAccountId(txn);
    lines.add({
      'account_id': salesAccountId,
      'debit_amount': 0.0,
      'credit_amount': invoice.subtotal,
      'description': 'إيرادات المبيعات',
    });
    
    // Debit: discount allowed (contra-revenue)
    if (invoice.discountAmount > 0) {
      final discountAccountId = await _getDiscountAccountId(txn);
      lines.add({
        'account_id': discountAccountId,
        'debit_amount': invoice.discountAmount,
        'credit_amount': 0.0,
        'description': 'خصومات ممنوحة',
      });
    }
    
    // Credit: other charges
    if (invoice.otherCharges > 0) {
      final otherChargesAccountId = await _getOtherChargesAccountId(txn);
      lines.add({
        'account_id': otherChargesAccountId,
        'debit_amount': 0.0,
        'credit_amount': invoice.otherCharges,
        'description': 'رسوم إضافية',
      });
    }

    // Credit: VAT (output tax)
    if (invoice.taxAmount > 0.005) {
      final vatAccountId = await _getVatAccountId(txn);
      lines.add({
        'account_id': vatAccountId,
        'debit_amount': 0.0,
        'credit_amount': invoice.taxAmount,
        'description': 'ضريبة قيمة مضافة - مخرجات',
      });
    }

    // Credit: customer advance for overpayment
    if (overpayment > 0.005 && invoice.customer != null) {
      final advancesAccountId = await _getCustomerAdvancesAccountId(txn);
      lines.add({
        'account_id': advancesAccountId,
        'debit_amount': 0.0,
        'credit_amount': overpayment,
        'description': 'دفعات مقدمة عملاء - ${invoice.customer!.name}',
      });
    }

    // COGS: Dr COGS / Cr Inventory for tracked items
    double totalCOGS = 0;
    for (final item in invoice.items) {
      if (item.trackInventory && item.costPrice != null) {
        totalCOGS += (item.costPrice! * item.inventoryQuantity);
      }
    }
    if (totalCOGS > 0.005) {
      final cogsAccountId = await _getCogsAccountId(txn);
      final inventoryAccountId = await _getInventoryAccountId(txn);
      lines.add({
        'account_id': cogsAccountId,
        'debit_amount': totalCOGS,
        'credit_amount': 0.0,
        'description': 'تكلفة البضاعة المباعة - ${invoice.number}',
      });
      lines.add({
        'account_id': inventoryAccountId,
        'debit_amount': 0.0,
        'credit_amount': totalCOGS,
        'description': 'صرف مخزون - ${invoice.number}',
      });
    }

    // Validate balance: Dr == Cr
    final totalDebit = lines.fold<double>(0, (s, l) => s + ((l['debit_amount'] as num).toDouble()));
    final totalCredit = lines.fold<double>(0, (s, l) => s + ((l['credit_amount'] as num).toDouble()));
    if ((totalDebit - totalCredit).abs() > 0.01) {
      throw Exception('قيد غير متوازن: مدين=$totalDebit دائن=$totalCredit - تحقق من الضريبة والخصم');
    }

    final journalId = await txn.insert('journal_entries', {
      'entry_date': invoice.date.millisecondsSinceEpoch ~/ 1000,
      'description': 'فاتورة مبيعات رقم ${invoice.number}',
      'reference_type': 'sales_invoice',
      'reference_id': invoiceId,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': 0.0,
      'status': 1,
      'is_posted': 1,
      'creation_time': now,
      'last_modification_time': now,
    });
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      await txn.insert('journal_entry_lines', {
        'journal_entry_id': journalId,
        'line_number': i + 1,
        'account_id': line['account_id'],
        'debit_amount': line['debit_amount'],
        'credit_amount': line['credit_amount'],
        'description': line['description'],
      });
      final debit = (line['debit_amount'] as num).toDouble();
      final credit = (line['credit_amount'] as num).toDouble();
      await _applyBalanceDelta(txn, line['account_id'] as int, debit - credit);
    }
  }

  Future<void> _validateFiscalPeriod(Transaction txn, DateTime date) async {
    final ts = date.millisecondsSinceEpoch ~/ 1000;
    final result = await txn.rawQuery('SELECT is_closed FROM fiscal_periods WHERE start_date <= ? AND end_date >= ? LIMIT 1', [ts, ts]);
    if (result.isNotEmpty && (result.first['is_closed'] as int?) == 1) {
      throw Exception('الفترة المالية مقفلة - لا يمكن الترحيل');
    }
  }

  Future<void> _applyBalanceDelta(Transaction txn, int accountId, double delta) async {
    await txn.rawUpdate('UPDATE accounts SET balance = COALESCE(balance,0) + ?, local_balance = COALESCE(local_balance,0) + ?, last_modification_time = ? WHERE id = ?', [delta, delta, DateTime.now().millisecondsSinceEpoch ~/ 1000, accountId]);
  }

  Future<void> _updateCashBox(Transaction txn, Payment payment) async {
    final cashBoxName = payment.details?['cashBox'] as String?;
    final accountId = await _getCashAccountId(txn, cashBoxName);
    
    await txn.rawUpdate('''
      UPDATE accounts 
      SET balance = balance + ?, 
          local_balance = local_balance + ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [payment.amount, payment.amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, accountId]);
  }

  Future<void> _updateBankAccount(Transaction txn, Payment payment) async {
    final bankName = payment.details?['bank'] as String?;
    final accountId = await _getBankAccountId(txn, bankName);
    
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
    
    await txn.rawUpdate('''
      UPDATE customers 
      SET current_balance = current_balance - ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, customerId]);
  }

  Future<void> _addCustomerDebt(Transaction txn, Customer customer, double amount) async {
    final customerId = int.parse(customer.id);
    
    await txn.rawUpdate('''
      UPDATE customers 
      SET current_balance = current_balance + ?,
          last_modification_time = ?
      WHERE id = ?
    ''', [amount, DateTime.now().millisecondsSinceEpoch ~/ 1000, customerId]);
  }

  Future<int> _getCashAccountId(Transaction txn, String? cashBoxName) async {
    // If name supplied, try by name first
    if (cashBoxName != null && cashBoxName.trim().isNotEmpty) {
      final byName = await txn.query('accounts', where: 'name = ?', whereArgs: [cashBoxName.trim()], limit: 1);
      if (byName.isNotEmpty) return byName.first['id'] as int;
    }
    // Live lookup: default cashbox from funds.is_main_fund or account_connects.cashboxes
    try {
      final fund = await txn.query('funds', where: 'is_main_fund = ? AND is_active = ?', whereArgs: [1, 1], limit: 1);
      if (fund.isNotEmpty && fund.first['account_id'] != null) {
        final accId = fund.first['account_id'] as int;
        final check = await txn.query('accounts', where: 'id = ?', whereArgs: [accId], limit: 1);
        if (check.isNotEmpty) return accId;
      }
    } catch (_) {}
    // Fallback via account_connects
    try {
      final conn = await txn.query('account_connects', where: 'account_connect_type = ?', whereArgs: [1], limit: 1);
      if (conn.isNotEmpty && conn.first['c_id'] != null) {
        final cId = conn.first['c_id'] as int;
        final acc = await txn.query('accounts', where: 'c_id = ?', whereArgs: [cId], limit: 1);
        if (acc.isNotEmpty) return acc.first['id'] as int;
      }
    } catch (_) {}
    throw Exception('الصندوق غير مهيأ — يرجى ضبط الصندوق الافتراضي من الإعدادات وربط الحسابات');
  }

  Future<int> _getBankAccountId(Transaction txn, String? bankName) async {
    if (bankName != null && bankName.trim().isNotEmpty) {
      final byName = await txn.query('accounts', where: 'name = ?', whereArgs: [bankName.trim()], limit: 1);
      if (byName.isNotEmpty) return byName.first['id'] as int;
    }
    // Live lookup: default bank from banks.is_main or account_connects.banks
    try {
      final bank = await txn.query('banks', where: 'is_active = ?', whereArgs: [1], limit: 1, orderBy: 'id ASC');
      if (bank.isNotEmpty && bank.first['account_id'] != null) {
        final accId = bank.first['account_id'] as int;
        final check = await txn.query('accounts', where: 'id = ?', whereArgs: [accId], limit: 1);
        if (check.isNotEmpty) return accId;
      }
    } catch (_) {}
    try {
      final conn = await txn.query('account_connects', where: 'account_connect_type = ?', whereArgs: [0], limit: 1);
      if (conn.isNotEmpty && conn.first['c_id'] != null) {
        final cId = conn.first['c_id'] as int;
        final acc = await txn.query('accounts', where: 'c_id = ?', whereArgs: [cId], limit: 1);
        if (acc.isNotEmpty) return acc.first['id'] as int;
      }
    } catch (_) {}
    throw Exception('الحساب البنكي غير مهيأ — يرجى ضبط البنك الافتراضي وربط الحسابات');
  }

  // Legacy helper kept private for internal fallback — not used after migration
  Future<int> _getCashAccountIdLegacy(Transaction txn, String name) async {
    final accounts = await txn.query('accounts', where: 'name = ?', whereArgs: [name], limit: 1);
    if (accounts.isNotEmpty) return accounts.first['id'] as int;
    return await txn.insert('accounts', {
      'c_id': 111,
      'code': '111',
      'name': name,
      'is_master': 0,
      'master_id': 11,
      'type': 0,
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
    
    return await txn.insert('accounts', {
      'c_id': 411,
      'code': '411',
      'name': 'إيرادات المبيعات',
      'is_master': 0,
      'master_id': 41,
      'type': 3,
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
    
    return await txn.insert('accounts', {
      'c_id': 412,
      'code': '412',
      'name': 'خصومات ممنوحة',
      'is_master': 0,
      'master_id': 41,
      'type': 3,
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
    
    return await txn.insert('accounts', {
      'c_id': 419,
      'code': '419',
      'name': 'إيرادات أخرى',
      'is_master': 0,
      'master_id': 41,
      'type': 3,
      'national': 1,
      'is_active': 1,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<int> _getVatAccountId(Transaction txn) async {
    final accounts = await txn.query('accounts', where: 'name = ?', whereArgs: ['ضريبة القيمة المضافة - مخرجات'], limit: 1);
    if (accounts.isNotEmpty) return accounts.first['id'] as int;
    // Try VAT payable general
    final vat = await txn.query('accounts', where: 'c_id = ?', whereArgs: [2140], limit: 1);
    if (vat.isNotEmpty) return vat.first['id'] as int;
    return await txn.insert('accounts', {'c_id': 2141, 'code': '2141', 'name': 'ضريبة القيمة المضافة - مخرجات', 'is_master': 0, 'master_id': 21, 'type': 1, 'national': 1, 'is_active': 1, 'balance': 0.0, 'local_balance': 0.0, 'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000, 'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000});
  }

  Future<int> _getCustomerAdvancesAccountId(Transaction txn) async {
    final acc = await txn.query('accounts', where: 'name = ?', whereArgs: ['دفعات مقدمة عملاء'], limit: 1);
    if (acc.isNotEmpty) return acc.first['id'] as int;
    final byCId = await txn.query('accounts', where: 'c_id = ?', whereArgs: [2120], limit: 1);
    if (byCId.isNotEmpty) return byCId.first['id'] as int;
    return await txn.insert('accounts', {'c_id': 2120, 'code': '2120', 'name': 'دفعات مقدمة عملاء', 'is_master': 0, 'master_id': 21, 'type': 1, 'national': 1, 'is_active': 1, 'balance': 0.0, 'local_balance': 0.0, 'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000, 'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000});
  }

  Future<int> _getInventoryAccountId(Transaction txn) async {
    final acc = await txn.query('accounts', where: 'name LIKE ?', whereArgs: ['%المخزون%'], limit: 1);
    if (acc.isNotEmpty) return acc.first['id'] as int;
    final byCId = await txn.query('accounts', where: 'c_id = ?', whereArgs: [1130], limit: 1);
    if (byCId.isNotEmpty) return byCId.first['id'] as int;
    return await txn.insert('accounts', {'c_id': 1130, 'code': '1130', 'name': 'المخزون', 'is_master': 0, 'master_id': 11, 'type': 0, 'national': 1, 'is_active': 1, 'balance': 0.0, 'local_balance': 0.0, 'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000, 'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000});
  }

  Future<int> _getCogsAccountId(Transaction txn) async {
    final acc = await txn.query('accounts', where: 'name LIKE ?', whereArgs: ['%تكلفة البضاعة%'], limit: 1);
    if (acc.isNotEmpty) return acc.first['id'] as int;
    final byCId = await txn.query('accounts', where: 'c_id = ?', whereArgs: [5110], limit: 1);
    if (byCId.isNotEmpty) return byCId.first['id'] as int;
    return await txn.insert('accounts', {'c_id': 5110, 'code': '5110', 'name': 'تكلفة البضاعة المباعة', 'is_master': 0, 'master_id': 51, 'type': 4, 'national': 1, 'is_active': 1, 'balance': 0.0, 'local_balance': 0.0, 'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000, 'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000});
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
