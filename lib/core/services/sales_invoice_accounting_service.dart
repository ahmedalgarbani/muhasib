import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Comprehensive service for sales invoice accounting operations
/// Handles: Journal entries, inventory updates, COGS, multiple payments, discounts, commissions
class SalesInvoiceAccountingService {
  final DatabaseService _databaseService;

  SalesInvoiceAccountingService(this._databaseService);

  // Table names
  static const String _journalEntriesTable = 'journal_entries';
  static const String _journalLinesTable = 'journal_entry_lines';
  static const String _invoicesTable = 'invoices';
  static const String _invoiceLinesTable = 'invoice_lines';
  static const String _invoicePaymentsTable = 'invoice_payments';
  static const String _warehouseStocksTable = 'warehouse_stocks';
  static const String _stockMovementsTable = 'stock_movements';
  static const String _customersTable = 'customers';
  static const String _accountsTable = 'accounts';
  static const String _accountLimitsTable = 'account_limits';

  /// Process a complete sales invoice with full accounting
  /// This is the main entry point for creating a sales invoice
  Future<Either<Failure, SalesInvoiceResult>> processSalesInvoice({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> invoiceLines,
    required List<PaymentInfo> payments,
    String? discountCode,
    int? salesAgentId,
  }) async {
    try {
      final db = await _databaseService.database;
      
      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // 1. Validate and apply discount code if provided
        double discountFromCode = 0.0;
        int? discountCodeId;
        if (discountCode != null && discountCode.isNotEmpty) {
          final discountResult = await _validateAndApplyDiscountCode(
            txn: txn,
            code: discountCode,
            customerId: invoiceData['customer_id'] as int?,
            orderAmount: (invoiceData['amount'] as num?)?.toDouble() ?? 0.0,
          );
          if (discountResult != null) {
            discountFromCode = discountResult['discount_amount'] as double;
            discountCodeId = discountResult['discount_code_id'] as int;
          }
        }
        
        // 2. Update invoice with discount from code
        final originalDiscount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
        final totalDiscount = originalDiscount + discountFromCode;
        invoiceData['discount_amt'] = totalDiscount;
        
        // 3. Recalculate totals
        final subtotal = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
        final taxRate = (invoiceData['tax_rate'] as num?)?.toDouble() ?? 0.15;
        final afterDiscount = subtotal - totalDiscount;
        final tax = afterDiscount * taxRate;
        final otherFees = (invoiceData['other_fee_amt'] as num?)?.toDouble() ?? 0.0;
        final finalAmount = afterDiscount + tax + otherFees;
        
        invoiceData['total_amount_after_discount'] = afterDiscount;
        invoiceData['tax_amt'] = tax;
        invoiceData['final_amt'] = finalAmount;
        invoiceData['creation_time'] = now;
        invoiceData['last_modification_time'] = now;
        
        // 4. Insert the invoice
        final invoiceId = await txn.insert(_invoicesTable, invoiceData);
        final invoiceNumber = invoiceData['number'] as String? ?? 'SI-$invoiceId';
        
        // 5. Insert invoice lines and update inventory
        double totalCOGS = 0.0;
        for (final line in invoiceLines) {
          line['invoice_id'] = invoiceId;
          await txn.insert(_invoiceLinesTable, line);
          
          // Use base_quantity for accurate inventory operations
          // base_quantity is the quantity converted to the product's base unit
          final baseQty = (line['base_quantity'] as num?)?.toDouble() ??
                         (line['quantity'] as num).toDouble();
          
          // Update inventory for each line - use base_quantity for accurate stock
          final stockResult = await _updateInventory(
            txn: txn,
            productId: line['product_id'] as int,
            warehouseId: line['warehouse_id'] as int? ?? 1,
            quantity: -baseQty, // Negative for sales, use converted base quantity
            unitCost: (line['cost_price'] as num?)?.toDouble() ?? 0.0,
            movementType: 'sale',
            referenceType: 'sales_invoice',
            referenceId: invoiceId,
            referenceNumber: invoiceNumber,
          );
          
          totalCOGS += stockResult['cogs'] as double? ?? 0.0;
        }
        
        // 6. Record discount code usage
        if (discountCodeId != null) {
          await txn.insert('discount_code_usage', {
            'discount_code_id': discountCodeId,
            'invoice_id': invoiceId,
            'customer_id': invoiceData['customer_id'],
            'discount_amount': discountFromCode,
            'used_at': now,
          });
          
          // Increment usage count
          await txn.rawUpdate(
            'UPDATE discount_codes SET current_uses = current_uses + 1 WHERE id = ?',
            [discountCodeId],
          );
        }
        
        // 7. Process payments and create journal entries
        final journalEntryIds = <int>[];
        double totalPaid = 0.0;
        
        for (int i = 0; i < payments.length; i++) {
          final payment = payments[i];
          totalPaid += payment.amount;
          
          final paymentResult = await _processPayment(
            txn: txn,
            invoiceId: invoiceId,
            invoiceNumber: invoiceNumber,
            paymentNumber: i + 1,
            payment: payment,
            invoiceData: invoiceData,
            totalCOGS: i == 0 ? totalCOGS : 0, // COGS only in first entry
            totalDiscount: i == 0 ? totalDiscount : 0, // Discount only in first entry
            now: now,
          );
          
          if (paymentResult['journal_entry_id'] != null) {
            journalEntryIds.add(paymentResult['journal_entry_id'] as int);
          }
        }
        
        // 8. If partial payment, create accounts receivable entry
        final remainingBalance = finalAmount - totalPaid;
        if (remainingBalance > 0.01) {
          await _createReceivableEntry(
            txn: txn,
            invoiceId: invoiceId,
            invoiceNumber: invoiceNumber,
            customerId: invoiceData['customer_id'] as int? ?? 1,
            amount: remainingBalance,
            now: now,
          );
        }
        
        // 9. Process sales commission if agent specified
        int? commissionEntryId;
        if (salesAgentId != null) {
          commissionEntryId = await _processSalesCommission(
            txn: txn,
            invoiceId: invoiceId,
            invoiceNumber: invoiceNumber,
            salesAgentId: salesAgentId,
            invoiceAmount: afterDiscount, // Commission on net sales
            now: now,
          );
          if (commissionEntryId != null) {
            journalEntryIds.add(commissionEntryId);
          }
        }
        
        // 10. Update customer balance
        final customerId = invoiceData['customer_id'] as int?;
        if (customerId != null && remainingBalance > 0.01) {
          await txn.rawUpdate(
            'UPDATE $_customersTable SET current_balance = COALESCE(current_balance, 0) + ? WHERE id = ?',
            [remainingBalance, customerId],
          );
        }
        
        return Right(SalesInvoiceResult(
          invoiceId: invoiceId,
          invoiceNumber: invoiceNumber,
          journalEntryIds: journalEntryIds,
          totalAmount: finalAmount,
          totalPaid: totalPaid,
          remainingBalance: remainingBalance,
          totalCOGS: totalCOGS,
          discountApplied: totalDiscount,
          commissionAmount: commissionEntryId != null ? (await _getCommissionAmount(txn, invoiceId)) : 0.0,
        ));
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في معالجة فاتورة المبيعات: ${e.toString()}'));
    }
  }

