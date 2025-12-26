import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/trial_balance_model.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/trial_balance_entity.dart';

abstract class TrialBalanceDataSource {
  Future<List<TrialBalanceModel>> getTrialBalance({
    required ReportFilter filter,
  });

  Future<TrialBalanceSummary> getTrialBalanceSummary({
    required ReportFilter filter,
  });
}

class TrialBalanceDataSourceImpl implements TrialBalanceDataSource {
  final DatabaseService databaseService;

  TrialBalanceDataSourceImpl({required this.databaseService});

  @override
  Future<List<TrialBalanceModel>> getTrialBalance({
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    String dateFilter = '';
    final args = <Object?>[];
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final query = '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        a.type as account_type,
        COALESCE(SUM(CASE WHEN jel.debit_amount > 0 THEN jel.debit_amount ELSE 0 END), 0) as debit_balance,
        COALESCE(SUM(CASE WHEN jel.credit_amount > 0 THEN jel.credit_amount ELSE 0 END), 0) as credit_balance
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1
      $dateFilter
      GROUP BY a.id, a.code, a.name, a.type
      HAVING (debit_balance > 0 OR credit_balance > 0)
      ORDER BY a.code
    ''';

    final result = await db.rawQuery(query, args);
    
    return result.map((map) => TrialBalanceModel.fromMap(map)).toList();
  }

  @override
  Future<TrialBalanceSummary> getTrialBalanceSummary({
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    String dateFilter = '';
    final args = <Object?>[];
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final query = '''
      SELECT 
        COALESCE(SUM(jel.debit_amount), 0) as total_debit,
        COALESCE(SUM(jel.credit_amount), 0) as total_credit
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE a.is_active = 1 AND je.is_posted = 1
      $dateFilter
    ''';

    final result = await db.rawQuery(query, args);
    
    if (result.isNotEmpty) {
      final totalDebit = (result.first['total_debit'] as num?)?.toDouble() ?? 0.0;
      final totalCredit = (result.first['total_credit'] as num?)?.toDouble() ?? 0.0;
      
      return TrialBalanceSummary(
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        difference: totalDebit - totalCredit,
      );
    }

    return const TrialBalanceSummary(
      totalDebit: 0,
      totalCredit: 0,
      difference: 0,
    );
  }
}
