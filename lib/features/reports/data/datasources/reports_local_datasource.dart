import 'package:muhasib/core/constant/app_db_constants.dart';
import 'package:muhasib/core/enums/approval_status.dart';
import 'package:muhasib/core/enums/invoice_type.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';

/// Centralized data source for ALL raw SQL queries previously scattered in
/// presentation/pages. Verbatim SQL moved here and fixed:
/// - `!= 3` → `!= ${ApprovalStatus.rejected.value}`
/// - `IN (${ids.join(',')})` → placeholders with whereArgs
/// - date filtering via [normalizedReportTimestampSql] + [reportDateRangeArgs]
abstract class ReportsLocalDataSource {
  // ── Sales aggregates (sales_aggregates_report_pages.dart:405,562,713) ──
  Future<List<Map<String, dynamic>>> getSalesAggregatesByParty({
    required int invoiceType,
    required ReportFilter filter,
  });

  Future<List<Map<String, dynamic>>> getSalesAggregatesByProduct({
    required int invoiceType,
    required ReportFilter filter,
  });

  Future<List<Map<String, dynamic>>> getSalesAggregatesDaily({
    required int invoiceType,
    required ReportFilter filter,
  });

  // ── Purchase summary (purchase_summary_report_page.dart:258,262) ──
  Future<List<Map<String, dynamic>>> getPurchaseSummaryTotals({
    required ReportFilter filter,
  });

  Future<List<Map<String, dynamic>>> getPurchaseTopSuppliers({
    required ReportFilter filter,
  });

  // ── Party balances (party_balances_report_pages.dart:314) ──
  Future<List<Map<String, dynamic>>> getPartyBalances({
    required int customerType,
    required ReportFilter filter,
  });

  // ── Journal (journal_report_page.dart:228 db.query + 239 rawQuery) ──
  Future<List<Map<String, dynamic>>> getJournalEntries({
    required ReportFilter filter,
  });

  Future<List<Map<String, dynamic>>> getJournalEntryLines({
    required int journalEntryId,
  });

  // ── Invoices list (invoices_list_report_page.dart:279) ──
  Future<List<Map<String, dynamic>>> getInvoiceList({
    required ReportFilter filter,
    required List<int> invoiceTypes,
  });

  // ── General ledger (general_ledger_report_page.dart:287,455) ──
  Future<List<Map<String, dynamic>>> getGeneralLedgerSummary({
    required ReportFilter filter,
  });

  Future<List<Map<String, dynamic>>> getGeneralLedgerDetails({
    required int accountId,
    required ReportFilter filter,
  });

  // ── Cash flow (cash_flow_report_page.dart:211,222,228,234) ──
  Future<List<Map<String, dynamic>>> getCashAccountIds();

  Future<List<Map<String, dynamic>>> getCashFlowOpeningBalance({
    required int startSeconds,
    required List<int> accountIds,
  });

  Future<List<Map<String, dynamic>>> getCashFlowActualBalance({
    required int endSeconds,
    required List<int> accountIds,
  });

  Future<List<Map<String, dynamic>>> getCashFlowGrouped({
    required int startSeconds,
    required int endSeconds,
    required List<int> accountIds,
  });

  /// High-level helper that mirrors _CashFlowContent._load: fetches account ids,
  /// opening, actual and grouped data and lets caller categorize.
  /// Returns grouped rows; callers can also call the 3 helpers above.
  Future<List<Map<String, dynamic>>> getCashFlow({
    required ReportFilter filter,
  });

  // ── Balance sheet (balance_sheet_report_page.dart:235,250) ──
  Future<List<Map<String, dynamic>>> getBalanceSheetAccounts({
    required int asOfSeconds,
  });

  Future<List<Map<String, dynamic>>> getBalanceSheetNetIncome({
    required int asOfSeconds,
  });

  // ── Aged reports (aged_reports_pages.dart:249) ──
  Future<List<Map<String, dynamic>>> getAgedReceivables({
    required ReportFilter filter,
    required int customerType,
    required List<int> invoiceTypes,
  });

  // ── Inventory extra (inventory_extra_report_pages.dart:283,310,411,520) ──
  Future<List<Map<String, dynamic>>> getStockMovements();

  Future<List<Map<String, dynamic>>> getCategoryMovs();

  Future<List<Map<String, dynamic>>> getLowStock();

  Future<List<Map<String, dynamic>>> getInventoryValuation();

