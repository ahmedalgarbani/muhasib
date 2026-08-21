import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/inventory_reports/data/models/product_price_report_model.dart';

abstract class ProductPriceReportDataSource {
  Future<List<ProductPriceReportModel>> getPrices({
    List<int>? productIds,
    String? searchQuery,
  });
}

class ProductPriceReportDataSourceImpl implements ProductPriceReportDataSource {
  final DatabaseService databaseService;

  ProductPriceReportDataSourceImpl({required this.databaseService});

  @override
  Future<List<ProductPriceReportModel>> getPrices({
    List<int>? productIds,
    String? searchQuery,
  }) async {
    final db = await databaseService.database;

    final whereClauses = <String>['c.is_active = 1', 'c.is_deleted = 0'];
    final args = <Object?>[];

    if (productIds != null && productIds.isNotEmpty) {
      final placeholders = List.filled(productIds.length, '?').join(',');
      whereClauses.add('c.id IN ($placeholders)');
      args.addAll(productIds);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(c.name LIKE ? OR c.barcode_no LIKE ?)');
      args.addAll([q, q]);
    }

    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    // Prices: retail = c.sell_amount, wholesale = price_level 2, min = price_level 3 or 4
    // categories_prices is linked via category_sub_units
    final query = '''
      SELECT
        c.id as product_id,
        c.name as product_name,
        c.barcode_no as barcode_no,
        COALESCE(cu.name, 'حبة') as unit_name,
        COALESCE(c.sell_amount, 0) as retail_price,
        COALESCE((
          SELECT cp.bid_amount
          FROM category_sub_units csu
          JOIN categories_prices cp ON cp.category_sub_unit_id = csu.id
          WHERE csu.category_id = c.id AND cp.price_level = 2
          ORDER BY cp.min_quantity ASC
          LIMIT 1
        ), 0) as wholesale_price,
        COALESCE((
          SELECT cp.bid_amount
          FROM category_sub_units csu
          JOIN categories_prices cp ON cp.category_sub_unit_id = csu.id
          WHERE csu.category_id = c.id AND cp.price_level IN (3,4)
          ORDER BY cp.price_level ASC, cp.bid_amount ASC
          LIMIT 1
        ), COALESCE(c.sell_amount, 0)) as min_price
      FROM categories c
      LEFT JOIN categories_units cu ON cu.id = c.unit_id
      $whereSql
      ORDER BY c.name ASC
    ''';

    final rows = await db.rawQuery(query, args);
    return rows.map((m) => ProductPriceReportModel.fromMap(m)).toList();
  }
}
