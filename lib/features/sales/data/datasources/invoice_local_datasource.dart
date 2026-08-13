import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:sqflite/sqflite.dart';

import '../models/invoice_line_model.dart';
import '../models/invoice_model.dart';

abstract class InvoiceLocalDataSource {
  Future<List<InvoiceModel>> getInvoices();
  Future<InvoiceModel> getInvoice(int id);
  Future<int> insertInvoice(InvoiceModel invoice);
  Future<void> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(int id);
  Future<List<InvoiceModel>> searchInvoices(String query);

  // Filter operations
  Future<List<InvoiceModel>> getInvoicesByType(int invoiceType);
  Future<List<InvoiceModel>> getInvoicesByCustomer(int customerId);

  // Quotations
  Future<List<InvoiceModel>> getQuotations();
  Future<List<InvoiceModel>> getOpenQuotations();
  Future<int> convertQuotationToInvoice(
    int quotationId,
    InvoiceModel salesInvoice,
  );

  // Returns
  Future<List<InvoiceModel>> getReturnInvoices();
  Future<List<InvoiceModel>> getReturnsByParentInvoice(int parentInvoiceId);
  Future<int> createReturnInvoice(
    InvoiceModel returnInvoice,
    int parentInvoiceId,
  );
}

class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  static const String _invoicesTable = 'invoices';
  static const String _linesTable = 'invoice_lines';
  static const String _journalEntriesTable = 'journal_entries';
  static const String _journalLinesTable = 'journal_entry_lines';
  static const String _accountsTable = 'accounts';
  static const String _accountConnectsTable = 'account_connects';
  static const String _accountLimitsTable = 'account_limits';
  static const String _customersTable = 'customers';
  static const String _currenciesTable = 'currencies';

  final Database database;

  InvoiceLocalDataSourceImpl({required this.database});

  Future<int> _resolveConnectedAccountId(
    Transaction txn,
    int connectType, {
    required String label,
  }) async {
    final connect = await txn.query(
      _accountConnectsTable,
      columns: ['c_id'],
      where: 'account_connect_type = ?',
      whereArgs: [connectType],
      limit: 1,
    );
    int? cId = (connect.isNotEmpty ? connect.first['c_id'] : null) as int?;

    // If not configured in account_connects, fallback to seeded default accounts.
    // This keeps core flows (sales/purchases/convert order->invoice) working out of the box.
    cId ??= switch (connectType) {
      AccountConnectTypes.banks => DefaultAccountIds.bank,
      AccountConnectTypes.cashboxes => DefaultAccountIds.cash,
      AccountConnectTypes.customers => DefaultAccountIds.customers,
      AccountConnectTypes.suppliers => DefaultAccountIds.suppliers,
      AccountConnectTypes.taxes => DefaultAccountIds.tax,
      AccountConnectTypes.inventory => DefaultAccountIds.inventory,
      AccountConnectTypes.merchandise => DefaultAccountIds.inventory,
      AccountConnectTypes.sales => DefaultAccountIds.sales,
      AccountConnectTypes.discountAllowed => DefaultAccountIds.discountAllowed,
      AccountConnectTypes.discountEarned => DefaultAccountIds.discountEarned,
      AccountConnectTypes.purchases => DefaultAccountIds.purchases,
      AccountConnectTypes.salesReturns => DefaultAccountIds.salesReturns,
      AccountConnectTypes.purchaseReturns => DefaultAccountIds.purchaseReturns,
      AccountConnectTypes.costOfGoodsSold => DefaultAccountIds.costOfGoodsSold,
      _ => null,
    };
    if (cId == null) {
      throw LocalStorageException(
        'لا يوجد حساب افتراضي لنوع الربط: $label (type=$connectType)',
      );
    }

    final account = await txn.query(
      _accountsTable,
      columns: ['id'],
      where: 'c_id = ?',
      whereArgs: [cId],
      limit: 1,
    );
    if (account.isEmpty || account.first['id'] == null) {
      // Fallback: try to locate by name (in case seed c_id differs)
      final byName = await txn.query(
        _accountsTable,
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [label],
        limit: 1,
      );
      if (byName.isNotEmpty && byName.first['id'] != null) {
        return byName.first['id'] as int;
      }

      // Create the missing account automatically
      try {
        final newAccountId = await _createMissingAccount(
          txn,
          cId,
          label,
          connectType,
        );
        return newAccountId;
      } catch (e) {
        throw LocalStorageException(
          'فشل في إنشاء الحساب المفقود: $label (c_id=$cId). ${e.toString()}',
        );
      }
    }
    return account.first['id'] as int;
  }

  // Helper method to create missing default account
  Future<int> _createMissingAccount(
    Transaction txn,
    int cId,
    String label,
    int connectType,
  ) async {
    // Determine parent account and code based on account type
    final accountInfo = _getAccountInfo(cId, label, connectType);

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final newAccountId = await txn.insert(_accountsTable, {
      'c_id': cId,
      'name': label,
      'code': accountInfo['code'],
      'parent_id': accountInfo['parent_id'],
      'is_main': 0,
      'is_active': 1,
      'acc_type': accountInfo['acc_type'],
      'creation_time': now,
      'last_modification_time': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    return newAccountId;
  }

  Map<String, dynamic> _getAccountInfo(int cId, String label, int connectType) {
    // Return account info based on account type
    switch (connectType) {
      case AccountConnectTypes.salesReturns:
        return {
          'code': '4150',
          'parent_id': 4000,
          'acc_type': 2,
        }; // Revenue contra
      case AccountConnectTypes.purchaseReturns:
        return {
          'code': '502',
          'parent_id': 3000,
          'acc_type': 2,
        }; // Expense contra
      case AccountConnectTypes.sales:
        return {'code': '4110', 'parent_id': 4000, 'acc_type': 2}; // Revenue
      case AccountConnectTypes.purchases:
        return {'code': '3110', 'parent_id': 3000, 'acc_type': 2}; // Expense
      case AccountConnectTypes.discountAllowed:
        return {'code': '3150', 'parent_id': 3000, 'acc_type': 2}; // Expense
      case AccountConnectTypes.discountEarned:
        return {'code': '4140', 'parent_id': 4000, 'acc_type': 2}; // Revenue
      case AccountConnectTypes.customers:
        return {'code': '1120', 'parent_id': 1000, 'acc_type': 1}; // Asset
      case AccountConnectTypes.suppliers:
        return {'code': '2110', 'parent_id': 2000, 'acc_type': 3}; // Liability
      case AccountConnectTypes.cashboxes:
      case AccountConnectTypes.banks:
        return {'code': '1110', 'parent_id': 1000, 'acc_type': 1}; // Asset
      case AccountConnectTypes.taxes:
        return {'code': '2140', 'parent_id': 2000, 'acc_type': 3}; // Liability
      case AccountConnectTypes.inventory:
        return {'code': '1130', 'parent_id': 1000, 'acc_type': 1}; // Asset
      case AccountConnectTypes.costOfGoodsSold:
        return {'code': '3160', 'parent_id': 3000, 'acc_type': 2}; // Expense
      default:
        return {'code': cId.toString(), 'parent_id': null, 'acc_type': 1};
    }
  }

  Future<int> _resolveCustomerAccountId(
    Transaction txn,
    int customerId, {
    required int fallbackCustomersAccountId,
  }) async {
    final rows = await txn.query(
      _customersTable,
      columns: ['account_id'],
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    final accountId =
        (rows.isNotEmpty ? rows.first['account_id'] : null) as int?;
    return accountId ?? fallbackCustomersAccountId;
  }

  Future<Map<String, dynamic>> _getAccountMeta(
    Transaction txn,
    int accountId,
  ) async {
    final rows = await txn.query(
      _accountsTable,
      columns: ['id', 'code', 'name'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw LocalStorageException('Account not found: id=$accountId');
    }
    return rows.first;
  }

  Future<int?> _resolveCurrencyId(Transaction txn, int? desiredId) async {
    if (desiredId != null) {
      final rows = await txn.query(
        _currenciesTable,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [desiredId],
        limit: 1,
      );
      if (rows.isNotEmpty) return desiredId;
    }
    final any = await txn.query(
      _currenciesTable,
      columns: ['id'],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (any.isEmpty) return null;
    return any.first['id'] as int;
  }

  Future<String> _nextJournalNumber(Transaction txn, String prefix) async {
    final result = await txn.rawQuery(
      'SELECT MAX(id) as max_id FROM $_journalEntriesTable',
    );
    final maxId = result.isNotEmpty ? (result.first['max_id'] as int?) : null;
    final next = (maxId ?? 0) + 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  Future<void> _applyAccountBalanceDelta(
    Transaction txn,
    int accountId,
    double delta,
  ) async {
    final rows = await txn.query(
      _accountsTable,
      columns: ['balance', 'local_balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw LocalStorageException('Account not found: id=$accountId');
    }
    final current = (rows.first['balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = current + delta;
    await txn.update(
      _accountsTable,
      {
        'balance': newBalance,
        'local_balance': newBalance,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> _validateAndUpdateAccountLimits({
    required Transaction txn,
    required int currencyId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final violations = <String>[];

    // Validate first
    for (final l in lines) {
      final accountId = l['account_id'] as int;
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      final limitRows = await txn.query(
        _accountLimitsTable,
        columns: [
          'debit_limit',
          'credit_limit',
          'current_debit',
          'current_credit',
          'is_active',
        ],
        where: 'account_id = ? AND currency_id = ?',
        whereArgs: [accountId, currencyId],
        limit: 1,
      );

      if (limitRows.isEmpty) continue;
      final limit = limitRows.first;
      final isActive = (limit['is_active'] as int?) ?? 1;
      if (isActive != 1) continue;

      final debitLimit = (limit['debit_limit'] as num?)?.toDouble() ?? 0.0;
      final creditLimit = (limit['credit_limit'] as num?)?.toDouble() ?? 0.0;
      final currentDebit = (limit['current_debit'] as num?)?.toDouble() ?? 0.0;
      final currentCredit =
          (limit['current_credit'] as num?)?.toDouble() ?? 0.0;

      if (debitLimit > 0 && currentDebit + debit > debitLimit + 0.000001) {
        violations.add('تجاوز حد المدين للحساب $accountId');
      }
      if (creditLimit > 0 && currentCredit + credit > creditLimit + 0.000001) {
        violations.add('تجاوز حد الدائن للحساب $accountId');
      }
    }

    if (violations.isNotEmpty) {
      throw LocalStorageException(violations.join('\n'));
    }

    // Update after validation
    for (final l in lines) {
      final accountId = l['account_id'] as int;
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      final updated = await txn.rawUpdate(
        '''
UPDATE $_accountLimitsTable
SET current_debit = current_debit + ?,
    current_credit = current_credit + ?,
    last_modification_time = ?
WHERE account_id = ? AND currency_id = ? AND is_active = 1
''',
        [
          debit,
          credit,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          accountId,
          currencyId,
        ],
      );
      // If no row exists, ignore (limits not configured for this account/currency)
      if (updated == 0) {
        // no-op
      }
    }
  }

  Future<void> _postSalesInvoiceToJournal({
    required Transaction txn,
    required int invoiceId,
    required Map<String, dynamic> invoiceData,
  }) async {
    final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
    if (invoiceType != 1) return; // sales only

    final invoiceNumber = (invoiceData['number'] as String?) ?? '';
    final rawDate =
        (invoiceData['date'] as int?) ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final entryDate = rawDate > 1000000000000
        ? (rawDate ~/ 1000)
        : rawDate; // normalize to seconds
    final statement = (invoiceData['statement'] as String?) ?? 'فاتورة مبيعات';
    final currencyId = await _resolveCurrencyId(
      txn,
      invoiceData['currency_id'] as int?,
    );

    final subtotal = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
    final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFee = (invoiceData['other_fee_amt'] as num?)?.toDouble() ?? 0.0;

    final totalAfterDiscount =
        (invoiceData['total_amount_after_discount'] as num?)?.toDouble() ??
        (subtotal - discount);
    final netRevenue =
        (invoiceData['net_revenue_amt'] as num?)?.toDouble() ??
        (totalAfterDiscount + otherFee);
    final total =
        (invoiceData['final_amt'] as num?)?.toDouble() ?? (netRevenue + tax);

    final isCredit = ((invoiceData['invoice_trans_type'] as int?) ?? 0) == 1;

    // Connected accounts (resolve to accounts.id)
    final customersParentId = await _resolveConnectedAccountId(
      txn,
      2,
      label: 'العملاء',
    );
    final customerId = (invoiceData['customer_id'] as int?) ?? 1;
    final customerAccountId = await _resolveCustomerAccountId(
      txn,
      customerId,
      fallbackCustomersAccountId: customersParentId,
    );

    final cashAccountId = await _resolveConnectedAccountId(
      txn,
      1,
      label: 'الصناديق',
    );
    // banks is optional for sales posting unless you support bank payments explicitly
    final salesAccountId = await _resolveConnectedAccountId(
      txn,
      7,
      label: 'المبيعات',
    );
    final taxAccountId = tax > 0
        ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب')
        : 0;
    final discountAllowedId = discount > 0
        ? await _resolveConnectedAccountId(txn, 8, label: 'الخصم المسموح به')
        : 0;

    // ========== Split Payment Support ==========
    // paidAmount = cash portion; remainder = credit portion
    final paidAmount = (invoiceData['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final cashPortion = isCredit
        ? paidAmount
        : total; // If credit, use paidAmount as cash
    final creditPortion = isCredit
        ? (total - paidAmount)
        : 0.0; // If credit, remainder goes to customer account

    // Build lines (balanced)
    final rawLines = <Map<String, dynamic>>[];

    // Debit side - Cash portion (if any)
    if (cashPortion > 0) {
      rawLines.add({
        'account_id': cashAccountId,
        'debit_amount': cashPortion,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'مبيعات نقدية - $invoiceNumber',
      });
    }

    // Debit side - Credit portion (customer receivable)
    if (creditPortion > 0) {
      rawLines.add({
        'account_id': customerAccountId,
        'debit_amount': creditPortion,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'ذمم العملاء - $invoiceNumber',
      });
    }

    // If no cash and no credit (shouldn't happen, but fallback)
    if (cashPortion <= 0 && creditPortion <= 0 && total > 0) {
      rawLines.add({
        'account_id': isCredit ? customerAccountId : cashAccountId,
        'debit_amount': total,
        'credit_amount': 0.0,
        'notes': statement,
        'description': isCredit
            ? 'ذمم العملاء - $invoiceNumber'
            : 'مبيعات نقدية - $invoiceNumber',
      });
    }

    // Credit: Sales revenue
    rawLines.add({
      'account_id': salesAccountId,
      'debit_amount': 0.0,
      'credit_amount': netRevenue,
      'notes': statement,
      'description': 'إيراد مبيعات - $invoiceNumber',
    });

    // Credit: VAT payable
    if (tax > 0) {
      rawLines.add({
        'account_id': taxAccountId,
        'debit_amount': 0.0,
        'credit_amount': tax,
        'notes': statement,
        'description': 'ضريبة مبيعات - $invoiceNumber',
      });
    }

    // Debit: Discount allowed (contra revenue / expense)
    if (discount > 0) {
      rawLines.add({
        'account_id': discountAllowedId,
        'debit_amount': discount,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'خصم مسموح - $invoiceNumber',
      });
    }

    // Other fee account - use default if not specified to ensure accounting integrity
    if (otherFee > 0) {
      // Use provided account or default to "Other Revenue" account (4260)
      final effectiveAccountId =
          invoiceData['other_fee_account_id'] as int? ?? 4260;
      rawLines.add({
        'account_id': effectiveAccountId,
        'debit_amount': 0.0,
        'credit_amount': otherFee,
        'notes': statement,
        'description': 'رسوم أخرى - $invoiceNumber',
      });
    }

    // Post cost of goods sold using the cost captured on each invoice line.
    // If a line has no captured cost, use the warehouse average cost at posting time.
    double totalCogs = 0.0;
    final costLines = await txn.query(
      _linesTable,
      columns: [
        'category_id',
        'stock_id',
        'quantity',
        'base_quantity',
        'cost_price',
        'cost_total',
      ],
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    for (final line in costLines) {
      final productId = line['category_id'] as int?;
      final warehouseId =
          (line['stock_id'] as int?) ?? (invoiceData['stock_id'] as int?);
      if (productId == null) continue;

      final quantity =
          ((line['base_quantity'] as num?) ?? (line['quantity'] as num?) ?? 0)
              .toDouble();
      if (quantity <= 0) continue;

      var lineCost = (line['cost_total'] as num?)?.toDouble() ?? 0.0;
      if (lineCost <= 0) {
        final unitCost = (line['cost_price'] as num?)?.toDouble() ?? 0.0;
        lineCost = quantity * unitCost;
      }
      if (lineCost <= 0 && warehouseId != null) {
        final stockRows = await txn.query(
          'warehouse_stocks',
          columns: ['avg_cost'],
          where: 'product_id = ? AND warehouse_id = ?',
          whereArgs: [productId, warehouseId],
          limit: 1,
        );
        final averageCost = stockRows.isEmpty
            ? 0.0
            : ((stockRows.first['avg_cost'] as num?)?.toDouble() ?? 0.0);
        lineCost = quantity * averageCost;
      }
      if (lineCost <= 0) {
        final productRows = await txn.query(
          'categories',
          columns: ['cost_amount'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        final productCost = productRows.isEmpty
            ? 0.0
            : ((productRows.first['cost_amount'] as num?)?.toDouble() ?? 0.0);
        lineCost = quantity * productCost;
      }
      totalCogs += lineCost;
    }

    if (totalCogs > 0) {
      final cogsAccountId = await _resolveConnectedAccountId(
        txn,
        AccountConnectTypes.costOfGoodsSold,
        label: 'تكلفة البضاعة المباعة',
      );
      final inventoryAccountId = await _resolveConnectedAccountId(
        txn,
        AccountConnectTypes.inventory,
        label: 'المخزون',
      );
      rawLines.add({
        'account_id': cogsAccountId,
        'debit_amount': totalCogs,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'تكلفة البضاعة المباعة - $invoiceNumber',
      });
      rawLines.add({
        'account_id': inventoryAccountId,
        'debit_amount': 0.0,
        'credit_amount': totalCogs,
        'notes': statement,
        'description': 'تخفيض المخزون - $invoiceNumber',
      });
    }
    // Validate balance
    final totalDebit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['debit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final totalCredit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['credit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final diff = (totalDebit - totalCredit);
    if (diff.abs() > 0.01) {
      throw LocalStorageException(
        'قيد غير متوازن لفاتورة $invoiceNumber (فرق: ${diff.toStringAsFixed(2)})',
      );
    }

    // Enforce limits if invoice has currency
    if (currencyId != null) {
      await _validateAndUpdateAccountLimits(
        txn: txn,
        currencyId: currencyId,
        lines: rawLines,
      );
    }

    // Insert journal entry
    final journalNumber = await _nextJournalNumber(txn, 'SI');
    final journalEntryId = await txn.insert(_journalEntriesTable, {
      'number': journalNumber,
      'entry_date': entryDate,
      'description': 'قيد فاتورة مبيعات $invoiceNumber',
      'reference_type': 'sales_invoice',
      'reference_id': invoiceId,
      'reference_number': invoiceNumber,
      'notes': statement,
      'status': 1,
      'is_posted': 1,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }, conflictAlgorithm: ConflictAlgorithm.abort);

    // Insert journal lines + update balances
    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': i + 1,
        'account_id': accountId,
        'account_code': meta['code'],
        'account_name': meta['name'],
        'currency_id': currencyId,
        'debit_amount': debit,
        'credit_amount': credit,
        'description': l['description'],
        'notes': l['notes'],
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Note: Customer balance is already updated by _applyAccountBalanceDelta()
    // when the customer account is updated through journal entry lines
    // Removing duplicate update to prevent quadruple balance issue
  }

  Future<void> _postSalesReturnToJournal({
    required Transaction txn,
    required int returnInvoiceId,
    required Map<String, dynamic> invoiceData,
  }) async {
    final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
    if (invoiceType != 4) return; // sales return only

    final invoiceNumber = (invoiceData['number'] as String?) ?? '';
    final rawDate =
        (invoiceData['date'] as int?) ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final entryDate = rawDate > 1000000000000
        ? (rawDate ~/ 1000)
        : rawDate; // normalize to seconds
    final statement = (invoiceData['statement'] as String?) ?? 'مرتجع مبيعات';
    final currencyId = await _resolveCurrencyId(
      txn,
      invoiceData['currency_id'] as int?,
    );

    final netAmount = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
    final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final total =
        (invoiceData['final_amt'] as num?)?.toDouble() ??
        (netAmount + tax - discount);
    final cogsReversal =
        (invoiceData['cogs_reversal'] as num?)?.toDouble() ?? 0.0;

    final isCredit = ((invoiceData['invoice_trans_type'] as int?) ?? 0) == 1;

    // Connected accounts
    final customersParentId = await _resolveConnectedAccountId(
      txn,
      2,
      label: 'العملاء',
    );
    final customerId = (invoiceData['customer_id'] as int?) ?? 1;
    final customerAccountId = await _resolveCustomerAccountId(
      txn,
      customerId,
      fallbackCustomersAccountId: customersParentId,
    );

    final cashAccountId = await _resolveConnectedAccountId(
      txn,
      1,
      label: 'الصناديق',
    );
    final salesReturnsAccountId = await _resolveConnectedAccountId(
      txn,
      11,
      label: 'مردودات المبيعات',
    );
    final taxAccountId = tax > 0
        ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب')
        : 0;
    final discountAllowedId = discount > 0
        ? await _resolveConnectedAccountId(txn, 8, label: 'الخصم المسموح به')
        : 0;

    // COGS and Inventory accounts for reversal
    int cogsAccountId = 0;
    int inventoryAccountId = 0;
    if (cogsReversal > 0) {
      cogsAccountId = await _resolveConnectedAccountId(
        txn,
        12,
        label: 'تكلفة البضاعة المباعة',
      );
      inventoryAccountId = await _resolveConnectedAccountId(
        txn,
        6,
        label: 'المخزون',
      );
    }

    final rawLines = <Map<String, dynamic>>[];

    // Debit: Sales returns (contra revenue)
    rawLines.add({
      'account_id': salesReturnsAccountId,
      'debit_amount': netAmount,
      'credit_amount': 0.0,
      'notes': statement,
      'description': 'مردودات مبيعات - $invoiceNumber',
    });

    // Debit: VAT reversal
    if (tax > 0) {
      rawLines.add({
        'account_id': taxAccountId,
        'debit_amount': tax,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'عكس ضريبة مبيعات - $invoiceNumber',
      });
    }

    // Credit: customer (credit returns) OR cash (cash returns)
    rawLines.add({
      'account_id': isCredit ? customerAccountId : cashAccountId,
      'debit_amount': 0.0,
      'credit_amount': total,
      'notes': statement,
      'description': isCredit
          ? 'تخفيض ذمة العميل - $invoiceNumber'
          : 'إرجاع نقدي - $invoiceNumber',
    });

    // Credit: reverse discount allowed
    if (discount > 0) {
      rawLines.add({
        'account_id': discountAllowedId,
        'debit_amount': 0.0,
        'credit_amount': discount,
        'notes': statement,
        'description': 'عكس خصم مسموح - $invoiceNumber',
      });
    }

    // ========== COGS Reversal (NEW) ==========
    // When goods are returned, the COGS should be reversed:
    // Debit: Inventory (increase asset - goods returned to stock)
    // Credit: COGS (decrease expense - reduce cost of goods sold)
    if (cogsReversal > 0 && cogsAccountId > 0 && inventoryAccountId > 0) {
      rawLines.add({
        'account_id': inventoryAccountId,
        'debit_amount': cogsReversal,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'إعادة المخزون - مرتجع $invoiceNumber',
      });

      rawLines.add({
        'account_id': cogsAccountId,
        'debit_amount': 0.0,
        'credit_amount': cogsReversal,
        'notes': statement,
        'description': 'عكس تكلفة البضاعة المباعة - $invoiceNumber',
      });
    }
    // ========== End COGS Reversal ==========

    final totalDebit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['debit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final totalCredit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['credit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final diff = (totalDebit - totalCredit);
    if (diff.abs() > 0.01) {
      throw LocalStorageException(
        'قيد غير متوازن لمرتجع $invoiceNumber (فرق: ${diff.toStringAsFixed(2)})',
      );
    }

    if (currencyId != null) {
      await _validateAndUpdateAccountLimits(
        txn: txn,
        currencyId: currencyId,
        lines: rawLines,
      );
    }

    final journalNumber = await _nextJournalNumber(txn, 'SR');
    final journalEntryId = await txn.insert(_journalEntriesTable, {
      'number': journalNumber,
      'entry_date': entryDate,
      'description': 'قيد مرتجع مبيعات $invoiceNumber',
      'reference_type': 'sales_return',
      'reference_id': returnInvoiceId,
      'reference_number': invoiceNumber,
      'notes': statement,
      'status': 1,
      'is_posted': 1,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }, conflictAlgorithm: ConflictAlgorithm.abort);

    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': i + 1,
        'account_id': accountId,
        'account_code': meta['code'],
        'account_name': meta['name'],
        'currency_id': currencyId,
        'debit_amount': debit,
        'credit_amount': credit,
        'description': l['description'],
        'notes': l['notes'],
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Note: Customer balance is already updated by _applyAccountBalanceDelta()
    // when the customer account is updated through journal entry lines
    // Removing duplicate update to prevent quadruple balance issue
  }

  Future<void> _postPurchaseInvoiceToJournal({
    required Transaction txn,
    required int invoiceId,
    required Map<String, dynamic> invoiceData,
  }) async {
    final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
    if (invoiceType != 2) return; // purchase invoice only

    final invoiceNumber = (invoiceData['number'] as String?) ?? '';
    final rawDate =
        (invoiceData['date'] as int?) ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final entryDate = rawDate > 1000000000000
        ? (rawDate ~/ 1000)
        : rawDate; // normalize to seconds
    final statement = (invoiceData['statement'] as String?) ?? 'فاتورة مشتريات';
    final currencyId = await _resolveCurrencyId(
      txn,
      invoiceData['currency_id'] as int?,
    );

    final subtotal =
        (invoiceData['amount'] as num?)?.toDouble() ?? 0.0; // قبل الخصم
    final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFee = (invoiceData['other_fee_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFeeAccountId = invoiceData['other_fee_account_id'] as int?;

    // total (after discount + tax + fees)
    final total =
        (invoiceData['final_amt'] as num?)?.toDouble() ??
        ((subtotal - discount) + otherFee + tax);

    final isCredit = ((invoiceData['invoice_trans_type'] as int?) ?? 0) == 1;

    // Connected accounts (resolve to accounts.id)
    final suppliersParentId = await _resolveConnectedAccountId(
      txn,
      3,
      label: 'الموردون',
    );
    final supplierId = (invoiceData['customer_id'] as int?) ?? 1;
    final supplierAccountId = await _resolveCustomerAccountId(
      txn,
      supplierId,
      fallbackCustomersAccountId: suppliersParentId,
    );

    final cashAccountId = await _resolveConnectedAccountId(
      txn,
      1,
      label: 'الصناديق',
    );
    final bankAccountId = await _resolveConnectedAccountId(
      txn,
      0,
      label: 'البنوك',
    );
    final purchasesAccountId = await _resolveConnectedAccountId(
      txn,
      10,
      label: 'المشتريات',
    );
    final taxAccountId = tax > 0
        ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب')
        : 0;
    final discountEarnedId = discount > 0
        ? await _resolveConnectedAccountId(txn, 9, label: 'الخصم المكتسب')
        : 0;

    // Pick cash/bank account: default to cash unless statement hints bank
    final paymentAccountId =
        (invoiceData['statement'] as String?)?.contains('بنك') == true
        ? bankAccountId
        : cashAccountId;

    final rawLines = <Map<String, dynamic>>[];

    // Debit purchases (gross) - if otherFeeAccountId is set, keep fee separate
    final purchasesDebit = subtotal;
    rawLines.add({
      'account_id': purchasesAccountId,
      'debit_amount': purchasesDebit,
      'credit_amount': 0.0,
      'notes': statement,
      'description': 'مشتريات - $invoiceNumber',
    });

    // Debit other fees if configured
    if (otherFee > 0) {
      if (otherFeeAccountId != null) {
        rawLines.add({
          'account_id': otherFeeAccountId,
          'debit_amount': otherFee,
          'credit_amount': 0.0,
          'notes': statement,
          'description': 'رسوم/مصروفات شراء - $invoiceNumber',
        });
      } else {
        // otherwise treat as part of purchases cost (add debit)
        rawLines.add({
          'account_id': purchasesAccountId,
          'debit_amount': otherFee,
          'credit_amount': 0.0,
          'notes': statement,
          'description': 'تكاليف إضافية على المشتريات - $invoiceNumber',
        });
      }
    }

    // Debit tax (input VAT simplified)
    if (tax > 0) {
      rawLines.add({
        'account_id': taxAccountId,
        'debit_amount': tax,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'ضريبة مشتريات - $invoiceNumber',
      });
    }

    // Credit discount earned (contra cost / income)
    if (discount > 0) {
      rawLines.add({
        'account_id': discountEarnedId,
        'debit_amount': 0.0,
        'credit_amount': discount,
        'notes': statement,
        'description': 'خصم مكتسب - $invoiceNumber',
      });
    }

    // Credit payable/cash (net amount after discount)
    // total already = (subtotal - discount) + otherFee + tax
    // So we need to credit: total (which is the net payable)
    rawLines.add({
      'account_id': isCredit ? supplierAccountId : paymentAccountId,
      'debit_amount': 0.0,
      'credit_amount': total,
      'notes': statement,
      'description': isCredit
          ? 'ذمم الموردين - $invoiceNumber'
          : 'دفع مشتريات - $invoiceNumber',
    });

    // Validate balanced
    // Total Debit = subtotal + otherFee + tax
    // Total Credit = discount + total = discount + (subtotal - discount + otherFee + tax)
    //              = subtotal + otherFee + tax
    // Should be balanced!
    final totalDebit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['debit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final totalCredit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['credit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final diff = (totalDebit - totalCredit);
    if (diff.abs() > 0.01) {
      // Add debugging info to the error message
      final debugInfo =
          'المدين: ${totalDebit.toStringAsFixed(2)}, الدائن: ${totalCredit.toStringAsFixed(2)}, '
          'المجموع الفرعي: ${subtotal.toStringAsFixed(2)}, الخصم: ${discount.toStringAsFixed(2)}, '
          'الضريبة: ${tax.toStringAsFixed(2)}, رسوم: ${otherFee.toStringAsFixed(2)}, '
          'الإجمالي: ${total.toStringAsFixed(2)}';
      throw LocalStorageException(
        'قيد غير متوازن لمشتريات $invoiceNumber (فرق: ${diff.toStringAsFixed(2)}). $debugInfo',
      );
    }

    if (currencyId != null) {
      await _validateAndUpdateAccountLimits(
        txn: txn,
        currencyId: currencyId,
        lines: rawLines,
      );
    }

    final journalNumber = await _nextJournalNumber(txn, 'PI');
    final journalEntryId = await txn.insert(_journalEntriesTable, {
      'number': journalNumber,
      'entry_date': entryDate,
      'description': 'قيد مشتريات $invoiceNumber',
      'reference_type': 'purchase_invoice',
      'reference_id': invoiceId,
      'reference_number': invoiceNumber,
      'notes': statement,
      'status': 1,
      'is_posted': 1,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }, conflictAlgorithm: ConflictAlgorithm.abort);

    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': i + 1,
        'account_id': accountId,
        'account_code': meta['code'],
        'account_name': meta['name'],
        'currency_id': currencyId,
        'debit_amount': debit,
        'credit_amount': credit,
        'description': l['description'],
        'notes': l['notes'],
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Note: Supplier balance is already updated by _applyAccountBalanceDelta()
    // when the supplier account is updated through journal entry lines
    // Removing duplicate update to prevent triple balance issue
  }

  Future<void> _postPurchaseReturnToJournal({
    required Transaction txn,
    required int returnInvoiceId,
    required Map<String, dynamic> invoiceData,
  }) async {
    final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
    if (invoiceType != 5) return; // purchase return only

    final invoiceNumber = (invoiceData['number'] as String?) ?? '';
    final rawDate =
        (invoiceData['date'] as int?) ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final entryDate = rawDate > 1000000000000
        ? (rawDate ~/ 1000)
        : rawDate; // normalize to seconds
    final statement = (invoiceData['statement'] as String?) ?? 'مردود مشتريات';
    final currencyId = await _resolveCurrencyId(
      txn,
      invoiceData['currency_id'] as int?,
    );

    final subtotal = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
    final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFee = (invoiceData['other_fee_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFeeAccountId = invoiceData['other_fee_account_id'] as int?;

    final total =
        (invoiceData['final_amt'] as num?)?.toDouble() ??
        ((subtotal - discount) + otherFee + tax);

    final isCredit = ((invoiceData['invoice_trans_type'] as int?) ?? 0) == 1;

    final suppliersParentId = await _resolveConnectedAccountId(
      txn,
      3,
      label: 'الموردون',
    );
    final supplierId = (invoiceData['customer_id'] as int?) ?? 1;
    final supplierAccountId = await _resolveCustomerAccountId(
      txn,
      supplierId,
      fallbackCustomersAccountId: suppliersParentId,
    );

    final cashAccountId = await _resolveConnectedAccountId(
      txn,
      1,
      label: 'الصناديق',
    );
    final bankAccountId = await _resolveConnectedAccountId(
      txn,
      0,
      label: 'البنوك',
    );
    final purchaseReturnsAccountId = await _resolveConnectedAccountId(
      txn,
      12,
      label: 'مردودات المشتريات',
    );
    final taxAccountId = tax > 0
        ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب')
        : 0;
    final discountEarnedId = discount > 0
        ? await _resolveConnectedAccountId(txn, 9, label: 'الخصم المكتسب')
        : 0;

    final paymentAccountId =
        (invoiceData['statement'] as String?)?.contains('بنك') == true
        ? bankAccountId
        : cashAccountId;

    final rawLines = <Map<String, dynamic>>[];

    // Debit: supplier (reduce payable) or cash (refund received)
    rawLines.add({
      'account_id': isCredit ? supplierAccountId : paymentAccountId,
      'debit_amount': total,
      'credit_amount': 0.0,
      'notes': statement,
      'description': isCredit
          ? 'تخفيض ذمة المورد - $invoiceNumber'
          : 'استلام مردود مشتريات - $invoiceNumber',
    });

    // Debit: reverse discount earned
    if (discount > 0) {
      rawLines.add({
        'account_id': discountEarnedId,
        'debit_amount': discount,
        'credit_amount': 0.0,
        'notes': statement,
        'description': 'عكس خصم مكتسب - $invoiceNumber',
      });
    }

    // Credit: purchase returns (gross)
    rawLines.add({
      'account_id': purchaseReturnsAccountId,
      'debit_amount': 0.0,
      'credit_amount': subtotal,
      'notes': statement,
      'description': 'مردودات مشتريات - $invoiceNumber',
    });

    // Credit: other fee reversal
    if (otherFee > 0) {
      if (otherFeeAccountId != null) {
        rawLines.add({
          'account_id': otherFeeAccountId,
          'debit_amount': 0.0,
          'credit_amount': otherFee,
          'notes': statement,
          'description': 'عكس رسوم/مصروفات شراء - $invoiceNumber',
        });
      } else {
        rawLines.add({
          'account_id': purchaseReturnsAccountId,
          'debit_amount': 0.0,
          'credit_amount': otherFee,
          'notes': statement,
          'description': 'عكس تكاليف إضافية - $invoiceNumber',
        });
      }
    }

    // Credit: reverse input tax
    if (tax > 0) {
      rawLines.add({
        'account_id': taxAccountId,
        'debit_amount': 0.0,
        'credit_amount': tax,
        'notes': statement,
        'description': 'عكس ضريبة مشتريات - $invoiceNumber',
      });
    }

    final totalDebit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['debit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final totalCredit = rawLines.fold<double>(
      0.0,
      (s, l) => s + ((l['credit_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final diff = (totalDebit - totalCredit);
    if (diff.abs() > 0.01) {
      throw LocalStorageException(
        'قيد غير متوازن لمردود مشتريات $invoiceNumber (فرق: ${diff.toStringAsFixed(2)})',
      );
    }

    if (currencyId != null) {
      await _validateAndUpdateAccountLimits(
        txn: txn,
        currencyId: currencyId,
        lines: rawLines,
      );
    }

    final journalNumber = await _nextJournalNumber(txn, 'PR');
    final journalEntryId = await txn.insert(_journalEntriesTable, {
      'number': journalNumber,
      'entry_date': entryDate,
      'description': 'قيد مردود مشتريات $invoiceNumber',
      'reference_type': 'purchase_return',
      'reference_id': returnInvoiceId,
      'reference_number': invoiceNumber,
      'notes': statement,
      'status': 1,
      'is_posted': 1,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': 0.0,
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }, conflictAlgorithm: ConflictAlgorithm.abort);

    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': i + 1,
        'account_id': accountId,
        'account_code': meta['code'],
        'account_name': meta['name'],
        'currency_id': currencyId,
        'debit_amount': debit,
        'credit_amount': credit,
        'description': l['description'],
        'notes': l['notes'],
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Note: Supplier balance is already updated by _applyAccountBalanceDelta()
    // when the supplier account is updated through journal entry lines
    // Removing duplicate update to prevent triple balance issue
  }

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final heads = await database.query(
        _invoicesTable,
        orderBy: 'date DESC, id DESC',
      );

      final List<InvoiceModel> results = [];

      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }

      return results;
    } catch (e) {
      throw LocalStorageException('Failed to load invoices: ${e.toString()}');
    }
  }

  @override
  Future<InvoiceModel> getInvoice(int id) async {
    try {
      final rows = await database.query(
        _invoicesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw LocalStorageException('Invoice with id $id not found');
      }
      final lines = await database.query(
        _linesTable,
        where: 'invoice_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );
      final lineModels = lines
          .map((e) => InvoiceLineModel.fromJson(e))
          .toList();
      return InvoiceModel.fromJson(rows.first, lines: lineModels);
    } catch (e) {
      throw LocalStorageException('Failed to get invoice: ${e.toString()}');
    }
  }

  @override
  Future<int> insertInvoice(InvoiceModel invoice) async {
    try {
      return await database.transaction((txn) async {
        // Prepare invoice data with creation_time if not set
        final invoiceData = invoice.toJson();
        invoiceData['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
        invoiceData['last_modification_time'] ??=
            DateTime.now().millisecondsSinceEpoch;

        // ========== Ensure FK targets exist (defensive seeding) ==========
        // 1) Classifications (needed for customers)
        final classificationsCount =
            Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(1) FROM classifications'),
            ) ??
            0;
        if (classificationsCount == 0) {
          final now = DateTime.now().millisecondsSinceEpoch;
          await txn.insert('classifications', {
            'id': 1,
            'name': 'عملاء عاديين',
            'singler_name': 'عميل',
            'order': 1,
            'type': 1,
            'creation_time': now,
            'last_modification_time': now,
          });
        }

        // 2) Customers (seed id 1 cash, id 2 credit if missing)
        Future<void> ensureCustomer(int id, String name, int type) async {
          final rows = await txn.query(
            'customers',
            where: 'id = ?',
            whereArgs: [id],
            limit: 1,
          );
          if (rows.isEmpty) {
            final now =
                DateTime.now().millisecondsSinceEpoch ~/
                1000; // seconds to match CHECK
            await txn.insert('customers', {
              'id': id,
              'name': name,
              'type': type,
              'classification': 1,
              'classification_id': 1,
              'is_active': 1,
              'credit_limit': 0.0,
              'current_balance': 0.0,
              'creation_time': now,
              'last_modification_time': now,
            });
          }
        }

        await ensureCustomer(1, 'عميل نقدي', 1);
        await ensureCustomer(2, 'عميل آجل', 2);

        // 3) Stocks (seed main stock id 1 if missing)
        final stockId = invoiceData['stock_id'] as int?;
        Future<int> ensureStock(int? desiredId) async {
          if (desiredId != null) {
            final rows = await txn.query(
              'stocks',
              where: 'id = ?',
              whereArgs: [desiredId],
              limit: 1,
            );
            if (rows.isNotEmpty) return desiredId;
          }
          // Try any existing stock
          final anyStock = await txn.query('stocks', limit: 1);
          if (anyStock.isNotEmpty) return anyStock.first['id'] as int;
          // Seed default main stock
          final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await txn.insert('stocks', {
            'id': 1,
            'name': 'المخزن الرئيسي',
            'address': 'المقر الرئيسي',
            'is_main_stock': 1,
            'is_active': 1,
            'creation_time': nowSec,
            'last_modification_time': nowSec,
          });
          return 1;
        }

        invoiceData['stock_id'] = await ensureStock(stockId);

        // Ensure customer id points to an existing row (fallback to 1)
        int desiredCustomerId = (invoiceData['customer_id'] as int?) ?? 1;
        final cust = await txn.query(
          'customers',
          where: 'id = ?',
          whereArgs: [desiredCustomerId],
          limit: 1,
        );
        if (cust.isEmpty) {
          desiredCustomerId = 1;
        }
        invoiceData['customer_id'] = desiredCustomerId;

        // Remove ID if present to allow auto-generation (important for copied/converted invoices)
        invoiceData.remove('id');

        final invoiceId = await txn.insert(
          _invoicesTable,
          invoiceData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        for (final line in invoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);

          // Prepare line data with creation_time if not set
          final lineData = lineModel.toJson(invoiceId: invoiceId);
          lineData['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
          lineData['last_modification_time'] ??=
              DateTime.now().millisecondsSinceEpoch;

          // ========= Enforce/derive valid foreign keys for invoice_lines =========
          // currency_id -> nullable: if provided but not found, set to null
          final int? currencyId = lineData['currency_id'] as int?;
          if (currencyId != null) {
            final cur = await txn.query(
              'currencies',
              where: 'id = ?',
              whereArgs: [currencyId],
              limit: 1,
            );
            if (cur.isEmpty) {
              lineData['currency_id'] = null;
            }
          }

          // category, group, unit, sub-unit
          final int? categoryId = lineData['category_id'] as int?;
          int? groupId = lineData['group_id'] as int?;
          int? unitId = lineData['unit_id'] as int?;
          int? subUnitId = lineData['category_sub_unit_id'] as int?;

          // Validate provided group/unit ids
          if (groupId != null) {
            final g = await txn.query(
              'categories_groups',
              where: 'id = ?',
              whereArgs: [groupId],
              limit: 1,
            );
            if (g.isEmpty) groupId = null;
          }
          if (unitId != null) {
            final u = await txn.query(
              'categories_units',
              where: 'id = ?',
              whereArgs: [unitId],
              limit: 1,
            );
            if (u.isEmpty) unitId = null;
          }

          // Try derive group/unit from category if missing
          int? validCategoryId = categoryId;
          if (categoryId != null) {
            final cat = await txn.query(
              'categories',
              where: 'id = ?',
              whereArgs: [categoryId],
              limit: 1,
            );
            if (cat.isNotEmpty) {
              if (groupId == null) {
                final cg = cat.first['group_id'] as int?;
                if (cg != null) {
                  final g2 = await txn.query(
                    'categories_groups',
                    where: 'id = ?',
                    whereArgs: [cg],
                    limit: 1,
                  );
                  if (g2.isNotEmpty) {
                    groupId = cg;
                  }
                }
              }
              if (unitId == null) {
                final cu = cat.first['unit_id'] as int?;
                if (cu != null) {
                  final u2 = await txn.query(
                    'categories_units',
                    where: 'id = ?',
                    whereArgs: [cu],
                    limit: 1,
                  );
                  if (u2.isNotEmpty) {
                    unitId = cu;
                  }
                }
              }
            } else {
              // Provided category_id doesn't exist; null it to avoid FK violation (it's nullable in schema)
              validCategoryId = null;
            }
          }

          // If still no valid group_id, ensure or create a default
          if (groupId == null) {
            final anyGroup = await txn.query('categories_groups', limit: 1);
            if (anyGroup.isEmpty) {
              final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              await txn.insert('categories_groups', {
                'id': 1,
                'name': 'افتراضي',
                'is_active': 1,
                'creation_time': nowSec,
                'last_modification_time': nowSec,
              });
              groupId = 1;
            } else {
              groupId = anyGroup.first['id'] as int;
            }
          }

          // If still no valid unit_id, ensure or create a default
          if (unitId == null) {
            // Try derive from category if exists
            if (categoryId != null) {
              final cat = await txn.query(
                'categories',
                where: 'id = ?',
                whereArgs: [categoryId],
                limit: 1,
              );
              if (cat.isNotEmpty) {
                final cu = cat.first['unit_id'] as int?;
                if (cu != null) {
                  final u2 = await txn.query(
                    'categories_units',
                    where: 'id = ?',
                    whereArgs: [cu],
                    limit: 1,
                  );
                  if (u2.isNotEmpty) {
                    unitId = cu;
                  }
                }
              }
            }
            if (unitId == null) {
              final anyUnit = await txn.query('categories_units', limit: 1);
              if (anyUnit.isEmpty) {
                final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                await txn.insert('categories_units', {
                  'id': 1,
                  'name': 'وحدة',
                  'short': 'قطعة',
                  'is_active': 1,
                  'creation_time': nowSec,
                  'last_modification_time': nowSec,
                });
                unitId = 1;
              } else {
                unitId = anyUnit.first['id'] as int;
              }
            }
          }

          // Ensure category_sub_unit exists for this category (or create a default even without category)
          if (subUnitId != null) {
            final s = await txn.query(
              'category_sub_units',
              where: 'id = ?',
              whereArgs: [subUnitId],
              limit: 1,
            );
            if (s.isEmpty) subUnitId = null;
          }
          if (subUnitId == null) {
            if (validCategoryId != null) {
              final main = await txn.query(
                'category_sub_units',
                where: 'category_id = ? AND is_main_unit = 1',
                whereArgs: [validCategoryId],
                limit: 1,
              );
              if (main.isNotEmpty) {
                subUnitId = main.first['id'] as int;
              } else {
                final any = await txn.query(
                  'category_sub_units',
                  where: 'category_id = ?',
                  whereArgs: [validCategoryId],
                  limit: 1,
                );
                if (any.isNotEmpty) {
                  subUnitId = any.first['id'] as int;
                }
              }
            }
            if (subUnitId == null) {
              // No sub-unit found with or without category; create a default one (category_id can be NULL)
              final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final insertedId = await txn.insert('category_sub_units', {
                'packaging': 1,
                'is_active': 1,
                'is_main_unit': 1,
                'category_id': validCategoryId, // may be null
                'unit_id': unitId,
                'conversion_rate': 1.0,
                'creation_time': nowSec,
                'last_modification_time': nowSec,
              });
              subUnitId = insertedId;
            }
          }

          // Ensure valid stock_id for the line (fallback to header's stock_id)
          int? lineStockId = lineData['stock_id'] as int?;
          if (lineStockId != null) {
            final st = await txn.query(
              'stocks',
              where: 'id = ?',
              whereArgs: [lineStockId],
              limit: 1,
            );
            if (st.isEmpty) lineStockId = null;
          }
          lineStockId ??= invoiceData['stock_id'] as int?;
          lineStockId ??= await ensureStock(null);

          // Ensure valid customer_id for the line (fallback to header's customer_id)
          int? lineCustomerId = lineData['customer_id'] as int?;
          if (lineCustomerId != null) {
            final c = await txn.query(
              'customers',
              where: 'id = ?',
              whereArgs: [lineCustomerId],
              limit: 1,
            );
            if (c.isEmpty) lineCustomerId = null;
          }
          lineCustomerId ??= invoiceData['customer_id'] as int?;
          lineCustomerId ??= 1;

          // Write back ensured values
          lineData['category_id'] = validCategoryId; // null if invalid
          lineData['group_id'] = groupId;
          lineData['unit_id'] = unitId;
          lineData['category_sub_unit_id'] = subUnitId;
          lineData['stock_id'] = lineStockId;
          lineData['customer_id'] = lineCustomerId;

          // Remove ID if present to allow auto-generation (important for copied/converted invoice lines)
          lineData.remove('id');

          await txn.insert(
            _linesTable,
            lineData,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        // Auto-post accounting entries for sales invoices (not quotations)
        await _postSalesInvoiceToJournal(
          txn: txn,
          invoiceId: invoiceId,
          invoiceData: {...invoiceData, 'id': invoiceId},
        );

        // Auto-post accounting entries for purchases and purchase returns
        await _postPurchaseInvoiceToJournal(
          txn: txn,
          invoiceId: invoiceId,
          invoiceData: {...invoiceData, 'id': invoiceId},
        );
        await _postPurchaseReturnToJournal(
          txn: txn,
          returnInvoiceId: invoiceId,
          invoiceData: {...invoiceData, 'id': invoiceId},
        );

        // ========== UPDATE INVENTORY FOR SALES - Reduce stock ==========
        final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
        if (invoiceType == 1) {
          // Sales invoice only
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final headerStockId = invoiceData['stock_id'] as int?;
          final invoiceNumber = (invoiceData['number'] as String?) ?? '';

          for (final line in invoice.lines) {
            final lineModel = line is InvoiceLineModel
                ? line
                : InvoiceLineModel.fromEntity(line);
            final productId = lineModel.categoryId;
            final warehouseId = lineModel.stockId ?? headerStockId ?? 1;
            final qty = lineModel.quantity;

            if (productId != null && qty > 0) {
              // Get current stock
              final stockResult = await txn.query(
                'warehouse_stocks',
                where: 'product_id = ? AND warehouse_id = ?',
                whereArgs: [productId, warehouseId],
                limit: 1,
              );

              double currentQty = 0.0;
              double avgCost = 0.0;

              if (stockResult.isNotEmpty) {
                currentQty =
                    (stockResult.first['quantity'] as num?)?.toDouble() ?? 0.0;
                avgCost =
                    (stockResult.first['avg_cost'] as num?)?.toDouble() ?? 0.0;
              }

              final newQty = currentQty - qty;

              // Update or insert warehouse stock
              if (stockResult.isNotEmpty) {
                await txn.update(
                  'warehouse_stocks',
                  {'quantity': newQty, 'last_modification_time': now},
                  where: 'product_id = ? AND warehouse_id = ?',
                  whereArgs: [productId, warehouseId],
                );
              } else {
                // Create new record with negative quantity (oversold)
                await txn.insert('warehouse_stocks', {
                  'product_id': productId,
                  'warehouse_id': warehouseId,
                  'quantity': newQty,
                  'avg_cost': 0.0,
                  'last_cost': 0.0,
                  'creation_time': now,
                  'last_modification_time': now,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }

              // Record stock movement
              try {
                await txn.insert('stock_movements', {
                  'product_id': productId,
                  'warehouse_id': warehouseId,
                  'movement_type': 'sale',
                  'quantity': -qty, // Negative for outgoing
                  'unit_cost': avgCost,
                  'total_cost': qty * avgCost,
                  'balance_after': newQty,
                  'reference_type': 'sales_invoice',
                  'reference_id': invoiceId,
                  'reference_number': invoiceNumber,
                  'creation_time': now,
                });
              } catch (_) {
                // Ignore if stock_movements table doesn't exist
              }
            }
          }
        }
        // ========== END INVENTORY UPDATE ==========

        return invoiceId;
      });
    } catch (e) {
      if (e is LocalStorageException) {
        // Preserve the real message (avoid "Instance of LocalStorageException")
        throw LocalStorageException(e.message);
      }
      throw LocalStorageException('Failed to insert invoice: ${e.toString()}');
    }
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) {
      throw LocalStorageException('Invoice id is required for update');
    }
    try {
      await database.transaction((txn) async {
        // ========== Quotation Protection Check ==========
        final existing = await txn.query(
          _invoicesTable,
          columns: [
            'invoice_type',
            'is_locked',
            'next_invoice_id',
            'approval_status',
          ],
          where: 'id = ?',
          whereArgs: [invoice.id],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final data = existing.first;
          final invoiceType = data['invoice_type'] as int?;

          // Check if it's a quotation (type = 3)
          if (invoiceType == 3) {
            // Check if locked
            if ((data['is_locked'] as int?) == 1) {
              throw LocalStorageException('عرض السعر مقفل ولا يمكن تعديله');
            }

            // Check if already converted
            final nextInvoiceId = data['next_invoice_id'] as int?;
            if (nextInvoiceId != null && nextInvoiceId > 0) {
              throw LocalStorageException(
                'عرض السعر محول لفاتورة ولا يمكن تعديله',
              );
            }

            // Check if approved
            final approvalStatus = (data['approval_status'] as int?) ?? 0;
            if (approvalStatus == 2) {
              // 2 = approved
              throw LocalStorageException('عرض السعر معتمد ولا يمكن تعديله');
            }
          }
        }
        // ========== End Protection Check ==========

        final count = await txn.update(
          _invoicesTable,
          invoice.toJson(),
          where: 'id = ?',
          whereArgs: [invoice.id],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        if (count == 0) {
          throw LocalStorageException(
            'Invoice with id ${invoice.id} was not found',
          );
        }
        await txn.delete(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        for (final line in invoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          final lineData = lineModel.toJson(invoiceId: invoice.id!);
          lineData.remove('id'); // Remove ID to get new auto-generated ID

          await txn.insert(
            _linesTable,
            lineData,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });
    } catch (e) {
      if (e is LocalStorageException) {
        throw LocalStorageException(e.message);
      }
      throw LocalStorageException('Failed to update invoice: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteInvoice(int id) async {
    try {
      // ========== Quotation Protection Check ==========
      final existing = await database.query(
        _invoicesTable,
        columns: [
          'invoice_type',
          'is_locked',
          'next_invoice_id',
          'approval_status',
          'number',
        ],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final data = existing.first;
        final invoiceType = data['invoice_type'] as int?;
        final number = data['number'] as String? ?? '';

        // Check if it's a quotation (type = 3)
        if (invoiceType == 3) {
          // Check if already converted - CANNOT delete
          final nextInvoiceId = data['next_invoice_id'] as int?;
          if (nextInvoiceId != null && nextInvoiceId > 0) {
            throw LocalStorageException(
              'لا يمكن حذف عرض السعر $number لأنه محول لفاتورة',
            );
          }

          // Check if approved - CANNOT delete
          final approvalStatus = (data['approval_status'] as int?) ?? 0;
          if (approvalStatus == 2) {
            // 2 = approved
            throw LocalStorageException(
              'لا يمكن حذف عرض السعر $number لأنه معتمد',
            );
          }

          // Check if locked
          if ((data['is_locked'] as int?) == 1) {
            throw LocalStorageException('عرض السعر $number مقفل ولا يمكن حذفه');
          }
        }

        // For sales invoices (type = 1), check if it has journal entries
        if (invoiceType == 1) {
          final journalCheck = await database.rawQuery(
            "SELECT COUNT(*) as count FROM journal_entries WHERE reference_type = 'sales_invoice' AND reference_id = ?",
            [id],
          );
          final hasJournal = ((journalCheck.first['count'] as int?) ?? 0) > 0;
          if (hasJournal) {
            throw LocalStorageException(
              'لا يمكن حذف الفاتورة $number لأنها مسجلة محاسبياً. يجب إلغاؤها بدلاً من حذفها.',
            );
          }
        }
      }
      // ========== End Protection Check ==========

      final deleted = await database.delete(
        _invoicesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (deleted == 0) {
        throw LocalStorageException('Invoice with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) {
        throw LocalStorageException(e.message);
      }
      throw LocalStorageException('Failed to delete invoice: ${e.toString()}');
    }
  }

  @override
  Future<List<InvoiceModel>> searchInvoices(String query) async {
    try {
      final rows = await database.query(
        _invoicesTable,
        where: 'number LIKE ? OR u_no LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'date DESC, id DESC',
      );
      final List<InvoiceModel> results = [];
      for (final h in rows) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException('Failed to search invoices: ${e.toString()}');
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByType(int invoiceType) async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where: 'invoice_type = ?',
        whereArgs: [invoiceType],
        orderBy: 'date DESC, id DESC',
      );

      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get invoices by type: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByCustomer(int customerId) async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'date DESC, id DESC',
      );

      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get invoices by customer: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getQuotations() async {
    return await getInvoicesByType(3); // InvoiceType.quotation = 3
  }

  @override
  Future<List<InvoiceModel>> getOpenQuotations() async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where:
            'invoice_type = ? AND (next_invoice_id IS NULL OR next_invoice_id = 0)',
        whereArgs: [3], // Quotations that haven't been converted
        orderBy: 'date DESC, id DESC',
      );

      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get open quotations: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> convertQuotationToInvoice(
    int quotationId,
    InvoiceModel salesInvoice,
  ) async {
    try {
      return await database.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // ========== Protection Check Before Conversion ==========
        final existing = await txn.query(
          _invoicesTable,
          columns: [
            'invoice_type',
            'next_invoice_id',
            'is_locked',
            'number',
            'valid_until',
          ],
          where: 'id = ?',
          whereArgs: [quotationId],
          limit: 1,
        );

        if (existing.isEmpty) {
          throw LocalStorageException('عرض السعر غير موجود');
        }

        final quotationData = existing.first;

        // Check if it's a quotation
        if ((quotationData['invoice_type'] as int?) != 3) {
          throw LocalStorageException('هذا المستند ليس عرض سعر');
        }

        // Check if already converted
        final existingNextId = quotationData['next_invoice_id'] as int?;
        if (existingNextId != null && existingNextId > 0) {
          throw LocalStorageException(
            'عرض السعر ${quotationData['number']} محول مسبقاً',
          );
        }

        // Check expiry (warning only - allow conversion but log it)
        final validUntil = quotationData['valid_until'] as int?;
        String? expiryWarning;
        if (validUntil != null && now > validUntil) {
          expiryWarning = 'تحذير: عرض السعر منتهي الصلاحية';
        }
        // ========== End Protection Check ==========

        // 1. Insert the new sales invoice (remove ID to get new auto-generated ID)
        final invoiceData = salesInvoice.toJson();
        invoiceData.remove('id'); // Remove ID to avoid UNIQUE constraint error

        final invoiceId = await txn.insert(
          _invoicesTable,
          invoiceData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // 2. Insert invoice lines (remove IDs to get new auto-generated IDs)
        for (final line in salesInvoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          final lineData = lineModel.toJson(invoiceId: invoiceId);
          lineData.remove('id'); // Remove ID to avoid UNIQUE constraint error

          await txn.insert(
            _linesTable,
            lineData,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        // 3. Update the quotation to mark it as converted AND lock it
        await txn.update(
          _invoicesTable,
          {
            'next_invoice_id': invoiceId,
            'next_invoice_type': 1, // Sales invoice
            'next_invoice_number': salesInvoice.number,
            'payment_status': 4, // Converted status
            'approval_status': 5, // 5 = converted
            'is_locked': 1, // Lock the quotation to prevent modifications
            'locked_at': now,
            'locked_reason':
                'تم التحويل لفاتورة مبيعات رقم ${salesInvoice.number}${expiryWarning != null ? ' ($expiryWarning)' : ''}',
            'last_modification_time': now,
          },
          where: 'id = ?',
          whereArgs: [quotationId],
        );

        // 4. Log the conversion action
        try {
          await txn.insert('audit_logs', {
            'entity_type': 'quotation',
            'entity_id': quotationId,
            'action': 'CONVERT',
            'user_id': 1, // TODO: Get actual user ID
            'description':
                'تم تحويل عرض السعر ${quotationData['number']} إلى فاتورة ${salesInvoice.number}',
            'created_at': now,
          });
        } catch (_) {
          // Ignore if audit_logs table doesn't exist or insert fails
        }

        // 5. Auto-post accounting entries for the created sales invoice
        await _postSalesInvoiceToJournal(
          txn: txn,
          invoiceId: invoiceId,
          invoiceData: {...invoiceData, 'id': invoiceId},
        );

        return invoiceId;
      });
    } catch (e) {
      if (e is LocalStorageException) {
        throw LocalStorageException(e.message);
      }
      throw LocalStorageException(
        'Failed to convert quotation: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getReturnInvoices() async {
    return await getInvoicesByType(4); // InvoiceType.salesReturn = 4
  }

  @override
  Future<List<InvoiceModel>> getReturnsByParentInvoice(
    int parentInvoiceId,
  ) async {
    try {
      final heads = await database.query(
        _invoicesTable,
        where: 'parent_invoice_id = ? AND invoice_type = ?',
        whereArgs: [parentInvoiceId, 4],
        orderBy: 'date DESC, id DESC',
      );

      final List<InvoiceModel> results = [];
      for (final h in heads) {
        final lines = await database.query(
          _linesTable,
          where: 'invoice_id = ?',
          whereArgs: [h['id']],
          orderBy: 'id ASC',
        );
        final lineModels = lines
            .map((e) => InvoiceLineModel.fromJson(e))
            .toList();
        results.add(InvoiceModel.fromJson(h, lines: lineModels));
      }
      return results;
    } catch (e) {
      throw LocalStorageException(
        'Failed to get returns by parent: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> createReturnInvoice(
    InvoiceModel returnInvoice,
    int parentInvoiceId,
  ) async {
    try {
      return await database.transaction((txn) async {
        // Ensure default stock exists
        final stocks = await txn.query('stocks', limit: 1);
        if (stocks.isEmpty) {
          // Create default stock if none exists
          await txn.insert('stocks', {
            'name': 'المخزن الرئيسي',
            'address': 'العنوان الافتراضي',
            'is_main_stock': 1,
            'is_active': 1,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        // 1. Insert the return invoice (remove ID to get new auto-generated ID)
        final returnData = returnInvoice.toJson();
        returnData.remove('id'); // Remove ID to avoid UNIQUE constraint error

        final returnId = await txn.insert(
          _invoicesTable,
          returnData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // 2. Insert return invoice lines and update inventory
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        double totalCOGSReversal = 0.0;

        for (final line in returnInvoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          final lineData = lineModel.toJson(invoiceId: returnId);
          lineData.remove('id'); // Remove ID to avoid UNIQUE constraint error

          await txn.insert(
            _linesTable,
            lineData,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          // 3. Update inventory - increase stock quantity for returns
          final productId = lineData['category_id'] as int?;
          final warehouseId =
              lineData['stock_id'] as int? ??
              (returnData['stock_id'] as int?) ??
              1;
          final returnQty = (lineData['quantity'] as num?)?.toDouble() ?? 0.0;

          if (productId != null && returnQty > 0) {
            // Get current stock and average cost
            final stockResult = await txn.query(
              'warehouse_stocks',
              where: 'product_id = ? AND warehouse_id = ?',
              whereArgs: [productId, warehouseId],
              limit: 1,
            );

            double currentQty = 0.0;
            double avgCost =
                (lineData['cost_price'] as num?)?.toDouble() ?? 0.0;

            if (stockResult.isNotEmpty) {
              currentQty =
                  (stockResult.first['quantity'] as num?)?.toDouble() ?? 0.0;
              avgCost =
                  (stockResult.first['avg_cost'] as num?)?.toDouble() ??
                  avgCost;
            }

            final newQty = currentQty + returnQty;

            // Calculate COGS reversal for this line
            totalCOGSReversal += returnQty * avgCost;

            // Update or insert warehouse stock
            if (stockResult.isNotEmpty) {
              await txn.update(
                'warehouse_stocks',
                {'quantity': newQty, 'last_modification_time': now},
                where: 'product_id = ? AND warehouse_id = ?',
                whereArgs: [productId, warehouseId],
              );
            } else {
              await txn.insert('warehouse_stocks', {
                'product_id': productId,
                'warehouse_id': warehouseId,
                'quantity': newQty,
                'avg_cost': avgCost,
                'last_cost': avgCost,
                'creation_time': now,
                'last_modification_time': now,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }

            // Record stock movement for audit trail
            try {
              await txn.insert('stock_movements', {
                'product_id': productId,
                'warehouse_id': warehouseId,
                'movement_type': 'return_sale',
                'quantity': returnQty, // Positive for return (add to stock)
                'unit_cost': avgCost,
                'total_cost': returnQty * avgCost,
                'balance_after': newQty,
                'reference_type': 'sales_return',
                'reference_id': returnId,
                'reference_number': returnInvoice.number,
                'creation_time': now,
              });
            } catch (_) {
              // Ignore if stock_movements table doesn't exist
            }
          }
        }

        // Store COGS reversal amount for journal entry
        returnData['cogs_reversal'] = totalCOGSReversal;

        // 4. Update parent invoice to reference this return
        await txn.update(
          _invoicesTable,
          {
            'next_invoice_id': returnId,
            'next_invoice_type': 4, // Return invoice
            'next_invoice_number': returnInvoice.number,
          },
          where: 'id = ?',
          whereArgs: [parentInvoiceId],
        );

        // Auto-post accounting entries for sales returns
        await _postSalesReturnToJournal(
          txn: txn,
          returnInvoiceId: returnId,
          invoiceData: {...returnData, 'id': returnId},
        );

        return returnId;
      });
    } catch (e) {
      throw LocalStorageException(
        'Failed to create return invoice: ${e.toString()}',
      );
    }
  }
}
