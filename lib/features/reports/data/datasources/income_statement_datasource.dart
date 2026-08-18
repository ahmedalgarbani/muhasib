import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/income_statement_model.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
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

  /// Calculate the previous period dates based on current period
  ReportFilter _getPreviousPeriodFilter(ReportFilter filter) {
    if (filter.startDate == null || filter.endDate == null) {
      return ReportFilter();
    }

    final duration = filter.endDate!.difference(filter.startDate!);
    final previousStart = filter.startDate!.subtract(
      duration + const Duration(days: 1),
    );
    final previousEnd = filter.startDate!.subtract(const Duration(days: 1));

    return ReportFilter(startDate: previousStart, endDate: previousEnd);
  }

  @override
  Future<List<IncomeStatementEntity>> getIncomeStatementData({
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    String dateFilter = '';
    final args = <Object?>[];
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('je.entry_date');
      dateFilter = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }

    final List<IncomeStatementEntity> categories = [];

    // Reference type exclusion for opening/closing entries
    const referenceExclusion =
        "AND COALESCE(je.reference_type, '') NOT IN ('opening_entry', 'opening_balance', 'closing')";

    // ==================== REVENUE SECTION ====================
    // Revenue accounts: type = 4 or code starting with '4'
    final revenueQuery =
        '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE (a.type = 4 OR a.code LIKE '4%') AND a.is_active = 1 AND je.is_posted = 1
        AND NOT (a.code LIKE '42%' OR a.code LIKE '43%' OR a.name LIKE '%أرباح%' OR a.name LIKE '%إيرادات أخرى%' OR a.name LIKE '%فروق صرف%')
      $referenceExclusion
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final revenueResult = await db.rawQuery(revenueQuery, args);
    if (revenueResult.isNotEmpty) {
      final items = revenueResult
          .map((row) => IncomeStatementLineItemModel.fromMap(row))
          .toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);

      categories.add(
        IncomeStatementModel(
          categoryCode: '4',
          categoryName: 'الإيرادات',
          items: items,
          totalAmount: total,
        ),
      );
    }

    // ==================== OTHER INCOME ====================
    final otherIncomeQuery =
        '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.credit_amount - jel.debit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE (a.type = 4 OR a.code LIKE '4%') AND a.is_active = 1 AND je.is_posted = 1
        AND (
          a.code LIKE '42%' OR 
          a.code LIKE '43%' OR
          a.name LIKE '%أرباح%' OR
          a.name LIKE '%إيرادات أخرى%' OR
          a.name LIKE '%فروق صرف%'
        )
      $referenceExclusion
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final otherIncomeResult = await db.rawQuery(otherIncomeQuery, args);
    if (otherIncomeResult.isNotEmpty) {
      final items = otherIncomeResult
          .map((row) => IncomeStatementLineItemModel.fromMap(row))
          .toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);

      categories.add(
        IncomeStatementModel(
          categoryCode: '42',
          categoryName: 'إيرادات أخرى',
          items: items,
          totalAmount: total,
        ),
      );
    }

    // ==================== COST OF SALES ====================
    // Cost of Sales: purchases/COGS accounts (type = 3 or code 3xxx, c_id in 3110, 3190, 3160)
    final costOfSalesQuery =
        '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE (a.type = 3 OR a.code LIKE '3%') AND (a.c_id IN (3110, 3190, 3160) OR a.code LIKE '311%' OR a.code LIKE '3001%' OR a.code LIKE '3008%' OR a.code LIKE '3009%' OR a.name LIKE '%مشتريات%' OR a.name LIKE '%تكلفة البضاعة%') AND a.is_active = 1 AND je.is_posted = 1
      $referenceExclusion
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final costOfSalesResult = await db.rawQuery(costOfSalesQuery, args);
    if (costOfSalesResult.isNotEmpty) {
      final items = costOfSalesResult
          .map((row) => IncomeStatementLineItemModel.fromMap(row))
          .toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);

      categories.add(
        IncomeStatementModel(
          categoryCode: '311',
          categoryName: 'تكلفة المبيعات',
          items: items,
          totalAmount: total,
        ),
      );
    }

    // ==================== OPERATING EXPENSES ====================
    final operatingExpensesQuery =
        '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE (a.type = 3 OR a.code LIKE '3%') AND (
        a.c_id IN (3120, 3130, 3140, 3150, 3170, 3180) OR
        a.code LIKE '312%' OR
        a.code LIKE '313%' OR
        a.code LIKE '314%' OR
        a.code LIKE '315%' OR
        a.code LIKE '3002%' OR
        a.code LIKE '3003%' OR
        a.code LIKE '3004%' OR
        a.code LIKE '3005%' OR
        a.code LIKE '3006%' OR
        a.code LIKE '3007%'
      ) AND a.is_active = 1 AND je.is_posted = 1
      $referenceExclusion
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final operatingExpensesResult = await db.rawQuery(
      operatingExpensesQuery,
      args,
    );
    if (operatingExpensesResult.isNotEmpty) {
      final items = operatingExpensesResult
          .map((row) => IncomeStatementLineItemModel.fromMap(row))
          .toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);

      categories.add(
        IncomeStatementModel(
          categoryCode: '31x',
          categoryName: 'المصروفات التشغيلية',
          items: items,
          totalAmount: total,
        ),
      );
    }

    // ==================== OTHER EXPENSES ====================
    final otherExpensesQuery =
        '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE (a.type = 3 OR a.code LIKE '3%') AND a.is_active = 1 AND je.is_posted = 1
        AND a.c_id NOT IN (3110, 3190, 3120, 3130, 3140, 3150, 3160, 3170, 3180)
        AND a.code NOT LIKE '311%' AND a.code NOT LIKE '3001%' AND a.code NOT LIKE '3008%'
        AND a.code NOT LIKE '312%' AND a.code NOT LIKE '3002%'
        AND a.code NOT LIKE '313%' AND a.code NOT LIKE '3003%'
        AND a.code NOT LIKE '314%' AND a.code NOT LIKE '3004%'
        AND a.code NOT LIKE '315%' AND a.code NOT LIKE '3005%'
        AND a.code NOT LIKE '316%'
        AND a.name NOT LIKE '%ضريبة الدخل%'
        AND a.name NOT LIKE '%ضريبة أرباح%'
        AND a.name NOT LIKE '%مشتريات%'
        AND a.name NOT LIKE '%تكلفة البضاعة%'
      $referenceExclusion
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final otherExpensesResult = await db.rawQuery(otherExpensesQuery, args);
    if (otherExpensesResult.isNotEmpty) {
      final items = otherExpensesResult
          .map((row) => IncomeStatementLineItemModel.fromMap(row))
          .toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);

      categories.add(
        IncomeStatementModel(
          categoryCode: '3xx',
          categoryName: 'مصروفات أخرى',
          items: items,
          totalAmount: total,
        ),
      );
    }

    // ==================== TAX EXPENSE ====================
    final taxExpenseQuery =
        '''
      SELECT 
        a.id as account_id,
        a.code as account_code,
        a.name as account_name,
        COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE (a.type = 3 OR a.code LIKE '3%') AND a.is_active = 1 AND je.is_posted = 1
        AND (
          a.name LIKE '%ضريبة الدخل%' OR
          a.name LIKE '%ضريبة أرباح%'
        )
      $referenceExclusion
      $dateFilter
      GROUP BY a.id, a.code, a.name
      HAVING amount != 0
      ORDER BY a.code
    ''';

    final taxExpenseResult = await db.rawQuery(taxExpenseQuery, args);
    if (taxExpenseResult.isNotEmpty) {
      final items = taxExpenseResult
          .map((row) => IncomeStatementLineItemModel.fromMap(row))
          .toList();
      final total = items.fold<double>(0, (sum, item) => sum + item.amount);

      categories.add(
        IncomeStatementModel(
          categoryCode: '316',
          categoryName: 'ضريبة الدخل',
          items: items,
          totalAmount: total,
        ),
      );
    }

    return categories;
  }

  @override
  Future<IncomeStatementSummary> getIncomeStatementSummary({
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    // Get current period summary
    final currentSummary = await _getPeriodSummary(db, filter);

    // Get previous period summary for comparison
    final previousFilter = _getPreviousPeriodFilter(filter);
    final previousSummary = await _getPeriodSummary(db, previousFilter);

    return IncomeStatementSummary(
      totalRevenue: currentSummary['revenue'] ?? 0,
      totalCostOfSales: currentSummary['cost_of_sales'] ?? 0,
      grossProfit: currentSummary['gross_profit'] ?? 0,
      totalOperatingExpenses: currentSummary['operating_expenses'] ?? 0,
      operatingIncome: currentSummary['operating_income'] ?? 0,
      totalOtherIncome: currentSummary['other_income'] ?? 0,
      totalOtherExpenses: currentSummary['other_expenses'] ?? 0,
      netIncomeBeforeTax: currentSummary['net_income_before_tax'] ?? 0,
      taxExpense: currentSummary['tax_expense'] ?? 0,
      netIncome: currentSummary['net_income'] ?? 0,
      previousTotalRevenue: previousSummary['revenue'],
      previousNetIncome: previousSummary['net_income'],
    );
  }

  Future<Map<String, double>> _getPeriodSummary(
    dynamic db,
    ReportFilter filter,
  ) async {
    String dateFilter = '';
    final args = <Object?>[];
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('je.entry_date');
      dateFilter = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }

    // Reference type exclusion for opening/closing entries
    const referenceExclusion =
        "AND COALESCE(je.reference_type, '') NOT IN ('opening_entry', 'opening_balance', 'closing')";

    // Summary query with standard categories
    final summaryQuery =
        '''
      SELECT 
        CASE 
          WHEN (a.type = 4 OR a.code LIKE '4%') AND (a.code LIKE '42%' OR a.code LIKE '43%' OR a.name LIKE '%أرباح%' OR a.name LIKE '%إيرادات أخرى%' OR a.name LIKE '%فروق صرف%') THEN 'other_income'
          WHEN (a.type = 4 OR a.code LIKE '4%') THEN 'revenue'
          WHEN (a.type = 3 OR a.code LIKE '3%') AND (a.c_id IN (3110, 3190, 3160) OR a.code LIKE '311%' OR a.code LIKE '3001%' OR a.code LIKE '3008%' OR a.code LIKE '3009%' OR a.name LIKE '%مشتريات%' OR a.name LIKE '%تكلفة البضاعة%') THEN 'cost_of_sales'
          WHEN (a.type = 3 OR a.code LIKE '3%') AND (
            a.c_id IN (3120, 3130, 3140, 3150, 3170, 3180) OR
            a.code LIKE '312%' OR
            a.code LIKE '313%' OR
            a.code LIKE '314%' OR
            a.code LIKE '315%' OR
            a.code LIKE '3002%' OR
            a.code LIKE '3003%' OR
            a.code LIKE '3004%' OR
            a.code LIKE '3005%' OR
            a.code LIKE '3006%' OR
            a.code LIKE '3007%'
          ) THEN 'operating_expenses'
          WHEN (a.type = 3 OR a.code LIKE '3%') AND (a.name LIKE '%ضريبة الدخل%' OR a.name LIKE '%ضريبة أرباح%') THEN 'tax_expense'
          WHEN (a.type = 3 OR a.code LIKE '3%') THEN 'other_expenses'
          ELSE 'other'
        END as category,
        COALESCE(SUM(
          CASE 
            WHEN (a.type = 4 OR a.code LIKE '4%') THEN jel.credit_amount - jel.debit_amount
            WHEN (a.type = 3 OR a.code LIKE '3%') THEN jel.debit_amount - jel.credit_amount
            ELSE 0
          END
        ), 0) as amount
      FROM accounts a
      INNER JOIN journal_entry_lines jel ON a.id = jel.account_id
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1 AND (a.type = 4 OR a.type = 3 OR a.code LIKE '4%' OR a.code LIKE '3%')
      $referenceExclusion
      $dateFilter
      GROUP BY category
    ''';

    final result = await db.rawQuery(summaryQuery, args);

    double totalRevenue = 0;
    double totalOtherIncome = 0;
    double totalCostOfSales = 0;
    double totalOperatingExpenses = 0;
    double totalOtherExpenses = 0;
    double taxExpense = 0;

    for (final row in result) {
      final category = row['category'] as String?;
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;

      switch (category) {
        case 'revenue':
          totalRevenue += amount;
          break;
        case 'other_income':
          totalOtherIncome += amount;
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
        case 'tax_expense':
          taxExpense += amount;
          break;
      }
    }

    // Calculate derived values
    final grossProfit = totalRevenue - totalCostOfSales;
    final operatingIncome =
        grossProfit - totalOperatingExpenses + totalOtherIncome;
    final netIncomeBeforeTax = operatingIncome - totalOtherExpenses;
    final netIncome = netIncomeBeforeTax - taxExpense;

    return {
      'revenue': totalRevenue,
      'other_income': totalOtherIncome,
      'cost_of_sales': totalCostOfSales,
      'gross_profit': grossProfit,
      'operating_expenses': totalOperatingExpenses,
      'operating_income': operatingIncome,
      'other_expenses': totalOtherExpenses,
      'net_income_before_tax': netIncomeBeforeTax,
      'tax_expense': taxExpense,
      'net_income': netIncome,
    };
  }
}
