import 'package:muhasib/core/enums/sort_options.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/transaction_model.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';

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
      final dateColumn = normalizedReportTimestampSql('entry_date');
      whereClause += ' AND $dateColumn >= ? AND $dateColumn <= ?';
      whereArgs.addAll(reportDateRangeArgs(filter));
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

    // Sorting — type-safe via TransactionSortBy
    final sort = TransactionSortBy.fromCode(sortBy);
    final orderBy = '${sort.column} ${isAscending ? 'ASC' : 'DESC'}';

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
    // Sort the journal entries — via TransactionSortBy
    final sortForList = TransactionSortBy.fromCode(sortBy);
    transactions.sort((a, b) {
      return switch (sortForList) {
        TransactionSortBy.amount => isAscending
            ? a.totalAmount.compareTo(b.totalAmount)
            : b.totalAmount.compareTo(a.totalAmount),
        TransactionSortBy.date => isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
      };
    });

    return transactions;
  }

  @override
  Future<Map<String, dynamic>> getTransactionsSummary({
    required ReportFilter filter,
    String? transactionType,
  }) async {
    final db = await _databaseService.database;

    String whereClause = 'is_posted = 1';
    List<dynamic> whereArgs = [];

    // Date filter
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('entry_date');
      whereClause += ' AND $dateColumn >= ? AND $dateColumn <= ?';
      whereArgs.addAll(reportDateRangeArgs(filter));
    }

    // Transaction type filter
    if (transactionType != null && transactionType != 'all') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'reference_type = ?';
      whereArgs.add(transactionType);
    }

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      whereClause +=
          ' AND (description LIKE ? OR number LIKE ? OR reference_number LIKE ?)';
      final searchPattern = '%${filter.searchQuery}%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
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
        'totalDebit': (result.first['total_debit'] as num?)?.toDouble() ?? 0.0,
        'totalCredit':
            (result.first['total_credit'] as num?)?.toDouble() ?? 0.0,
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