  /// Validate and apply discount code
  Future<Map<String, dynamic>?> _validateAndApplyDiscountCode({
    required Transaction txn,
    required String code,
    required int? customerId,
    required double orderAmount,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Get discount code
    final codeResult = await txn.query(
      'discount_codes',
      where: 'code = ? AND status = 1',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );
    
    if (codeResult.isEmpty) return null;
    
    final discountCode = codeResult.first;
    final discountCodeId = discountCode['id'] as int;
    
    // Check validity dates
    final validFrom = discountCode['valid_from'] as int?;
    final validTo = discountCode['valid_to'] as int?;
    if (validFrom != null && now < validFrom) return null;
    if (validTo != null && now > validTo) return null;
    
    // Check usage limits
    final maxUses = discountCode['max_uses'] as int?;
    final currentUses = discountCode['current_uses'] as int? ?? 0;
    if (maxUses != null && currentUses >= maxUses) return null;
    
    // Check per-customer usage
    if (customerId != null) {
      final maxPerCustomer = discountCode['max_uses_per_customer'] as int?;
      if (maxPerCustomer != null) {
        final usageResult = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM discount_code_usage WHERE discount_code_id = ? AND customer_id = ?',
          [discountCodeId, customerId],
        );
        final customerUsage = (usageResult.first['count'] as int?) ?? 0;
        if (customerUsage >= maxPerCustomer) return null;
      }
    }
    
    // Check minimum order amount
    final minOrder = (discountCode['min_order_amount'] as num?)?.toDouble() ?? 0.0;
    if (orderAmount < minOrder) return null;
    
    // Check customer restriction
    final restrictedCustomerId = discountCode['customer_id'] as int?;
    if (restrictedCustomerId != null && restrictedCustomerId != customerId) return null;
    
    // Calculate discount
    final discountType = discountCode['discount_type'] as int? ?? 0;
    final discountValue = (discountCode['discount_value'] as num?)?.toDouble() ?? 0.0;
    double discountAmount;
    
    if (discountType == 0) {
      // Percentage
      discountAmount = orderAmount * (discountValue / 100);
      final maxDiscount = (discountCode['max_discount_amount'] as num?)?.toDouble();
      if (maxDiscount != null && discountAmount > maxDiscount) {
        discountAmount = maxDiscount;
      }
    } else {
      // Fixed amount
      discountAmount = discountValue;
      if (discountAmount > orderAmount) {
        discountAmount = orderAmount;
      }
    }
    
    return {
      'discount_code_id': discountCodeId,
      'discount_amount': discountAmount,
    };
  }

