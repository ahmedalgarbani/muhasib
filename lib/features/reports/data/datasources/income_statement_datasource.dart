import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/income_statement_model.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/income_statement_entity.dart';

abstract class IncomeStatementDataSource {
  Future<List<IncomeStatementEntity>> getIncomeStatementData({
    required ReportFilter filter,
  });

  Future<IncomeStatementSummary> getIncomeStatementSummary({
    required ReportFilter filter,
  });
}

class IncomeStatementDataSourceImpl implements IncomeStatementDataSource {
  final DatabaseService databaseService;

  IncomeStatementDataSourceImpl({required this.databaseService});

  @override
  Future<List<IncomeStatementEntity>> getIncomeStatementData({
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

    final List<IncomeStatementEntity> categories = [];

    // Revenue: accounts.type = 4 (per seeders)
    final revenueQuery = '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.type = 4 AND a.is_active = 1 AND je.is_posted = 1
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final revenueResult = await db.rawQuery(revenueQuery, args);
    if (revenueResult.isNotEmpty) {
      final items = revenueResult.map((row) => IncomeStatementLineItemModel.fromMap(row)).toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);
      
      categories.add(IncomeStatementEntity(
        categoryCode: '4',
        categoryName: 'الإيرادات',
        items: items,
        totalAmount: total,
      ));
    }

    // Expenses: accounts.type = 3 (per seeders)
    // Cost of Sales approximation: purchases accounts (code starts with '311')
    final costOfSalesQuery = '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.type = 3 AND a.code LIKE '311%' AND a.is_active = 1 AND je.is_posted = 1
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final costOfSalesResult = await db.rawQuery(costOfSalesQuery, args);
    if (costOfSalesResult.isNotEmpty) {
      final items = costOfSalesResult.map((row) => IncomeStatementLineItemModel.fromMap(row)).toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);
      
      categories.add(IncomeStatementEntity(
        categoryCode: '311',
        categoryName: 'تكلفة المبيعات',
        items: items,
        totalAmount: total,
      ));
    }

    // Operating Expenses approximation: common expense accounts (312-315)
    final operatingExpensesQuery = '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.type = 3 AND (
        a.code LIKE '312%' OR
        a.code LIKE '313%' OR
        a.code LIKE '314%' OR
        a.code LIKE '315%'
      ) AND a.is_active = 1 AND je.is_posted = 1
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final operatingExpensesResult = await db.rawQuery(operatingExpensesQuery, args);
    if (operatingExpensesResult.isNotEmpty) {
      final items = operatingExpensesResult.map((row) => IncomeStatementLineItemModel.fromMap(row)).toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);
      
      categories.add(IncomeStatementEntity(
        categoryCode: '31x',
        categoryName: 'المصروفات التشغيلية',
        items: items,
        totalAmount: total,
      ));
    }

    // Other Expenses: remaining expenses (type=3) not included above
    final otherExpensesQuery = '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.type = 3 AND a.is_active = 1 AND je.is_posted = 1
        AND a.code NOT LIKE '311%'
        AND a.code NOT LIKE '312%'
        AND a.code NOT LIKE '313%'
        AND a.code NOT LIKE '314%'
        AND a.code NOT LIKE '315%'
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final otherExpensesResult = await db.rawQuery(otherExpensesQuery, args);
    if (otherExpensesResult.isNotEmpty) {
      final items = otherExpensesResult.map((row) => IncomeStatementLineItemModel.fromMap(row)).toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);
      
      categories.add(IncomeStatementEntity(
        categoryCode: '3',
        categoryName: 'المصروفات الأخرى',
        items: items,
        totalAmount: total,
      ));
    }

    return categories;
  }

  @override
  Future<IncomeStatementSummary> getIncomeStatementSummary({
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

    // Get totals for each category
    final summaryQuery = '''
      SELECT 
        CASE 
          WHEN a.type = 4 THEN 'revenue'
          WHEN a.type = 3 AND a.code LIKE '311%' THEN 'cost_of_sales'
          WHEN a.type = 3 AND (
            a.code LIKE '312%' OR
            a.code LIKE '313%' OR
            a.code LIKE '314%' OR
            a.code LIKE '315%'
          ) THEN 'operating_expenses'
          WHEN a.type = 3 THEN 'other_expenses'
          ELSE 'other'
        END as category,
        COALESCE(SUM(
          CASE 
            WHEN a.type = 4 THEN jel.credit_amount - jel.debit_amount
            WHEN a.type = 3 THEN jel.debit_amount - jel.credit_amount
            ELSE 0
          END
        ), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1 AND (a.type = 4 OR a.type = 3)
      $dateFilter
      GROUP BY category
    ''';

    final result = await db.rawQuery(summaryQuery, args);
    
    double totalRevenue = 0;
    double totalCostOfSales = 0;
    double totalOperatingExpenses = 0;
    double totalOtherExpenses = 0;

    for (final row in result) {
      final category = row['category'] as String?;
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;

      switch (category) {
        case 'revenue':
          totalRevenue += amount;
          break;
        case 'cost_of_sales':
          totalCostOfSales += amount;
          break;
        case 'operating_expenses':
          totalOperatingExpenses += amount;
          break;
        case 'other_expenses':
          totalOtherExpenses += amount;
          break;
      }
    }

    final grossProfit = totalRevenue - totalCostOfSales;
    final operatingIncome = grossProfit - totalOperatingExpenses;
    final netIncomeBeforeTax = operatingIncome - totalOtherExpenses;
    // For now, tax is 0 - can be enhanced to calculate from tax accounts
    const taxExpense = 0.0;
    final netIncome = netIncomeBeforeTax - taxExpense;

    return IncomeStatementSummary(
      totalRevenue: totalRevenue,
      totalCostOfSales: totalCostOfSales,
      grossProfit: grossProfit,
      totalOperatingExpenses: totalOperatingExpenses,
      operatingIncome: operatingIncome,
      totalOtherIncome: 0, // Can be enhanced to include other income accounts
      totalOtherExpenses: totalOtherExpenses,
      netIncomeBeforeTax: netIncomeBeforeTax,
      taxExpense: taxExpense,
      netIncome: netIncome,
    );
  }
}
