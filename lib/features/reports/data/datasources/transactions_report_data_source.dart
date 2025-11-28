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

    // Search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(description LIKE ? OR number LIKE ? OR reference_number LIKE ?)';
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

    // Also get transactions from invoices if needed
    if (transactionType == null || transactionType == 'all' || 
        transactionType == 'sales' || transactionType == 'purchase') {
      await _addInvoiceTransactions(
        db, 
        transactions, 
        filter, 
        transactionType,
        orderBy,
      );
    }

    // Sort the combined list
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
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Date filter
    if (filter.startDate != null && filter.endDate != null) {
      whereClause = 'invoice_date >= ? AND invoice_date <= ?';
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
      whereClause += '(invoice_number LIKE ? OR description LIKE ?)';
      final searchPattern = '%${filter.searchQuery}%';
      whereArgs.addAll([searchPattern, searchPattern]);
    }

    final invoices = await db.query(
      'invoices',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy.replaceAll('entry_date', 'invoice_date')
                     .replaceAll('total_debit', 'invoice_amount'),
    );

    for (final invoice in invoices) {
      final lines = await db.query(
        'invoice_lines',
        where: 'invoice_id = ?',
        whereArgs: [invoice['invoice_id']],
      );

      // Convert invoice to transaction format
      final transactionData = {
        'id': invoice['invoice_id'],
        'entry_date': invoice['invoice_date'],
        'description': invoice['description'] ?? 
            (invoice['invoice_type'] == 1 ? 'فاتورة مبيعات' : 'فاتورة مشتريات'),
        'number': invoice['invoice_number'],
        'reference_type': invoice['invoice_type'] == 1 ? 'sales' : 'purchase',
        'total_debit': invoice['invoice_amount'],
        'total_credit': invoice['invoice_amount'],
        'reference_id': invoice['invoice_id'],
        'creator_id': invoice['creator_id'],
        'creation_time': invoice['creation_time'],
      };

      // Convert invoice lines to journal entry lines format
      final journalLines = lines.map((line) => {
        'id': line['invoice_line_id'],
        'account_id': line['account_id'] ?? 1,
        'account_name': line['item_name'] ?? '',
        'account_code': line['item_code'] ?? '',
        'debit_amount': invoice['invoice_type'] == 1 ? 0.0 : (line['amount'] ?? 0.0),
        'credit_amount': invoice['invoice_type'] == 1 ? (line['amount'] ?? 0.0) : 0.0,
        'notes': line['notes'],
      }).toList();

      transactions.add(TransactionModel.fromDatabase(transactionData, journalLines));
    }
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

    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as count,
        SUM(total_debit) as total_debit,
        SUM(total_credit) as total_credit
      FROM journal_entries
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ''',
      whereArgs.isEmpty ? null : whereArgs,
    );

    if (result.isNotEmpty) {
      return {
        'count': result.first['count'] ?? 0,
        'totalDebit': result.first['total_debit'] ?? 0.0,
        'totalCredit': result.first['total_credit'] ?? 0.0,
      };
    }

    return {
      'count': 0,
      'totalDebit': 0.0,
      'totalCredit': 0.0,
    };
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