  /// Update inventory and calculate COGS
  Future<Map<String, dynamic>> _updateInventory({
    required Transaction txn,
    required int productId,
    required int warehouseId,
    required double quantity,
    required double unitCost,
    required String movementType,
    required String referenceType,
    required int referenceId,
    required String referenceNumber,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    double cogs = 0.0;
    
    // Get current stock
    final stockResult = await txn.query(
      _warehouseStocksTable,
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [productId, warehouseId],
      limit: 1,
    );
    
    double currentQty = 0.0;
    double avgCost = unitCost;
    
    if (stockResult.isNotEmpty) {
      currentQty = (stockResult.first['quantity'] as num?)?.toDouble() ?? 0.0;
      avgCost = (stockResult.first['avg_cost'] as num?)?.toDouble() ?? unitCost;
    }
    
    // For sales (negative quantity), calculate COGS using average cost
    if (quantity < 0) {
      cogs = (-quantity) * avgCost;
    }
    
    final newQty = currentQty + quantity;
    
    // Update or insert stock
    if (stockResult.isNotEmpty) {
      await txn.update(
        _warehouseStocksTable,
        {
          'quantity': newQty,
          'last_modification_time': now,
        },
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [productId, warehouseId],
      );
    } else {
      await txn.insert(_warehouseStocksTable, {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': newQty,
        'avg_cost': avgCost,
        'creation_time': now,
        'last_modification_time': now,
      });
    }
    
    // Record stock movement
    await txn.insert(_stockMovementsTable, {
      'product_id': productId,
      'warehouse_id': warehouseId,
      'movement_type': movementType,
      'quantity': quantity,
      'unit_cost': avgCost,
      'total_cost': quantity.abs() * avgCost,
      'balance_after': newQty,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'reference_number': referenceNumber,
      'creation_time': now,
    });
    
    return {
      'cogs': cogs,
      'new_quantity': newQty,
      'avg_cost': avgCost,
    };
  }

  /// Process a payment and create journal entry
  Future<Map<String, dynamic>> _processPayment({
    required Transaction txn,
    required int invoiceId,
    required String invoiceNumber,
    required int paymentNumber,
    required PaymentInfo payment,
    required Map<String, dynamic> invoiceData,
    required double totalCOGS,
    required double totalDiscount,
    required int now,
  }) async {
    // Get account IDs from account_connects
    final salesAccountId = await _getConnectedAccountId(txn, 7, 4110); // Sales
    final cashAccountId = await _getConnectedAccountId(txn, 1, 1110);  // Cash
    final bankAccountId = await _getConnectedAccountId(txn, 0, 1110);  // Bank
    final customersAccountId = await _getConnectedAccountId(txn, 2, 1120); // Customers
    final taxAccountId = await _getConnectedAccountId(txn, 4, 2140);   // Tax
    final discountAccountId = await _getConnectedAccountId(txn, 8, 3150); // Discount Allowed
    final inventoryAccountId = await _getConnectedAccountId(txn, 5, 1130); // Inventory
    final cogsAccountId = await _getConnectedAccountId(txn, 13, 3160); // COGS
    
    // Determine payment account based on method
    int paymentAccountId;
    String paymentDescription;
    
    switch (payment.method) {
      case 0: // Cash
        paymentAccountId = cashAccountId;
        paymentDescription = 'دفعة نقدية';
        break;
      case 1: // Credit
        paymentAccountId = await _getCustomerAccountId(txn, invoiceData['customer_id'] as int?, customersAccountId);
        paymentDescription = 'على الحساب';
        break;
      case 2: // Bank Transfer
        paymentAccountId = payment.bankAccountId ?? bankAccountId;
        paymentDescription = 'حوالة بنكية';
        break;
      case 3: // Check
        paymentAccountId = payment.bankAccountId ?? bankAccountId;
        paymentDescription = 'شيك رقم ${payment.checkNumber ?? ""}';
        break;
      case 4: // Card
        paymentAccountId = payment.bankAccountId ?? bankAccountId;
        paymentDescription = 'بطاقة';
        break;
      default:
        paymentAccountId = cashAccountId;
        paymentDescription = 'دفعة';
    }
    
    // Insert payment record
    final paymentId = await txn.insert(_invoicePaymentsTable, {
      'invoice_id': invoiceId,
      'payment_number': paymentNumber,
      'payment_date': payment.date?.millisecondsSinceEpoch ?? now * 1000,
      'payment_method': payment.method,
      'amount': payment.amount,
      'local_amount': payment.amount * (payment.exchangeRate ?? 1.0),
      'currency_id': payment.currencyId,
      'exchange_rate': payment.exchangeRate ?? 1.0,
      'payment_account_id': paymentAccountId,
      'bank_id': payment.bankId,
      'check_number': payment.checkNumber,
      'check_date': payment.checkDate?.millisecondsSinceEpoch,
      'status': 1,
      'notes': payment.notes,
      'creation_time': now,
      'last_modification_time': now,
    });
    
    // Build journal entry lines
    final lines = <Map<String, dynamic>>[];
    int lineNumber = 1;
    
    final subtotal = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final netRevenue = subtotal - totalDiscount;
    
    // Calculate proportional amounts for this payment
    final totalAmount = (invoiceData['final_amt'] as num?)?.toDouble() ?? 0.0;
    final proportion = totalAmount > 0 ? payment.amount / totalAmount : 1.0;
    
    final proportionalTax = tax * proportion;
    final proportionalDiscount = totalDiscount * proportion;
    final proportionalCOGS = totalCOGS * proportion;
    final proportionalRevenue = netRevenue * proportion;
    
    // Debit: Payment account (cash, bank, or customer)
    lines.add({
      'account_id': paymentAccountId,
      'debit_amount': payment.amount,
      'credit_amount': 0.0,
      'description': '$paymentDescription - فاتورة $invoiceNumber',
    });
    
    // Debit: Discount allowed (if any)
    if (proportionalDiscount > 0.01) {
      lines.add({
        'account_id': discountAccountId,
        'debit_amount': proportionalDiscount,
        'credit_amount': 0.0,
        'description': 'خصم مسموح - فاتورة $invoiceNumber',
      });
    }
    
    // Credit: Sales revenue
    if (proportionalRevenue > 0.01) {
      lines.add({
        'account_id': salesAccountId,
        'debit_amount': 0.0,
        'credit_amount': proportionalRevenue,
        'description': 'إيراد مبيعات - فاتورة $invoiceNumber',
      });
    }
    
    // Credit: Tax payable (if any)
    if (proportionalTax > 0.01) {
      lines.add({
        'account_id': taxAccountId,
        'debit_amount': 0.0,
        'credit_amount': proportionalTax,
        'description': 'ضريبة مبيعات - فاتورة $invoiceNumber',
      });
    }
    
    // COGS Entry (Debit COGS, Credit Inventory)
    if (proportionalCOGS > 0.01) {
      lines.add({
        'account_id': cogsAccountId,
        'debit_amount': proportionalCOGS,
        'credit_amount': 0.0,
        'description': 'تكلفة بضاعة مباعة - فاتورة $invoiceNumber',
      });
      
      lines.add({
        'account_id': inventoryAccountId,
        'debit_amount': 0.0,
        'credit_amount': proportionalCOGS,
        'description': 'صرف مخزون - فاتورة $invoiceNumber',
      });
    }
    
    // Validate balance
    final totalDebit = lines.fold<double>(0.0, (s, l) => s + ((l['debit_amount'] as num?)?.toDouble() ?? 0.0));
    final totalCredit = lines.fold<double>(0.0, (s, l) => s + ((l['credit_amount'] as num?)?.toDouble() ?? 0.0));
    
    if ((totalDebit - totalCredit).abs() > 0.01) {
      throw LocalStorageException(
        'قيد غير متوازن: مدين=$totalDebit، دائن=$totalCredit'
      );
    }
    
    // Insert journal entry
    final journalNumber = await _nextJournalNumber(txn, 'SI');
    final journalEntryId = await txn.insert(_journalEntriesTable, {
      'number': journalNumber,
      'entry_date': now,
      'description': 'قيد مبيعات $invoiceNumber - $paymentDescription',
      'reference_type': 'sales_invoice',
      'reference_id': invoiceId,
      'reference_number': invoiceNumber,
      'status': 1,
      'is_posted': 1,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': 0.0,
      'creation_time': now,
      'last_modification_time': now,
    });
    
    // Insert journal lines and update account balances
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final accountId = line['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (line['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (line['credit_amount'] as num?)?.toDouble() ?? 0.0;
      
      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': i + 1,
        'account_id': accountId,
        'account_code': meta['code'],
        'account_name': meta['name'],
        'debit_amount': debit,
        'credit_amount': credit,
        'description': line['description'],
      });
      
      // Update account balance
      await txn.rawUpdate(
        'UPDATE $_accountsTable SET balance = COALESCE(balance, 0) + ? WHERE id = ?',
        [debit - credit, accountId],
      );
    }
    
