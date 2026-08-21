import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/domain/entities/sales_summary_entity.dart';

abstract class SalesSummaryDataSource {
  Future<SalesSummaryEntity> getSalesSummary({required ReportFilter filter});
}

class SalesSummaryDataSourceImpl implements SalesSummaryDataSource {
  final DatabaseService databaseService;

  SalesSummaryDataSourceImpl({required this.databaseService});

  @override
  Future<SalesSummaryEntity> getSalesSummary({
    required ReportFilter filter,
  }) async {
    final db = await databaseService.database;

    String dateFilter = '';
    final args = <Object?>[];
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('i.date');
      dateFilter = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }

    // Get sales totals
    final salesQuery =
        '''
      SELECT 
        COUNT(CASE WHEN i.invoice_type = 1 THEN 1 END) as invoice_count,
        COUNT(CASE WHEN i.invoice_type = 4 THEN 1 END) as return_count,
        COALESCE(SUM(CASE WHEN i.invoice_type = 1 THEN COALESCE(i.final_amt, i.total_amount, i.amount) END), 0) as total_sales,
        COALESCE(SUM(CASE WHEN i.invoice_type = 4 THEN COALESCE(i.final_amt, i.total_amount, i.amount) END), 0) as total_returns,
        COALESCE(SUM(CASE WHEN i.invoice_type = 1 THEN COALESCE(i.discount_amt, 0) END), 0) as total_discounts,
        COALESCE(SUM(CASE WHEN i.invoice_type = 1 THEN COALESCE(i.tax_amt, 0) END), 0) as total_taxes,
        COUNT(DISTINCT i.customer_id) as customer_count
      FROM invoices i
      WHERE (i.invoice_type = 1 OR i.invoice_type = 4)
        AND COALESCE(i.approval_status, 1) != 3
      $dateFilter
    ''';

    final salesResult = await db.rawQuery(salesQuery, args);

    double totalSales = 0;
    double totalReturns = 0;
    double totalDiscounts = 0;
    double totalTaxes = 0;
    int invoiceCount = 0;
    int returnCount = 0;
    int customerCount = 0;

    if (salesResult.isNotEmpty) {
      final row = salesResult.first;
      totalSales = (row['total_sales'] as num?)?.toDouble() ?? 0.0;
      totalReturns = (row['total_returns'] as num?)?.toDouble() ?? 0.0;
      totalDiscounts = (row['total_discounts'] as num?)?.toDouble() ?? 0.0;
      totalTaxes = (row['total_taxes'] as num?)?.toDouble() ?? 0.0;
      invoiceCount = (row['invoice_count'] ?? 0) as int;
      returnCount = (row['return_count'] ?? 0) as int;
      customerCount = (row['customer_count'] ?? 0) as int;
    }

    // Get top products
    final topProductsQuery =
        '''
      SELECT 
        c.id as product_id,
        c.name as product_name,
        SUM(il.quantity) as quantity,
        SUM(il.total_amount) as total_amount,
        COUNT(DISTINCT i.id) as sales_count
      FROM invoice_lines il
      INNER JOIN invoices i ON i.id = il.invoice_id
      LEFT JOIN categories c ON c.id = il.category_id
      WHERE i.invoice_type = 1
        AND COALESCE(i.approval_status, 1) != 3
      $dateFilter
      GROUP BY c.id, c.name
      ORDER BY total_amount DESC
      LIMIT 10
    ''';

    final topProductsResult = await db.rawQuery(topProductsQuery, args);
    final topProducts = topProductsResult
        .map(
          (row) => TopProductEntity(
            productId: row['product_id'] as int? ?? 0,
            productName: row['product_name'] as String? ?? 'صنف غير محدد',
            quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
            totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
            salesCount: row['sales_count'] as int,
          ),
        )
        .toList();

    // Get top customers
    final topCustomersQuery =
        '''
      SELECT 
        c.id as customer_id,
        c.name as customer_name,
        SUM(COALESCE(i.final_amt, i.total_amount, i.amount)) as total_purchases,
        COUNT(i.id) as invoice_count
      FROM invoices i
      INNER JOIN customers c ON c.id = i.customer_id
      WHERE i.invoice_type = 1
        AND COALESCE(i.approval_status, 1) != 3
      $dateFilter
      GROUP BY c.id, c.name
      ORDER BY total_purchases DESC
      LIMIT 10
    ''';

    final topCustomersResult = await db.rawQuery(topCustomersQuery, args);
    final topCustomers = topCustomersResult
        .map(
          (row) => TopCustomerEntity(
            customerId: row['customer_id'] as int,
            customerName: row['customer_name'] as String,
            totalPurchases: (row['total_purchases'] as num?)?.toDouble() ?? 0.0,
            invoiceCount: row['invoice_count'] as int,
          ),
        )
        .toList();

    // Get daily sales
    final dailySalesQuery =
        '''
      SELECT 
        date(${normalizedReportTimestampSql('i.date')}, 'unixepoch') as sale_date,
        SUM(COALESCE(i.final_amt, i.total_amount, i.amount)) as daily_total
      FROM invoices i
      WHERE i.invoice_type = 1
        AND COALESCE(i.approval_status, 1) != 3
      $dateFilter
      GROUP BY sale_date
      ORDER BY sale_date
    ''';

    final dailySalesResult = await db.rawQuery(dailySalesQuery, args);
    final dailySales = Map<String, double>.fromEntries(
      dailySalesResult.map(
        (row) => MapEntry(
          row['sale_date'] as String,
          (row['daily_total'] as num?)?.toDouble() ?? 0.0,
        ),
      ),
    );

    final netSales = totalSales - totalReturns;

    return SalesSummaryEntity(
      totalSales: totalSales,
      totalReturns: totalReturns,
      totalDiscounts: totalDiscounts,
      totalTaxes: totalTaxes,
      netSales: netSales,
      invoiceCount: invoiceCount,
      returnCount: returnCount,
      customerCount: customerCount,
      topProducts: topProducts,
      topCustomers: topCustomers,
      dailySales: dailySales,
    );
  }
}
