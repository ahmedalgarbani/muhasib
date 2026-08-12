import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/transaction_model.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:sqflite/sqflite.dart';

abstract class TransactionsReportDataSource {
  Future<List<TransactionModel>> getTransactions({
    required ReportFilter filter,
    String? transactionType,
    String? sortBy,
    bool isAscending = false,
  });

  Future<Map<String, dynamic>> getTransactionsSummary({
    required ReportFilter filter,
    String? transactionType,
  });

  Future<TransactionModel> getTransactionDetails(int transactionId);

  Future<List<TransactionModel>> searchTransactions({
    required String query,
    ReportFilter? filter,
  });
}

class TransactionsReportDataSourceImpl implements TransactionsReportDataSource {
  final DatabaseService _databaseService;

  TransactionsReportDataSourceImpl(this._databaseService);

  @override
  Future<List<TransactionModel>> getTransactions({
    required ReportFilter filter,
    String? transactionType,
    String? sortBy,
    bool isAscending = false,
  }) async {
    final db = await _databaseService.database;

    String whereClause = 'is_posted = 1';
    List<dynamic> whereArgs = [];

    // Date filter
    if (filter.startDate != null && filter.endDate != null) {
      // Support both seconds (correct) and legacy milliseconds timestamps.
      whereClause =
          '((entry_date >= ? AND entry_date <= ?) OR (entry_date >= ? AND entry_date <= ?))';
      final startSec = filter.startDate!.millisecondsSinceEpoch ~/ 1000;
      final endSec = filter.endDate!.millisecondsSinceEpoch ~/ 1000;
      whereArgs = [startSec, endSec, startSec * 1000, endSec * 1000];
    }

    // Transaction type filter
    if (transactionType != null && transactionType != 'all') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'reference_type = ?';
      whereArgs.add(transactionType);
    }

    // Search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause +=
          '(description LIKE ? OR number LIKE ? OR reference_number LIKE ?)';
      final searchPattern = '%${filter.searchQuery}%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }

    // Sorting
    String orderBy = 'entry_date';
    switch (sortBy) {
      case 'amount':
        orderBy = 'total_debit';
        break;
      case 'date':
      default:
        orderBy = 'entry_date';
    }
    orderBy += isAscending ? ' ASC' : ' DESC';

    final journalEntries = await db.query(
      'journal_entries',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    final transactions = <TransactionModel>[];

    for (final entry in journalEntries) {
      final lines = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [entry['id']],
      );

      transactions.add(TransactionModel.fromDatabase(entry, lines));
    }

    // Invoices are represented by their posted journal entries, so adding
    // source invoices here would duplicate every posted transaction.
    // Sort the journal entries.
    transactions.sort((a, b) {
      switch (sortBy) {
        case 'amount':
          return isAscending
              ? a.totalAmount.compareTo(b.totalAmount)
              : b.totalAmount.compareTo(a.totalAmount);
        case 'date':
        default:
          return isAscending
              ? a.date.compareTo(b.date)
              : b.date.compareTo(a.date);
      }
    });