    // Update payment with journal entry ID
    await txn.update(
      _invoicePaymentsTable,
      {'journal_entry_id': journalEntryId},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
    
    return {
      'payment_id': paymentId,
      'journal_entry_id': journalEntryId,
    };
  }

  /// Create accounts receivable entry for unpaid balance
  Future<int> _createReceivableEntry({
    required Transaction txn,
    required int invoiceId,
    required String invoiceNumber,
    required int customerId,
    required double amount,
    required int now,
  }) async {
    final customersAccountId = await _getConnectedAccountId(txn, 2, 1120);
    final customerAccountId = await _getCustomerAccountId(txn, customerId, customersAccountId);
    final salesAccountId = await _getConnectedAccountId(txn, 7, 4110);
    
    // Insert payment record for remaining balance
    await txn.insert(_invoicePaymentsTable, {
      'invoice_id': invoiceId,
      'payment_number': 999, // Special number for A/R
      'payment_date': now * 1000,
      'payment_method': 1, // Credit
      'amount': amount,
      'local_amount': amount,
      'payment_account_id': customerAccountId,
      'status': 0, // Pending
      'notes': 'رصيد مستحق',
      'creation_time': now,
      'last_modification_time': now,
    });
    
    return customerAccountId;
  }

  /// Process sales commission
  Future<int?> _processSalesCommission({
    required Transaction txn,
    required int invoiceId,
    required String invoiceNumber,
    required int salesAgentId,
    required double invoiceAmount,
    required int now,
  }) async {
    // Get agent info
    final agentResult = await txn.query(
      'sales_agents',
      where: 'id = ? AND is_active = 1',
      whereArgs: [salesAgentId],
      limit: 1,
    );
    
    if (agentResult.isEmpty) return null;
    
    final agent = agentResult.first;
    final commissionRate = (agent['commission_rate'] as num?)?.toDouble() ?? 0.0;
    final commissionType = agent['commission_type'] as int? ?? 0;
    final commissionAccountId = agent['commission_account_id'] as int?;
    
    if (commissionRate == 0) return null;
    
    double commissionAmount;
    if (commissionType == 0) {
      // Percentage
      commissionAmount = invoiceAmount * (commissionRate / 100);
    } else {
      // Fixed per invoice
      commissionAmount = commissionRate;
    }
    
    // Insert commission record
    await txn.insert('sales_commissions', {
      'invoice_id': invoiceId,
      'sales_agent_id': salesAgentId,
      'invoice_amount': invoiceAmount,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'status': 0, // Pending
      'creation_time': now,
    });
    
    // Update agent balance
    await txn.rawUpdate(
      'UPDATE sales_agents SET current_balance = current_balance + ? WHERE id = ?',
      [commissionAmount, salesAgentId],
    );
    
    // Create journal entry for commission expense
    if (commissionAccountId != null) {
      final commissionExpenseAccountId = await _getConnectedAccountId(txn, 14, 3180); // Sales Commission Expense
      
      final journalNumber = await _nextJournalNumber(txn, 'SC');
      final journalEntryId = await txn.insert(_journalEntriesTable, {
        'number': journalNumber,
        'entry_date': now,
        'description': 'عمولة مبيعات - فاتورة $invoiceNumber',
        'reference_type': 'sales_commission',
        'reference_id': invoiceId,
        'reference_number': invoiceNumber,
        'status': 1,
        'is_posted': 1,
        'total_debit': commissionAmount,
        'total_credit': commissionAmount,
        'difference': 0.0,
        'creation_time': now,
        'last_modification_time': now,
      });
      
      // Debit: Commission Expense
      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': 1,
        'account_id': commissionExpenseAccountId,
        'debit_amount': commissionAmount,
        'credit_amount': 0.0,
        'description': 'مصروف عمولة مبيعات',
      });
      
