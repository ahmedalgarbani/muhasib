import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/account_statement_model.dart';
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
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final query =
        '''
      SELECT 
        jel.id as transaction_id,
        datetime(je.entry_date, 'unixepoch') as transaction_date,
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

    final result = await db.rawQuery(query, args);

    double balance = await _getOpeningBalance(accountId, filter.startDate);
    final transactions = <AccountStatementModel>[];

    for (final row in result) {
      final debit = (row['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (row['credit_amount'] as num?)?.toDouble() ?? 0.0;
      balance += (debit - credit);

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
      SELECT id, code, name 
      FROM accounts 
      WHERE id = ?
    ''';

    final accountResult = await db.rawQuery(accountQuery, [accountId]);
    if (accountResult.isEmpty) {
      throw Exception('Account not found');
    }

    final account = accountResult.first;

    String dateFilter = '';
    final args = <Object?>[accountId];
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
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
    );
    final totalDebits =
        (summaryResult.first['total_debits'] as num?)?.toDouble() ?? 0.0;
    final totalCredits =
        (summaryResult.first['total_credits'] as num?)?.toDouble() ?? 0.0;
    final closingBalance = openingBalance + (totalDebits - totalCredits);

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

  Future<double> _getOpeningBalance(int accountId, DateTime? beforeDate) async {
    if (beforeDate == null) return 0;

    final db = await databaseService.database;

    final query = '''
      SELECT 
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as balance
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE je.is_posted = 1 AND jel.account_id = ?
      AND je.entry_date < ?
    ''';

    final result = await db.rawQuery(query, [
      accountId,
      beforeDate.millisecondsSinceEpoch ~/ 1000,
    ]);
    if (result.isNotEmpty) {
      return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
    }
    return 0;
  }
}
