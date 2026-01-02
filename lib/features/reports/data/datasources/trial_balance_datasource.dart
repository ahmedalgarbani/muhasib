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

    // Get start and end dates for the period
    final startDate = filter.startDate != null 
        ? filter.startDate!.millisecondsSinceEpoch ~/ 1000 
        : 0;
    final endDate = filter.endDate != null 
        ? filter.endDate!.millisecondsSinceEpoch ~/ 1000 
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Enhanced query to calculate:
    // 1. Opening balance (all posted entries BEFORE the period start date)
    // 2. Period movements (all posted entries WITHIN the date range)
    // 3. Closing balance (opening + period movements)
    final query = '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        a.type as account_type,
        
        -- Opening Balance (before period start)
        COALESCE(SUM(CASE 
          WHEN je.entry_date < ? 
          THEN jel.debit_amount 
          ELSE 0 
        END), 0) as opening_debit,
        COALESCE(SUM(CASE 
          WHEN je.entry_date < ? 
          THEN jel.credit_amount 
          ELSE 0 
        END), 0) as opening_credit,
        
        -- Period Movements (within date range)
        COALESCE(SUM(CASE 
          WHEN je.entry_date >= ? AND je.entry_date <= ? 
          THEN jel.debit_amount 
          ELSE 0 
        END), 0) as period_debit,
        COALESCE(SUM(CASE 
          WHEN je.entry_date >= ? AND je.entry_date <= ? 
          THEN jel.credit_amount 
          ELSE 0 
        END), 0) as period_credit,
        
        -- Closing Balance (all entries up to period end)
        COALESCE(SUM(CASE 
          WHEN je.entry_date <= ? 
          THEN jel.debit_amount 
          ELSE 0 
        END), 0) as closing_debit,
        COALESCE(SUM(CASE 
          WHEN je.entry_date <= ? 
          THEN jel.credit_amount 
          ELSE 0 
        END), 0) as closing_credit
        
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1
      GROUP BY a.id, a.code, a.name, a.type
      HAVING (
        opening_debit > 0 OR opening_credit > 0 OR
        period_debit > 0 OR period_credit > 0 OR
        closing_debit > 0 OR closing_credit > 0
      )
      ORDER BY a.code
    ''';

    final args = [
      startDate,  // opening_debit before
      startDate,  // opening_credit before
      startDate,  // period_debit from
      endDate,    // period_debit to
      startDate,  // period_credit from
      endDate,    // period_credit to
      endDate,    // closing_debit up to
      endDate,    // closing_credit up to
    ];

    final result = await db.rawQuery(query, args);
    
    return result.map((map) => TrialBalanceModel.fromMap(map)).toList();
  }

  @override
  Future<TrialBalanceSummary> getTrialBalanceSummary({
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    final startDate = filter.startDate != null 
        ? filter.startDate!.millisecondsSinceEpoch ~/ 1000 
        : 0;
    final endDate = filter.endDate != null 
        ? filter.endDate!.millisecondsSinceEpoch ~/ 1000 
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final query = '''
      SELECT 
        -- Opening totals
        COALESCE(SUM(CASE WHEN je.entry_date < ? THEN jel.debit_amount ELSE 0 END), 0) as opening_debit,
        COALESCE(SUM(CASE WHEN je.entry_date < ? THEN jel.credit_amount ELSE 0 END), 0) as opening_credit,
        
        -- Period totals
        COALESCE(SUM(CASE WHEN je.entry_date >= ? AND je.entry_date <= ? THEN jel.debit_amount ELSE 0 END), 0) as period_debit,
        COALESCE(SUM(CASE WHEN je.entry_date >= ? AND je.entry_date <= ? THEN jel.credit_amount ELSE 0 END), 0) as period_credit,
        
        -- Closing totals
        COALESCE(SUM(CASE WHEN je.entry_date <= ? THEN jel.debit_amount ELSE 0 END), 0) as closing_debit,
        COALESCE(SUM(CASE WHEN je.entry_date <= ? THEN jel.credit_amount ELSE 0 END), 0) as closing_credit
        
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE a.is_active = 1 AND je.is_posted = 1
    ''';

    final args = [
      startDate, startDate,           // opening
      startDate, endDate, startDate, endDate,  // period
      endDate, endDate,               // closing
    ];

    final result = await db.rawQuery(query, args);
    
    if (result.isNotEmpty) {
      final row = result.first;
      return TrialBalanceSummary(
        openingDebit: (row['opening_debit'] as num?)?.toDouble() ?? 0.0,
        openingCredit: (row['opening_credit'] as num?)?.toDouble() ?? 0.0,
        periodDebit: (row['period_debit'] as num?)?.toDouble() ?? 0.0,
        periodCredit: (row['period_credit'] as num?)?.toDouble() ?? 0.0,
        closingDebit: (row['closing_debit'] as num?)?.toDouble() ?? 0.0,
        closingCredit: (row['closing_credit'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return const TrialBalanceSummary();
  }
}
