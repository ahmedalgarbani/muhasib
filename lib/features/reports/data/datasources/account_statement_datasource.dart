import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/account_statement_model.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/account_statement_entity.dart';

abstract class AccountStatementDataSource {
  Future<List<AccountStatementModel>> getAccountStatement({
    required int accountId,
    required ReportFilter filter,
  });

  Future<AccountStatementSummary> getAccountStatementSummary({
    required int accountId,
    required ReportFilter filter,
  });

  Future<List<Map<String, dynamic>>> getAllAccounts();
}

class AccountStatementDataSourceImpl implements AccountStatementDataSource {
  final DatabaseService databaseService;

  AccountStatementDataSourceImpl({required this.databaseService});

  @override
  Future<List<AccountStatementModel>> getAccountStatement({
    required int accountId,
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    String dateFilter = '';
    final args = <Object?>[accountId];
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('je.entry_date');
      dateFilter = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }

    final query =
        '''
      SELECT 
        jel.id as transaction_id,
        jel.journal_entry_id as journal_entry_id,
        datetime(${normalizedReportTimestampSql('je.entry_date')}, 'unixepoch') as transaction_date,
        COALESCE(je.description, '') as description,
        COALESCE(je.reference_number, je.number, '') as reference,
        jel.debit_amount as debit_amount,
        jel.credit_amount as credit_amount,
        0 as balance,
        'journal' as transaction_type
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE je.is_posted = 1 AND jel.account_id = ?
      $dateFilter
      ORDER BY je.entry_date, jel.id
    ''';

    // Get account type to determine normal balance nature
    final accRows = await db.query(
      'accounts',
      columns: ['type', 'code'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    final accType = accRows.isNotEmpty
        ? (accRows.first['type'] as int? ?? 1)
        : 1;
    final accCode = accRows.isNotEmpty
        ? (accRows.first['code'] as String? ?? '')
        : '';
    final isCreditNormal =
        accType == 2 ||
        accType == 4 ||
        accCode.startsWith('2') ||
        accCode.startsWith('4');

    final result = await db.rawQuery(query, args);

    double balance = await _getOpeningBalance(
      accountId,
      filter.startDate,
      isCreditNormal: isCreditNormal,
    );
    final transactions = <AccountStatementModel>[];

    for (final row in result) {
      final debit = (row['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (row['credit_amount'] as num?)?.toDouble() ?? 0.0;
      if (isCreditNormal) {
        balance += (credit - debit);
      } else {
        balance += (debit - credit);
      }

      transactions.add(
        AccountStatementModel.fromMap({...row, 'balance': balance}),
      );
    }

    return transactions;
  }

  @override
  Future<AccountStatementSummary> getAccountStatementSummary({
    required int accountId,
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    // Get account info
    final accountQuery = '''
      SELECT id, code, name, type 
      FROM accounts 
      WHERE id = ?
    ''';

    final accountResult = await db.rawQuery(accountQuery, [accountId]);
    if (accountResult.isEmpty) {
      throw Exception('Account not found');
    }

    final account = accountResult.first;
    final accType = (account['type'] as int?) ?? 1;
    final accCode = (account['code'] as String?) ?? '';
    final isCreditNormal =
        accType == 2 ||
        accType == 4 ||
        accCode.startsWith('2') ||
        accCode.startsWith('4');

    String dateFilter = '';
    final args = <Object?>[accountId];
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('je.entry_date');
      dateFilter = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }

    // Get transaction summary
    final summaryQuery =
        '''
      SELECT 
        COUNT(DISTINCT jel.id) as transaction_count,
        COALESCE(SUM(jel.debit_amount), 0) as total_debits,
        COALESCE(SUM(jel.credit_amount), 0) as total_credits
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE je.is_posted = 1 AND jel.account_id = ?
      $dateFilter
    ''';

    final summaryResult = await db.rawQuery(summaryQuery, args);

    final openingBalance = await _getOpeningBalance(
      accountId,
      filter.startDate,
      isCreditNormal: isCreditNormal,
    );
    final totalDebits =
        (summaryResult.first['total_debits'] as num?)?.toDouble() ?? 0.0;
    final totalCredits =
        (summaryResult.first['total_credits'] as num?)?.toDouble() ?? 0.0;
    final closingBalance = isCreditNormal
        ? openingBalance + (totalCredits - totalDebits)
        : openingBalance + (totalDebits - totalCredits);

    return AccountStatementSummary(
      accountId: accountId,
      accountCode: account['code'] as String,
      accountName: account['name'] as String,
      openingBalance: openingBalance,
      totalDebits: totalDebits,
      totalCredits: totalCredits,
      closingBalance: closingBalance,
      transactionCount: (summaryResult.first['transaction_count'] ?? 0) as int,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await databaseService.database;

    final query = '''
      SELECT id, code, name, type 
      FROM accounts 
      WHERE is_active = 1
      ORDER BY code
    ''';

    return await db.rawQuery(query);
  }

  Future<double> _getOpeningBalance(
    int accountId,
    DateTime? beforeDate, {
    bool isCreditNormal = false,
  }) async {
    if (beforeDate == null) return 0;

    final db = await databaseService.database;

    final query =
        '''
      SELECT 
        COALESCE(SUM(jel.debit_amount), 0) as d,
        COALESCE(SUM(jel.credit_amount), 0) as c
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE je.is_posted = 1 AND jel.account_id = ?
      AND ${normalizedReportTimestampSql('je.entry_date')} < ?
    ''';

    final result = await db.rawQuery(query, [
      accountId,
      reportTimestampSeconds(beforeDate),
    ]);
    if (result.isNotEmpty) {
      final d = (result.first['d'] as num?)?.toDouble() ?? 0.0;
      final c = (result.first['c'] as num?)?.toDouble() ?? 0.0;
      return isCreditNormal ? (c - d) : (d - c);
    }
    return 0;
  }
}