      // Credit: Commission Payable
      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': 2,
        'account_id': commissionAccountId,
        'debit_amount': 0.0,
        'credit_amount': commissionAmount,
        'description': 'عمولة مستحقة للمندوب',
      });
      
      // Update account balances
      await txn.rawUpdate(
        'UPDATE $_accountsTable SET balance = COALESCE(balance, 0) + ? WHERE id = ?',
        [commissionAmount, commissionExpenseAccountId],
      );
      await txn.rawUpdate(
        'UPDATE $_accountsTable SET balance = COALESCE(balance, 0) - ? WHERE id = ?',
        [commissionAmount, commissionAccountId],
      );
      
      return journalEntryId;
    }
    
    return null;
  }

  /// Helper: Get connected account ID
  Future<int> _getConnectedAccountId(Transaction txn, int connectType, int defaultId) async {
    final result = await txn.query(
      'account_connects',
      columns: ['c_id'],
      where: 'account_connect_type = ?',
      whereArgs: [connectType],
      limit: 1,
    );
    
    if (result.isNotEmpty && result.first['c_id'] != null) {
      // Get the actual account ID from c_id
      final cId = result.first['c_id'] as int;
      final accountResult = await txn.query(
        _accountsTable,
        columns: ['id'],
        where: 'c_id = ?',
        whereArgs: [cId],
        limit: 1,
      );
      if (accountResult.isNotEmpty) {
        return accountResult.first['id'] as int;
      }
    }
    
    // Try to find by c_id directly as fallback
    final directResult = await txn.query(
      _accountsTable,
      columns: ['id'],
      where: 'c_id = ?',
      whereArgs: [defaultId],
      limit: 1,
    );
    
    if (directResult.isNotEmpty) {
      return directResult.first['id'] as int;
    }
    
    return 1; // Ultimate fallback
  }

  /// Helper: Get customer-specific account ID
  Future<int> _getCustomerAccountId(Transaction txn, int? customerId, int defaultAccountId) async {
    if (customerId == null) return defaultAccountId;
    
    final result = await txn.query(
      _customersTable,
      columns: ['account_id'],
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    
    if (result.isNotEmpty && result.first['account_id'] != null) {
      return result.first['account_id'] as int;
    }
    
    return defaultAccountId;
  }

  /// Helper: Get account metadata
  Future<Map<String, dynamic>> _getAccountMeta(Transaction txn, int accountId) async {
    final result = await txn.query(
      _accountsTable,
      columns: ['code', 'name'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return {
        'code': result.first['code'] ?? '',
        'name': result.first['name'] ?? '',
      };
    }
    
    return {'code': '', 'name': ''};
  }

  /// Helper: Get next journal number
  Future<String> _nextJournalNumber(Transaction txn, String prefix) async {
    final result = await txn.rawQuery(
      "SELECT COALESCE(MAX(CAST(REPLACE(number, '$prefix-', '') AS INTEGER)), 0) + 1 as next FROM journal_entries WHERE number LIKE '$prefix-%'",
    );
    final next = (result.first['next'] as int?) ?? 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  /// Helper: Get commission amount for invoice
  Future<double> _getCommissionAmount(Transaction txn, int invoiceId) async {
    final result = await txn.rawQuery(
      'SELECT COALESCE(SUM(commission_amount), 0) as total FROM sales_commissions WHERE invoice_id = ?',
      [invoiceId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

/// Payment information for multi-payment support
class PaymentInfo {
  final int method; // 0=Cash, 1=Credit, 2=BankTransfer, 3=Check, 4=Card
  final double amount;
  final DateTime? date;
  final int? currencyId;
  final double? exchangeRate;
  final int? bankId;
  final int? bankAccountId;
  final String? checkNumber;
  final DateTime? checkDate;
  final String? cardTransactionRef;
  final String? notes;

  const PaymentInfo({
    required this.method,
    required this.amount,
    this.date,
    this.currencyId,
    this.exchangeRate,
    this.bankId,
    this.bankAccountId,
    this.checkNumber,
    this.checkDate,
    this.cardTransactionRef,
    this.notes,
  });
}

/// Result of sales invoice processing
class SalesInvoiceResult {
  final int invoiceId;
  final String invoiceNumber;
  final List<int> journalEntryIds;
  final double totalAmount;
  final double totalPaid;
  final double remainingBalance;
  final double totalCOGS;
  final double discountApplied;
  final double commissionAmount;

  const SalesInvoiceResult({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.journalEntryIds,
    required this.totalAmount,
    required this.totalPaid,
    required this.remainingBalance,
    required this.totalCOGS,
    required this.discountApplied,
    required this.commissionAmount,
  });
}
