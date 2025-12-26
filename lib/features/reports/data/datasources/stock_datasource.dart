import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/data/models/stock_model.dart';
import 'package:muhasib/features/reports/domain/entities/stock_entity.dart';

abstract class StockDataSource {
  Future<List<StockModel>> getStockReport({
    int? warehouseId,
    String? searchQuery,
    String? categoryId,
  });

  Future<StockSummary> getStockSummary({
    int? warehouseId,
  });
}

class StockDataSourceImpl implements StockDataSource {
  final DatabaseService databaseService;

  StockDataSourceImpl({required this.databaseService});

  @override
  Future<List<StockModel>> getStockReport({
    int? warehouseId,
    String? searchQuery,
    String? categoryId,
  }) async {
    final db = await databaseService.database;

    final where = <String>['c.is_active = 1'];
    final args = <Object?>[];

    if (warehouseId != null) {
      where.add('c.stock_id = ?');
      args.add(warehouseId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(c.name LIKE ? OR c.barcode_no LIKE ?)');
      final pattern = '%$searchQuery%';
      args.addAll([pattern, pattern]);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      // In this codebase, "category" for products is categories_groups.id
      where.add('c.group_id = ?');
      args.add(int.tryParse(categoryId));
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final query = '''
      SELECT 
        c.id as product_id,
        c.barcode_no as product_code,
        c.name as product_name,
        cg.name as category_name,
        cu.name as unit_name,
        COALESCE(c.quantity, 0) as current_stock,
        COALESCE(c.min_stock_level, 0) as min_stock,
        COALESCE(c.max_stock_level, 999999) as max_stock,
        COALESCE(c.cost_amount, 0) as cost_price,
        COALESCE(c.sell_amount, 0) as sale_price,
        COALESCE(c.quantity * c.cost_amount, 0) as stock_value,
        c.stock_id as warehouse_id,
        s.name as warehouse_name,
        (
          SELECT datetime(MAX(cm.trans_date), 'unixepoch')
          FROM category_movs cm
          WHERE cm.category_id = c.id
        ) as last_movement_date
      FROM categories c
      LEFT JOIN categories_groups cg ON c.group_id = cg.id
      LEFT JOIN categories_units cu ON c.unit_id = cu.id
      LEFT JOIN stocks s ON c.stock_id = s.id
      $whereClause
      ORDER BY c.name
    ''';

    final result = await db.rawQuery(query, args);
    
    return result.map((map) => StockModel.fromMap(map)).toList();
  }

  @override
  Future<StockSummary> getStockSummary({
    int? warehouseId,
  }) async {
    final db = await databaseService.database;

    final where = <String>['c.is_active = 1'];
    final args = <Object?>[];
    if (warehouseId != null) {
      where.add('c.stock_id = ?');
      args.add(warehouseId);
    }
    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final query = '''
      SELECT 
        COUNT(DISTINCT c.id) as total_products,
        COALESCE(SUM(c.quantity), 0) as total_quantity,
        COALESCE(SUM(c.quantity * c.cost_amount), 0) as total_stock_value,
        COUNT(DISTINCT CASE WHEN c.quantity <= COALESCE(c.min_stock_level, 0) AND c.quantity > 0 THEN c.id END) as low_stock_count,
        COUNT(DISTINCT CASE WHEN c.max_stock_level IS NOT NULL AND c.quantity >= c.max_stock_level THEN c.id END) as over_stock_count,
        COUNT(DISTINCT CASE WHEN c.quantity <= 0 THEN c.id END) as out_of_stock_count
      FROM categories c
      $whereClause
    ''';

    final result = await db.rawQuery(query, args);
    
    if (result.isNotEmpty) {
      final row = result.first;
      return StockSummary(
        totalStockValue: (row['total_stock_value'] as num?)?.toDouble() ?? 0.0,
        totalProducts: (row['total_products'] as int?) ?? 0,
        totalQuantity: (row['total_quantity'] as num?)?.toDouble() ?? 0.0,
        lowStockCount: (row['low_stock_count'] as int?) ?? 0,
        overStockCount: (row['over_stock_count'] as int?) ?? 0,
        outOfStockCount: (row['out_of_stock_count'] as int?) ?? 0,
      );
    }

    return const StockSummary(
      totalStockValue: 0,
      totalProducts: 0,
      totalQuantity: 0,
      lowStockCount: 0,
      overStockCount: 0,
      outOfStockCount: 0,
    );
  }
}
