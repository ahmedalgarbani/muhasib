import 'package:muhasib/core/errors/exceptions.dart';
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
    final cId = (connect.isNotEmpty ? connect.first['c_id'] : null) as int?;
    if (cId == null) {
      throw LocalStorageException(
        'الحساب غير مربوط: $label. الرجاء ربط الحسابات من صفحة ربط الحسابات.',
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
      throw LocalStorageException(
        'الحساب غير موجود في دليل الحسابات: $label (c_id=$cId).',
      );
    }
    return account.first['id'] as int;
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
    final accountId = (rows.isNotEmpty ? rows.first['account_id'] : null) as int?;
    return accountId ?? fallbackCustomersAccountId;
  }

  Future<Map<String, dynamic>> _getAccountMeta(Transaction txn, int accountId) async {
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
        columns: ['debit_limit', 'credit_limit', 'current_debit', 'current_credit', 'is_active'],
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
      final currentCredit = (limit['current_credit'] as num?)?.toDouble() ?? 0.0;

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
    final entryDate = (invoiceData['date'] as int?) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final statement = (invoiceData['statement'] as String?) ?? 'فاتورة مبيعات';
    final currencyId = await _resolveCurrencyId(
      txn,
      invoiceData['currency_id'] as int?,
    );

    final subtotal = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
    final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFee = (invoiceData['other_fee_amt'] as num?)?.toDouble() ?? 0.0;

    final totalAfterDiscount = (invoiceData['total_amount_after_discount'] as num?)?.toDouble() ??
        (subtotal - discount);
    final netRevenue = (invoiceData['net_revenue_amt'] as num?)?.toDouble() ??
        (totalAfterDiscount + otherFee);
    final total = (invoiceData['final_amt'] as num?)?.toDouble() ??
        (netRevenue + tax);

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

    final cashAccountId = await _resolveConnectedAccountId(txn, 1, label: 'الصناديق');
    // banks is optional for sales posting unless you support bank payments explicitly
    final salesAccountId = await _resolveConnectedAccountId(txn, 7, label: 'المبيعات');
    final taxAccountId = tax > 0 ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب') : 0;
    final discountAllowedId =
        discount > 0 ? await _resolveConnectedAccountId(txn, 8, label: 'الخصم المسموح به') : 0;

    // Build lines (balanced)
    final rawLines = <Map<String, dynamic>>[];

    // Debit side
    rawLines.add({
      'account_id': isCredit ? customerAccountId : cashAccountId,
      'debit_amount': total,
      'credit_amount': 0.0,
      'notes': statement,
      'description': isCredit ? 'ذمم العملاء - $invoiceNumber' : 'مبيعات نقدية - $invoiceNumber',
    });

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

    // Other fee account (optional)
    final otherFeeAccountId = invoiceData['other_fee_account_id'] as int?;
    if (otherFee > 0 && otherFeeAccountId != null) {
      rawLines.add({
        'account_id': otherFeeAccountId,
        'debit_amount': 0.0,
        'credit_amount': otherFee,
        'notes': statement,
        'description': 'رسوم أخرى - $invoiceNumber',
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
      throw LocalStorageException('قيد غير متوازن لفاتورة $invoiceNumber (فرق: ${diff.toStringAsFixed(2)})');
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
    final journalEntryId = await txn.insert(
      _journalEntriesTable,
      {
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
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    // Insert journal lines + update balances
    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(
        _journalLinesTable,
        {
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
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Update customer balance only for credit invoices (A/R)
    if (isCredit) {
      await txn.rawUpdate(
        'UPDATE $_customersTable SET current_balance = COALESCE(current_balance, 0) + ? WHERE id = ?',
        [total, customerId],
      );
    }
  }

  Future<void> _postSalesReturnToJournal({
    required Transaction txn,
    required int returnInvoiceId,
    required Map<String, dynamic> invoiceData,
  }) async {
    final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
    if (invoiceType != 4) return; // sales return only

    final invoiceNumber = (invoiceData['number'] as String?) ?? '';
    final entryDate = (invoiceData['date'] as int?) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final statement = (invoiceData['statement'] as String?) ?? 'مرتجع مبيعات';
    final currencyId = await _resolveCurrencyId(
      txn,
      invoiceData['currency_id'] as int?,
    );

    final netAmount = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;
    final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final total = (invoiceData['final_amt'] as num?)?.toDouble() ?? (netAmount + tax - discount);

    final isCredit = ((invoiceData['invoice_trans_type'] as int?) ?? 0) == 1;

    // Connected accounts
    final customersParentId = await _resolveConnectedAccountId(txn, 2, label: 'العملاء');
    final customerId = (invoiceData['customer_id'] as int?) ?? 1;
    final customerAccountId = await _resolveCustomerAccountId(
      txn,
      customerId,
      fallbackCustomersAccountId: customersParentId,
    );

    final cashAccountId = await _resolveConnectedAccountId(txn, 1, label: 'الصناديق');
    final salesReturnsAccountId = await _resolveConnectedAccountId(txn, 11, label: 'مردودات المبيعات');
    final taxAccountId = tax > 0 ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب') : 0;
    final discountAllowedId =
        discount > 0 ? await _resolveConnectedAccountId(txn, 8, label: 'الخصم المسموح به') : 0;

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
      'description': isCredit ? 'تخفيض ذمة العميل - $invoiceNumber' : 'إرجاع نقدي - $invoiceNumber',
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
      throw LocalStorageException('قيد غير متوازن لمرتجع $invoiceNumber (فرق: ${diff.toStringAsFixed(2)})');
    }

    if (currencyId != null) {
      await _validateAndUpdateAccountLimits(
        txn: txn,
        currencyId: currencyId,
        lines: rawLines,
      );
    }

    final journalNumber = await _nextJournalNumber(txn, 'SR');
    final journalEntryId = await txn.insert(
      _journalEntriesTable,
      {
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
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(
        _journalLinesTable,
        {
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
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Update customer balance only for credit returns (reduce A/R)
    if (isCredit) {
      await txn.rawUpdate(
        'UPDATE $_customersTable SET current_balance = COALESCE(current_balance, 0) - ? WHERE id = ?',
        [total, customerId],
      );
    }
  }

  Future<void> _postPurchaseInvoiceToJournal({
    required Transaction txn,
    required int invoiceId,
    required Map<String, dynamic> invoiceData,
  }) async {
    final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
    if (invoiceType != 2) return; // purchase invoice only

    final invoiceNumber = (invoiceData['number'] as String?) ?? '';
    final entryDate = (invoiceData['date'] as int?) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final statement = (invoiceData['statement'] as String?) ?? 'فاتورة مشتريات';
    final currencyId = await _resolveCurrencyId(
      txn,
      invoiceData['currency_id'] as int?,
    );

    final subtotal = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0; // قبل الخصم
    final discount = (invoiceData['discount_amt'] as num?)?.toDouble() ?? 0.0;
    final tax = (invoiceData['tax_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFee = (invoiceData['other_fee_amt'] as num?)?.toDouble() ?? 0.0;
    final otherFeeAccountId = invoiceData['other_fee_account_id'] as int?;

    // total (after discount + tax + fees)
    final total = (invoiceData['final_amt'] as num?)?.toDouble() ??
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

    final cashAccountId = await _resolveConnectedAccountId(txn, 1, label: 'الصناديق');
    final bankAccountId = await _resolveConnectedAccountId(txn, 0, label: 'البنوك');
    final purchasesAccountId = await _resolveConnectedAccountId(txn, 10, label: 'المشتريات');
    final taxAccountId = tax > 0 ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب') : 0;
    final discountEarnedId =
        discount > 0 ? await _resolveConnectedAccountId(txn, 9, label: 'الخصم المكتسب') : 0;

    // Pick cash/bank account: default to cash unless statement hints bank
    final paymentAccountId = (invoiceData['statement'] as String?)?.contains('بنك') == true
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

    // Credit payable/cash
    rawLines.add({
      'account_id': isCredit ? supplierAccountId : paymentAccountId,
      'debit_amount': 0.0,
      'credit_amount': total,
      'notes': statement,
      'description': isCredit ? 'ذمم الموردين - $invoiceNumber' : 'دفع مشتريات - $invoiceNumber',
    });

    // Validate balanced
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
      throw LocalStorageException('قيد غير متوازن لمشتريات $invoiceNumber (فرق: ${diff.toStringAsFixed(2)})');
    }

    if (currencyId != null) {
      await _validateAndUpdateAccountLimits(
        txn: txn,
        currencyId: currencyId,
        lines: rawLines,
      );
    }

    final journalNumber = await _nextJournalNumber(txn, 'PI');
    final journalEntryId = await txn.insert(
      _journalEntriesTable,
      {
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
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(
        _journalLinesTable,
        {
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
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Update supplier balance only for credit purchases (A/P)
    if (isCredit) {
      await txn.rawUpdate(
        'UPDATE $_customersTable SET current_balance = COALESCE(current_balance, 0) + ? WHERE id = ?',
        [total, supplierId],
      );
    }
  }

  Future<void> _postPurchaseReturnToJournal({
    required Transaction txn,
    required int returnInvoiceId,
    required Map<String, dynamic> invoiceData,
  }) async {
    final invoiceType = (invoiceData['invoice_type'] as int?) ?? 0;
    if (invoiceType != 5) return; // purchase return only

    final invoiceNumber = (invoiceData['number'] as String?) ?? '';
    final entryDate = (invoiceData['date'] as int?) ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
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

    final total = (invoiceData['final_amt'] as num?)?.toDouble() ??
        ((subtotal - discount) + otherFee + tax);

    final isCredit = ((invoiceData['invoice_trans_type'] as int?) ?? 0) == 1;

    final suppliersParentId = await _resolveConnectedAccountId(txn, 3, label: 'الموردون');
    final supplierId = (invoiceData['customer_id'] as int?) ?? 1;
    final supplierAccountId = await _resolveCustomerAccountId(
      txn,
      supplierId,
      fallbackCustomersAccountId: suppliersParentId,
    );

    final cashAccountId = await _resolveConnectedAccountId(txn, 1, label: 'الصناديق');
    final bankAccountId = await _resolveConnectedAccountId(txn, 0, label: 'البنوك');
    final purchaseReturnsAccountId = await _resolveConnectedAccountId(txn, 12, label: 'مردودات المشتريات');
    final taxAccountId = tax > 0 ? await _resolveConnectedAccountId(txn, 4, label: 'الضرائب') : 0;
    final discountEarnedId =
        discount > 0 ? await _resolveConnectedAccountId(txn, 9, label: 'الخصم المكتسب') : 0;

    final paymentAccountId = (invoiceData['statement'] as String?)?.contains('بنك') == true
        ? bankAccountId
        : cashAccountId;

    final rawLines = <Map<String, dynamic>>[];

    // Debit: supplier (reduce payable) or cash (refund received)
    rawLines.add({
      'account_id': isCredit ? supplierAccountId : paymentAccountId,
      'debit_amount': total,
      'credit_amount': 0.0,
      'notes': statement,
      'description': isCredit ? 'تخفيض ذمة المورد - $invoiceNumber' : 'استلام مردود مشتريات - $invoiceNumber',
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
      throw LocalStorageException('قيد غير متوازن لمردود مشتريات $invoiceNumber (فرق: ${diff.toStringAsFixed(2)})');
    }

    if (currencyId != null) {
      await _validateAndUpdateAccountLimits(
        txn: txn,
        currencyId: currencyId,
        lines: rawLines,
      );
    }

    final journalNumber = await _nextJournalNumber(txn, 'PR');
    final journalEntryId = await txn.insert(
      _journalEntriesTable,
      {
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
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    for (int i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      final accountId = l['account_id'] as int;
      final meta = await _getAccountMeta(txn, accountId);
      final debit = (l['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (l['credit_amount'] as num?)?.toDouble() ?? 0.0;

      await txn.insert(
        _journalLinesTable,
        {
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
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _applyAccountBalanceDelta(txn, accountId, debit - credit);
    }

    // Update supplier balance only for credit returns (reduce A/P)
    if (isCredit) {
      await txn.rawUpdate(
        'UPDATE $_customersTable SET current_balance = COALESCE(current_balance, 0) - ? WHERE id = ?',
        [total, supplierId],
      );
    }
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
        invoiceData['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
        
        // ========== Ensure FK targets exist (defensive seeding) ==========
        // 1) Classifications (needed for customers)
        final classificationsCount = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(1) FROM classifications'),
        ) ?? 0;
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
        Future<void> _ensureCustomer(int id, String name, int type) async {
          final rows = await txn.query('customers', where: 'id = ?', whereArgs: [id], limit: 1);
          if (rows.isEmpty) {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // seconds to match CHECK
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
        await _ensureCustomer(1, 'عميل نقدي', 1);
        await _ensureCustomer(2, 'عميل آجل', 2);

        // 3) Stocks (seed main stock id 1 if missing)
        final stockId = invoiceData['stock_id'] as int?;
        Future<int> _ensureStock(int? desiredId) async {
          if (desiredId != null) {
            final rows = await txn.query('stocks', where: 'id = ?', whereArgs: [desiredId], limit: 1);
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
        invoiceData['stock_id'] = await _ensureStock(stockId);

        // Ensure customer id points to an existing row (fallback to 1)
        int desiredCustomerId = (invoiceData['customer_id'] as int?) ?? 1;
        final cust = await txn.query('customers', where: 'id = ?', whereArgs: [desiredCustomerId], limit: 1);
        if (cust.isEmpty) {
          desiredCustomerId = 1;
        }
        invoiceData['customer_id'] = desiredCustomerId;
        
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
          lineData['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;

          // ========= Enforce/derive valid foreign keys for invoice_lines =========
          // currency_id -> nullable: if provided but not found, set to null
          final int? _currencyId = lineData['currency_id'] as int?;
          if (_currencyId != null) {
            final cur = await txn.query('currencies', where: 'id = ?', whereArgs: [_currencyId], limit: 1);
            if (cur.isEmpty) {
              lineData['currency_id'] = null;
            }
          }

          // category, group, unit, sub-unit
          final int? _categoryId = lineData['category_id'] as int?;
          int? _groupId = lineData['group_id'] as int?;
          int? _unitId = lineData['unit_id'] as int?;
          int? _subUnitId = lineData['category_sub_unit_id'] as int?;

          // Validate provided group/unit ids
          if (_groupId != null) {
            final g = await txn.query('categories_groups', where: 'id = ?', whereArgs: [_groupId], limit: 1);
            if (g.isEmpty) _groupId = null;
          }
          if (_unitId != null) {
            final u = await txn.query('categories_units', where: 'id = ?', whereArgs: [_unitId], limit: 1);
            if (u.isEmpty) _unitId = null;
          }

          // Try derive group/unit from category if missing
          int? validCategoryId = _categoryId;
          if (_categoryId != null) {
            final cat = await txn.query('categories', where: 'id = ?', whereArgs: [_categoryId], limit: 1);
            if (cat.isNotEmpty) {
              if (_groupId == null) {
                final cg = cat.first['group_id'] as int?;
                if (cg != null) {
                  final g2 = await txn.query('categories_groups', where: 'id = ?', whereArgs: [cg], limit: 1);
                  if (g2.isNotEmpty) {
                    _groupId = cg;
                  }
                }
              }
              if (_unitId == null) {
                final cu = cat.first['unit_id'] as int?;
                if (cu != null) {
                  final u2 = await txn.query('categories_units', where: 'id = ?', whereArgs: [cu], limit: 1);
                  if (u2.isNotEmpty) {
                    _unitId = cu;
                  }
                }
              }
            } else {
              // Provided category_id doesn't exist; null it to avoid FK violation (it's nullable in schema)
              validCategoryId = null;
            }
          }

          // If still no valid group_id, ensure or create a default
          if (_groupId == null) {
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
              _groupId = 1;
            } else {
              _groupId = anyGroup.first['id'] as int;
            }
          }

          // If still no valid unit_id, ensure or create a default
          if (_unitId == null) {
            // Try derive from category if exists
            if (_categoryId != null) {
              final cat = await txn.query('categories', where: 'id = ?', whereArgs: [_categoryId], limit: 1);
              if (cat.isNotEmpty) {
                final cu = cat.first['unit_id'] as int?;
                if (cu != null) {
                  final u2 = await txn.query('categories_units', where: 'id = ?', whereArgs: [cu], limit: 1);
                  if (u2.isNotEmpty) {
                    _unitId = cu;
                  }
                }
              }
            }
            if (_unitId == null) {
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
                _unitId = 1;
              } else {
                _unitId = anyUnit.first['id'] as int;
              }
            }
          }

          // Ensure category_sub_unit exists for this category (or create a default even without category)
          if (_subUnitId != null) {
            final s = await txn.query('category_sub_units', where: 'id = ?', whereArgs: [_subUnitId], limit: 1);
            if (s.isEmpty) _subUnitId = null;
          }
          if (_subUnitId == null) {
            if (validCategoryId != null) {
              final main = await txn.query('category_sub_units',
                  where: 'category_id = ? AND is_main_unit = 1', whereArgs: [validCategoryId], limit: 1);
              if (main.isNotEmpty) {
                _subUnitId = main.first['id'] as int;
              } else {
                final any = await txn.query('category_sub_units', where: 'category_id = ?', whereArgs: [validCategoryId], limit: 1);
                if (any.isNotEmpty) {
                  _subUnitId = any.first['id'] as int;
                }
              }
            }
            if (_subUnitId == null) {
              // No sub-unit found with or without category; create a default one (category_id can be NULL)
              final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final insertedId = await txn.insert('category_sub_units', {
                'packaging': 1,
                'is_active': 1,
                'is_main_unit': 1,
                'category_id': validCategoryId, // may be null
                'unit_id': _unitId,
                'conversion_rate': 1.0,
                'creation_time': nowSec,
                'last_modification_time': nowSec,
              });
              _subUnitId = insertedId;
            }
          }

          // Ensure valid stock_id for the line (fallback to header's stock_id)
          int? _lineStockId = lineData['stock_id'] as int?;
          if (_lineStockId != null) {
            final st = await txn.query('stocks', where: 'id = ?', whereArgs: [_lineStockId], limit: 1);
            if (st.isEmpty) _lineStockId = null;
          }
          _lineStockId ??= invoiceData['stock_id'] as int?;
          if (_lineStockId == null) {
            _lineStockId = await _ensureStock(null);
          }

          // Ensure valid customer_id for the line (fallback to header's customer_id)
          int? _lineCustomerId = lineData['customer_id'] as int?;
          if (_lineCustomerId != null) {
            final c = await txn.query('customers', where: 'id = ?', whereArgs: [_lineCustomerId], limit: 1);
            if (c.isEmpty) _lineCustomerId = null;
          }
          _lineCustomerId ??= invoiceData['customer_id'] as int?;
          _lineCustomerId ??= 1;

          // Write back ensured values
          lineData['category_id'] = validCategoryId; // null if invalid
          lineData['group_id'] = _groupId;
          lineData['unit_id'] = _unitId;
          lineData['category_sub_unit_id'] = _subUnitId;
          lineData['stock_id'] = _lineStockId;
          lineData['customer_id'] = _lineCustomerId;

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
          invoiceData: {
            ...invoiceData,
            'id': invoiceId,
          },
        );

        // Auto-post accounting entries for purchases and purchase returns
        await _postPurchaseInvoiceToJournal(
          txn: txn,
          invoiceId: invoiceId,
          invoiceData: {
            ...invoiceData,
            'id': invoiceId,
          },
        );
        await _postPurchaseReturnToJournal(
          txn: txn,
          returnInvoiceId: invoiceId,
          invoiceData: {
            ...invoiceData,
            'id': invoiceId,
          },
        );

        return invoiceId;
      });
    } catch (e) {
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
          await txn.insert(
            _linesTable,
            lineModel.toJson(invoiceId: invoice.id!),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });
    } catch (e) {
      throw LocalStorageException('Failed to update invoice: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteInvoice(int id) async {
    try {
      final deleted = await database.delete(
        _invoicesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (deleted == 0) {
        throw LocalStorageException('Invoice with id $id not found');
      }
    } catch (e) {
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
        where: 'invoice_type = ? AND (next_invoice_id IS NULL OR next_invoice_id = 0)',
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
        // 1. Insert the new sales invoice
        final invoiceId = await txn.insert(
          _invoicesTable,
          salesInvoice.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        
        // 2. Insert invoice lines
        for (final line in salesInvoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          await txn.insert(
            _linesTable,
            lineModel.toJson(invoiceId: invoiceId),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        
        // 3. Update the quotation to mark it as converted
        await txn.update(
          _invoicesTable,
          {
            'next_invoice_id': invoiceId,
            'next_invoice_type': 1, // Sales invoice
            'next_invoice_number': salesInvoice.number,
            'payment_status': 4, // Converted status
          },
          where: 'id = ?',
          whereArgs: [quotationId],
        );

        // Auto-post accounting entries for the created sales invoice
        await _postSalesInvoiceToJournal(
          txn: txn,
          invoiceId: invoiceId,
          invoiceData: {
            ...salesInvoice.toJson(),
            'id': invoiceId,
          },
        );
        
        return invoiceId;
      });
    } catch (e) {
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
          await txn.insert(
            'stocks',
            {
              'name': 'المخزن الرئيسي',
              'address': 'العنوان الافتراضي',
              'is_main_stock': 1,
              'is_active': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        
        // 1. Insert the return invoice
        final returnId = await txn.insert(
          _invoicesTable,
          returnInvoice.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        
        // 2. Insert return invoice lines
        for (final line in returnInvoice.lines) {
          final lineModel = line is InvoiceLineModel
              ? line
              : InvoiceLineModel.fromEntity(line);
          await txn.insert(
            _linesTable,
            lineModel.toJson(invoiceId: returnId),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          
          // 3. Update inventory - increase stock quantity for returns
          // TODO: Update this when products table is available
          // For now, skip inventory update to avoid database errors
          // await txn.rawUpdate(
          //   'UPDATE products SET quantity = quantity + ? WHERE id = ?',
          //   [line.quantity, line.groupId],
          // );
        }
        
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
          invoiceData: {
            ...returnInvoice.toJson(),
            'id': returnId,
          },
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