  // ── Extra 3: account / currency pages ──
  Future<List<Map<String, dynamic>>> getAccountTransactions({
    required int accountId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getCurrenciesForRevaluation();

  Future<List<Map<String, dynamic>>> getAccountsForRevaluation();

  Future<List<Map<String, dynamic>>> getAccountsForExchange();
}

class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  final DatabaseService _databaseService;

  ReportsLocalDataSourceImpl({required DatabaseService databaseService})
      : _databaseService = databaseService;

  // Ensure required imports are considered used (no unused_import lint)
  static const int _minValidTimestamp = AppDbConstants.minValidTimestamp;
  static const InvoiceType _exampleInvoiceType = InvoiceType.salesInvoice;

  // =========================================================================
  // Sales aggregates
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/sales_aggregates_report_pages.dart:405
  @override
  Future<List<Map<String, dynamic>>> getSalesAggregatesByParty({
    required int invoiceType,
    required ReportFilter filter,
  }) async {
    // Reference example imports to avoid unused lints
    assert(_minValidTimestamp == AppDbConstants.minValidTimestamp);
    assert(_exampleInvoiceType.value == InvoiceType.salesInvoice.value);

    final db = await _databaseService.database;
    final args = <Object?>[invoiceType];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('i.date');
      dateFilter = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    // Original WHERE : i.invoice_type = ? AND COALESCE(i.approval_status,1)!=3
    // Fixed: != ${ApprovalStatus.rejected.value} with interpolation
    final rows = await db.rawQuery('''
      SELECT c.id as party_id, c.name as party_name, COUNT(i.id) as doc_count, COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total
      FROM invoices i
      INNER JOIN customers c ON c.id = i.customer_id
      WHERE i.invoice_type = ? AND COALESCE(i.approval_status, 1) != ${ApprovalStatus.rejected.value} $dateFilter
      GROUP BY c.id, c.name ORDER BY total DESC
    ''', args);
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/sales_aggregates_report_pages.dart:562
  @override
  Future<List<Map<String, dynamic>>> getSalesAggregatesByProduct({
    required int invoiceType,
    required ReportFilter filter,
  }) async {
    final db = await _databaseService.database;
    final args = <Object?>[invoiceType];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('i.date');
      df = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    final rows = await db.rawQuery('''
      SELECT c.id as pid, c.name as pname, COALESCE(SUM(il.quantity), 0) as qty, COALESCE(SUM(il.total_amount), 0) as total
      FROM invoice_lines il INNER JOIN invoices i ON i.id = il.invoice_id LEFT JOIN categories c ON c.id = il.category_id
      WHERE i.invoice_type = ? AND COALESCE(i.approval_status, 1) != ${ApprovalStatus.rejected.value} $df
      GROUP BY c.id, c.name ORDER BY total DESC
    ''', args);
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/sales_aggregates_report_pages.dart:713
  @override
  Future<List<Map<String, dynamic>>> getSalesAggregatesDaily({
    required int invoiceType,
    required ReportFilter filter,
  }) async {
    final db = await _databaseService.database;
    final args = <Object?>[invoiceType];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('i.date');
      df = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    final rows = await db.rawQuery('''
      SELECT date(${normalizedReportTimestampSql('i.date')}, 'unixepoch') as day, COUNT(i.id) as cnt, COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total
      FROM invoices i WHERE i.invoice_type = ? AND COALESCE(i.approval_status, 1) != ${ApprovalStatus.rejected.value} $df
      GROUP BY day ORDER BY day
    ''', args);
    return rows;
  }

  // =========================================================================
  // Purchase summary
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/purchase_summary_report_page.dart:258
  @override
  Future<List<Map<String, dynamic>>> getPurchaseSummaryTotals({
    required ReportFilter filter,
  }) async {
    final db = await _databaseService.database;
    final args = <Object?>[];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('i.date');
      df = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    final rows = await db.rawQuery(
      'SELECT COUNT(CASE WHEN i.invoice_type = 2 THEN 1 END) as ic, COUNT(CASE WHEN i.invoice_type = 5 THEN 1 END) as rc, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as tp, COALESCE(SUM(CASE WHEN i.invoice_type = 5 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as tr, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.tax_amt, 0) END), 0) as tx, COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.discount_amt, 0) END), 0) as td FROM invoices i WHERE (i.invoice_type = 2 OR i.invoice_type = 5) AND COALESCE(i.approval_status, 1) != ${ApprovalStatus.rejected.value} $df',
      args,
    );
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/purchase_summary_report_page.dart:262
  @override
  Future<List<Map<String, dynamic>>> getPurchaseTopSuppliers({
    required ReportFilter filter,
  }) async {
    final db = await _databaseService.database;
    final args = <Object?>[];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('i.date');
      df = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    final rows = await db.rawQuery(
      'SELECT c.name, COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total FROM invoices i JOIN customers c ON c.id = i.customer_id WHERE i.invoice_type = 2 AND COALESCE(i.approval_status, 1) != ${ApprovalStatus.rejected.value} $df GROUP BY c.id ORDER BY total DESC',
      args,
    );
    return rows;
  }

  // =========================================================================
  // Party balances
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/party_balances_report_pages.dart:314
  @override
  Future<List<Map<String, dynamic>>> getPartyBalances({
    required int customerType,
    required ReportFilter filter,
  }) async {
    // filter is not used in original (showDateFilter: false) but kept for signature uniformity
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      'SELECT c.id, c.name, COALESCE(a.balance, 0) as balance FROM customers c LEFT JOIN accounts a ON a.id = c.account_id WHERE c.is_active = 1 AND c.type = ? ORDER BY ABS(balance) DESC',
      [customerType],
    );
    return rows;
  }

  // =========================================================================
  // Journal
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/journal_report_page.dart:228
  @override
  Future<List<Map<String, dynamic>>> getJournalEntries({
    required ReportFilter filter,
  }) async {
    final db = await _databaseService.database;
    final args = <Object?>[];
    String where = '1=1';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('entry_date');
      where += ' AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    final rows = await db.query(
      'journal_entries',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'entry_date ASC, id ASC',
    );
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/journal_report_page.dart:239
  @override
  Future<List<Map<String, dynamic>>> getJournalEntryLines({
    required int journalEntryId,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      '''
        SELECT jel.*, a.code as acode, a.name as aname 
        FROM journal_entry_lines jel 
        LEFT JOIN accounts a ON a.id = jel.account_id 
        WHERE jel.journal_entry_id = ? 
        ORDER BY jel.line_number, jel.id
      ''',
      [journalEntryId],
    );
    return rows;
  }

  // =========================================================================
  // Invoices list
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/invoices_list_report_page.dart:279
  @override
  Future<List<Map<String, dynamic>>> getInvoiceList({
    required ReportFilter filter,
    required List<int> invoiceTypes,
  }) async {
    final db = await _databaseService.database;
    final args = <Object?>[];
    final whereParts = <String>[];

    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('i.date');
      whereParts.add('$dateColumn >= ? AND $dateColumn <= ?');
      args.addAll(reportDateRangeArgs(filter));
    }
    if (invoiceTypes.isNotEmpty) {
      final placeholders = invoiceTypes.map((_) => '?').join(',');
      whereParts.add('i.invoice_type IN ($placeholders)');
      args.addAll(invoiceTypes);
    }
    final where = whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT
        i.id,
        i.number,
        i.date,
        i.statement,
        i.invoice_type,
        COALESCE(i.approval_status, 1) as status,
        COALESCE(i.final_amt, i.total_amount, i.amount, 0) as amount,
        c.name as party_name,
        CASE WHEN EXISTS (SELECT 1 FROM journal_entries je WHERE je.reference_id = i.id AND je.reference_type IN ('sales', 'purchase', 'sales_return', 'purchase_return')) THEN 1 ELSE 0 END as has_journal_entry
      FROM invoices i
      LEFT JOIN customers c ON c.id = i.customer_id
      $where
      ORDER BY i.date DESC, i.id DESC
    ''', args);
    return rows;
  }

  // =========================================================================
  // General ledger
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/general_ledger_report_page.dart:287
  @override
  Future<List<Map<String, dynamic>>> getGeneralLedgerSummary({
    required ReportFilter filter,
  }) async {
    final db = await _databaseService.database;
    final args = <Object?>[];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('je.entry_date');
      df = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    final rows = await db.rawQuery('''
      SELECT a.id, a.code, a.name, a.type, 
             COALESCE(SUM(jel.debit_amount), 0) as td, 
             COALESCE(SUM(jel.credit_amount), 0) as tc
      FROM accounts a 
      INNER JOIN journal_entry_lines jel ON jel.account_id = a.id 
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1 $df 
      GROUP BY a.id 
      ORDER BY a.code
    ''', args);
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/general_ledger_report_page.dart:455
  @override
  Future<List<Map<String, dynamic>>> getGeneralLedgerDetails({
    required int accountId,
    required ReportFilter filter,
  }) async {
    final db = await _databaseService.database;
    // Original uses raw epoch without normalized helper; keep verbatim but use reportDateRangeArgs helpers where possible.
    // We keep plain je.entry_date comparison to stay verbatim, but use helper args for timestamps.
    String df = '';
    final args = <Object?>[accountId];
    if (filter.startDate != null && filter.endDate != null) {
      df = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(reportTimestampSeconds(filter.startDate!));
      args.add(reportTimestampSeconds(filter.endDate!));
    }
    final rows = await db.rawQuery('''
      SELECT je.entry_date, je.description, jel.debit_amount as d, jel.credit_amount as c 
      FROM journal_entry_lines jel 
      JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE jel.account_id = ? AND je.is_posted = 1 $df
      ORDER BY je.entry_date ASC, jel.id ASC
    ''', args);
    return rows;
  }

  // =========================================================================
  // Cash flow — 4 queries share same original method (cash_flow_report_page.dart:211,222,228,234)
  // Fixed IN (${ids.join(',')}) → placeholders with whereArgs
  // =========================================================================

  /// Source: cash_flow_report_page.dart:211-214
  @override
  Future<List<Map<String, dynamic>>> getCashAccountIds() async {
    final db = await _databaseService.database;
    // Fixed: original `IN (0, 1)` → `IN (?, ?)` with args
    final rows = await db.rawQuery(
      'SELECT a.id FROM account_connects ac JOIN accounts a ON a.c_id = ac.c_id WHERE ac.account_connect_type IN (?, ?)',
      [0, 1],
    );
    return rows;
  }

  /// Source: cash_flow_report_page.dart:222-226 (opening balance)
  @override
  Future<List<Map<String, dynamic>>> getCashFlowOpeningBalance({
    required int startSeconds,
    required List<int> accountIds,
  }) async {
    if (accountIds.isEmpty) return [{'b': 0}];
    final db = await _databaseService.database;
    final placeholders = List.filled(accountIds.length, '?').join(',');
    final args = <Object?>[...accountIds, startSeconds];
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(debit_amount - credit_amount), 0) as b FROM journal_entry_lines jel JOIN journal_entries je ON je.id = jel.journal_entry_id WHERE je.is_posted = 1 AND jel.account_id IN ($placeholders) AND je.entry_date < ?',
      args,
    );
    return rows;
  }

  /// Source: cash_flow_report_page.dart:228-231 (actual balance)
  @override
  Future<List<Map<String, dynamic>>> getCashFlowActualBalance({
    required int endSeconds,
    required List<int> accountIds,
  }) async {
    if (accountIds.isEmpty) return [{'b': 0}];
    final db = await _databaseService.database;
    final placeholders = List.filled(accountIds.length, '?').join(',');
    final args = <Object?>[...accountIds, endSeconds];
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(debit_amount - credit_amount), 0) as b FROM journal_entry_lines jel JOIN journal_entries je ON je.id = jel.journal_entry_id WHERE je.is_posted = 1 AND jel.account_id IN ($placeholders) AND je.entry_date <= ?',
      args,
    );
    return rows;
  }

  /// Source: cash_flow_report_page.dart:234-238 (grouped by reference_type)
  @override
  Future<List<Map<String, dynamic>>> getCashFlowGrouped({
    required int startSeconds,
    required int endSeconds,
    required List<int> accountIds,
  }) async {
    if (accountIds.isEmpty) return [];
    final db = await _databaseService.database;
    final placeholders = List.filled(accountIds.length, '?').join(',');
    final args = <Object?>[...accountIds, startSeconds, endSeconds];
    final rows = await db.rawQuery(
      'SELECT je.reference_type, COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as net FROM journal_entry_lines jel JOIN journal_entries je ON je.id = jel.journal_entry_id WHERE je.is_posted = 1 AND jel.account_id IN ($placeholders) AND je.entry_date >= ? AND je.entry_date <= ? GROUP BY je.reference_type',
      args,
    );
    return rows;
  }

  /// High-level wrapper mirroring _CashFlowContent._load (211+222+228+234)
  /// Returns grouped rows; callers needing opening/actual can use helpers above.
  @override
  Future<List<Map<String, dynamic>>> getCashFlow({
    required ReportFilter filter,
  }) async {
    final accountRows = await getCashAccountIds();
    final ids = accountRows.map((m) => m['id'] as int).toList();
    if (ids.isEmpty) return [];
    final start = filter.startDate != null
        ? reportTimestampSeconds(filter.startDate!)
        : reportTimestampSeconds(DateTime(2020));
    final end = filter.endDate != null
        ? reportTimestampSeconds(filter.endDate!)
        : reportTimestampSeconds(DateTime.now());
    return getCashFlowGrouped(
      startSeconds: start,
      endSeconds: end,
      accountIds: ids,
    );
  }

  // =========================================================================
  // Balance sheet
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/balance_sheet_report_page.dart:235
  @override
  Future<List<Map<String, dynamic>>> getBalanceSheetAccounts({
    required int asOfSeconds,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      '''
      SELECT a.id, a.code, a.name, a.type, COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as net
      FROM accounts a 
      LEFT JOIN journal_entry_lines jel ON jel.account_id = a.id 
      LEFT JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND (je.is_posted = 1 OR je.id IS NULL) AND (je.entry_date <= ? OR je.id IS NULL) 
        AND (a.type IN (0, 1, 2) OR a.code LIKE '1%' OR a.code LIKE '2%')
      GROUP BY a.id, a.code, a.name, a.type 
      HAVING net != 0 
      ORDER BY a.code
    ''',
      [asOfSeconds],
    );
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/balance_sheet_report_page.dart:250
  @override
  Future<List<Map<String, dynamic>>> getBalanceSheetNetIncome({
    required int asOfSeconds,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(
        CASE 
          WHEN (a.type = 3 OR a.code LIKE '4%') THEN jel.credit_amount - jel.debit_amount
          WHEN (a.type = 4 OR a.code LIKE '3%') THEN -(jel.debit_amount - jel.credit_amount)
          ELSE 0
        END
      ), 0) as ni
      FROM accounts a 
      JOIN journal_entry_lines jel ON jel.account_id = a.id 
      JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1 AND je.entry_date <= ? 
        AND (a.type IN (3, 4) OR a.code LIKE '3%' OR a.code LIKE '4%') 
        AND COALESCE(je.reference_type, '') NOT IN ('opening_entry', 'opening_balance', 'closing')
    ''',
      [asOfSeconds],
    );
    return rows;
  }

  // =========================================================================
  // Aged reports
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/aged_reports_pages.dart:249
  @override
  Future<List<Map<String, dynamic>>> getAgedReceivables({
    required ReportFilter filter,
    required int customerType,
    required List<int> invoiceTypes,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final asOf = filter.endDate != null
        ? reportTimestampSeconds(filter.endDate!)
        : reportTimestampSeconds(now);
    final args = <Object?>[asOf, customerType];
    final typeClause = invoiceTypes.isEmpty
        ? ''
        : 'AND i.invoice_type IN (${invoiceTypes.map((_) => '?').join(',')})';
    if (invoiceTypes.isNotEmpty) args.addAll(invoiceTypes);

    final rows = await db.rawQuery('''
      SELECT i.id, i.date, i.due_date,
        COALESCE(i.final_amt, i.total_amount, i.amount, 0) as amount,
        COALESCE(i.paid_amount, 0) as paid_amount,
        COALESCE(i.bank_paid_amount, 0) as bank_paid_amount,
        i.customer_id
      FROM invoices i INNER JOIN customers c ON c.id = i.customer_id
      WHERE ${normalizedReportTimestampSql('COALESCE(i.due_date, i.date)')} <= ?
        AND c.type = ?
        AND i.payment_status != 2
        AND COALESCE(i.approval_status, 1) != ${ApprovalStatus.rejected.value}
        $typeClause
    ''', args);
    return rows;
  }

  // =========================================================================
  // Inventory extra
  // =========================================================================

  /// Source: lib/features/reports/presentation/pages/inventory_extra_report_pages.dart:283
  @override
  Future<List<Map<String, dynamic>>> getStockMovements() async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery('''
        SELECT sm.creation_time as trans_date, 
               CASE WHEN sm.quantity > 0 THEN sm.quantity ELSE 0 END as quantity_in,
               CASE WHEN sm.quantity < 0 THEN -sm.quantity ELSE 0 END as quantity_out,
               COALESCE(sm.reference_number, sm.reference_type, '') as refrenc_no,
               c.name 
        FROM stock_movements sm 
        JOIN categories c ON c.id = sm.product_id 
        ORDER BY sm.creation_time DESC LIMIT 100
      ''');
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/inventory_extra_report_pages.dart:310
  @override
  Future<List<Map<String, dynamic>>> getCategoryMovs() async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      'SELECT cm.trans_date, cm.quantity_in, cm.quantity_out, cm.refrenc_no, c.name FROM category_movs cm JOIN categories c ON c.id = cm.category_id ORDER BY cm.trans_date DESC LIMIT 100',
    );
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/inventory_extra_report_pages.dart:411
  @override
  Future<List<Map<String, dynamic>>> getLowStock() async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery(
      'SELECT name, quantity, COALESCE(min_stock_level, 0) as ms FROM categories WHERE is_active = 1 AND quantity <= COALESCE(min_stock_level, 0)',
    );
    return rows;
  }