    return transactions;
  }

  Future<void> _addInvoiceTransactions(
    Database db,
    List<TransactionModel> transactions,
    ReportFilter filter,
    String? transactionType,
    String orderBy,
  ) async {
    String whereClause = 'is_posted = 1';
    List<dynamic> whereArgs = [];

    // Date filter
    if (filter.startDate != null && filter.endDate != null) {
      whereClause = 'date >= ? AND date <= ?';
      whereArgs = [
        filter.startDate!.millisecondsSinceEpoch ~/ 1000,
        filter.endDate!.millisecondsSinceEpoch ~/ 1000,
      ];
    }

    // Type filter for invoices
    if (transactionType == 'sales') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'invoice_type = 1'; // Sales invoice
    } else if (transactionType == 'purchase') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'invoice_type = 2'; // Purchase invoice
    }

    // Search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(number LIKE ? OR statement LIKE ?)';
      final searchPattern = '%${filter.searchQuery}%';
      whereArgs.addAll([searchPattern, searchPattern]);
    }

    final invoices = await db.query(
      'invoices',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy
          .replaceAll('entry_date', 'date')
          .replaceAll('total_debit', 'final_amt'),
    );

    for (final invoice in invoices) {
      final invoiceId = invoice['id'] as int;
      final invoiceDate = (invoice['date'] as int?) ?? 0;
      final invoiceNumber = (invoice['number'] ?? '') as String;
      final invoiceType = (invoice['invoice_type'] as int?) ?? 0;
      final invoiceAmount =
          (invoice['final_amt'] as num?)?.toDouble() ??
          (invoice['total_amount'] as num?)?.toDouble() ??
          (invoice['amount'] as num?)?.toDouble() ??
          0.0;

      // Convert invoice to transaction format
      final transactionData = {
        'id': invoiceId,
        'entry_date': invoiceDate,
        'description':
            invoice['statement'] ??
            (invoiceType == 1 ? 'فاتورة مبيعات' : 'فاتورة مشتريات'),
        'number': invoiceNumber,
        'reference_type': invoice['invoice_type'] == 1 ? 'sales' : 'purchase',
        'total_debit': invoiceAmount,
        'total_credit': invoiceAmount,
        'reference_id': invoiceId,
        'creator_id': invoice['creator_id'],
        'creation_time': invoice['creation_time'],
      };

      // Build accounting-correct two-line entry using account_connects mapping:
      // - Sales: Dr Customers, Cr Sales
      // - Purchase: Dr Purchases, Cr Suppliers
      final debitAccount = await _getConnectedAccount(
        db,
        invoiceType == 1 ? 2 : 10,
      );
      final creditAccount = await _getConnectedAccount(
        db,
        invoiceType == 1 ? 7 : 3,
      );

      final journalLines = <Map<String, dynamic>>[
        {
          'id': invoiceId * 10 + 1,
          'account_id': debitAccount['id'],
          'account_code': debitAccount['code'],
          'account_name': debitAccount['name'],
          'debit_amount': invoiceAmount,
          'credit_amount': 0.0,
          'notes': invoice['statement'],
        },
        {
          'id': invoiceId * 10 + 2,
          'account_id': creditAccount['id'],
          'account_code': creditAccount['code'],
          'account_name': creditAccount['name'],
          'debit_amount': 0.0,
          'credit_amount': invoiceAmount,
          'notes': invoice['statement'],
        },
      ];

      transactions.add(
        TransactionModel.fromDatabase(transactionData, journalLines),
      );
    }
  }

  /// Resolve connected account for a given connect type using:
  /// account_connects(account_connect_type -> accounts.c_id) -> accounts(id, code, name)
  Future<Map<String, dynamic>> _getConnectedAccount(
    Database db,
    int connectType,
  ) async {
    final connect = await db.query(
      'account_connects',
      columns: ['c_id'],
      where: 'account_connect_type = ?',
      whereArgs: [connectType],
      limit: 1,
    );

    final cId = (connect.isNotEmpty ? connect.first['c_id'] : null) as int?;
    if (cId == null) {
      // Fallback to a safe default (first active account)
      final fallback = await db.query(
        'accounts',
        columns: ['id', 'code', 'name'],
        where: 'is_active = 1',
        orderBy: 'code',
        limit: 1,
      );
      if (fallback.isEmpty) {
        return {'id': 1, 'code': '', 'name': ''};
      }
      return fallback.first;
    }

    final account = await db.query(
      'accounts',
      columns: ['id', 'code', 'name'],
      where: 'c_id = ?',
      whereArgs: [cId],
      limit: 1,
    );

    if (account.isEmpty) {
      return {'id': 1, 'code': '', 'name': ''};
    }

    return account.first;
  }

  @override
  Future<Map<String, dynamic>> getTransactionsSummary({
    required ReportFilter filter,
    String? transactionType,
  }) async {
    final db = await _databaseService.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Date filter
    if (filter.startDate != null && filter.endDate != null) {
      whereClause = 'entry_date >= ? AND entry_date <= ?';
      whereArgs = [
        filter.startDate!.millisecondsSinceEpoch ~/ 1000,
        filter.endDate!.millisecondsSinceEpoch ~/ 1000,
      ];
    }

    // Transaction type filter
    if (transactionType != null && transactionType != 'all') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'reference_type = ?';
      whereArgs.add(transactionType);
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        SUM(total_debit) as total_debit,
        SUM(total_credit) as total_credit
      FROM journal_entries
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ''', whereArgs.isEmpty ? null : whereArgs);

    if (result.isNotEmpty) {
      return {
        'count': result.first['count'] ?? 0,
        'totalDebit': result.first['total_debit'] ?? 0.0,
        'totalCredit': result.first['total_credit'] ?? 0.0,
      };
    }

    return {'count': 0, 'totalDebit': 0.0, 'totalCredit': 0.0};
  }

  @override
  Future<TransactionModel> getTransactionDetails(int transactionId) async {
    final db = await _databaseService.database;

    final entries = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (entries.isEmpty) {
      throw Exception('Transaction not found');
    }

    final lines = await db.query(
      'journal_entry_lines',
      where: 'journal_entry_id = ?',
      whereArgs: [transactionId],
    );

    return TransactionModel.fromDatabase(entries.first, lines);
  }

  @override
  Future<List<TransactionModel>> searchTransactions({
    required String query,
    ReportFilter? filter,
  }) async {
    final searchFilter = (filter ?? ReportFilter()).copyWith(
      searchQuery: query,
    );

    return getTransactions(
      filter: searchFilter,
      sortBy: 'date',
      isAscending: false,
    );
  }
}