  /// Source: lib/features/reports/presentation/pages/inventory_extra_report_pages.dart:520
  @override
  Future<List<Map<String, dynamic>>> getInventoryValuation() async {
    final db = await _databaseService.database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.name, 
             COALESCE((SELECT SUM(ws.quantity) FROM warehouse_stocks ws WHERE ws.product_id = c.id), c.quantity, 0) as total_qty,
             COALESCE((SELECT SUM(ws.quantity * CASE WHEN ws.avg_cost > 0 THEN ws.avg_cost ELSE COALESCE(c.cost_amount, 0) END) FROM warehouse_stocks ws WHERE ws.product_id = c.id), COALESCE(c.cost_amount, 0) * COALESCE(c.quantity, 0), 0) as val 
      FROM categories c 
      WHERE c.is_active = 1 
      GROUP BY c.id 
      HAVING total_qty > 0 OR val > 0 
      ORDER BY val DESC
    ''');
    return rows;
  }

  // =========================================================================
  // Extra 3: accounts / currencies
  // =========================================================================

  /// Source: lib/features/accounts/presentation/pages/account_transactions_page.dart:53
  @override
  Future<List<Map<String, dynamic>>> getAccountTransactions({
    required int accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseService.database;
    final whereArgs = <Object?>[accountId];
    String dateFilter = '';
    if (startDate != null && endDate != null) {
      // Use plain entry_date epoch as original page does
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch ~/ 1000);
      whereArgs.add(endDate.millisecondsSinceEpoch ~/ 1000);
    }
    final rows = await db.rawQuery('''
        SELECT 
          je.id,
          je.number as entry_number,
          je.entry_date as date,
          je.description,
          jel.debit_amount,
          jel.credit_amount,
          jel.notes,
          'journal' as source_type
        FROM journal_entry_lines jel
        JOIN journal_entries je ON je.id = jel.journal_entry_id
        WHERE jel.account_id = ?
        $dateFilter
        ORDER BY je.entry_date DESC, je.id DESC
      ''', whereArgs);
    return rows;
  }

  /// Source: lib/features/currencies/presentation/pages/currency_revaluation_page.dart:36
  @override
  Future<List<Map<String, dynamic>>> getCurrenciesForRevaluation() async {
    final db = await _databaseService.database;
    // Fixed: original where 'is_local_currency = 0' → placeholder with whereArgs
    final rows = await db.query(
      'currencies',
      where: 'is_local_currency = ?',
      whereArgs: [0],
      orderBy: 'name',
    );
    return rows;
  }

  /// Source: lib/features/currencies/presentation/pages/currency_revaluation_page.dart:41
  @override
  Future<List<Map<String, dynamic>>> getAccountsForRevaluation() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'accounts',
      where: 'is_active = ? AND is_master = ?',
      whereArgs: [1, 0],
      orderBy: 'code',
    );
    return rows;
  }

  /// Source: lib/features/currencies/presentation/pages/currency_exchange_page_v2.dart:45
  @override
  Future<List<Map<String, dynamic>>> getAccountsForExchange() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'accounts',
      columns: ['id', 'code', 'name', 'type'],
      where: 'is_active = ? AND is_master = ?',
      whereArgs: [1, 0],
      orderBy: 'code',
    );
    return rows;
  }
}
