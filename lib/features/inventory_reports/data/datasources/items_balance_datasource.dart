import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/inventory_reports/data/models/items_balance_model.dart';

abstract class ItemsBalanceDataSource {
  Future<List<ItemsBalanceModel>> getBalances({
    int? warehouseId,
    String? searchQuery,
  });
}

class ItemsBalanceDataSourceImpl implements ItemsBalanceDataSource {
  final DatabaseService databaseService;

  ItemsBalanceDataSourceImpl({required this.databaseService});

  @override
  Future<List<ItemsBalanceModel>> getBalances({
    int? warehouseId,
    String? searchQuery,
  }) async {
    final db = await databaseService.database;
    final whereClauses = <String>['c.is_active = 1', 'c.is_deleted = 0'];
    final args = <Object?>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(c.name LIKE ? OR c.barcode_no LIKE ?)');
      args.addAll([q, q]);
    }

    // We add warehouse filter later via JOIN condition or WHERE on ws
    // For aggregated current quantity, we use warehouse_stocks
    // For inbound/outbound, we use stock_movements aggregation subqueries

    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    // Build inbound/outbound subqueries that respect warehouseId filter
    // If warehouseId is null -> aggregate across all warehouses
    // If not null -> filter by warehouse_id

    final inboundExpr = warehouseId != null
        ? "(SELECT COALESCE(SUM(CASE WHEN sm.quantity > 0 THEN sm.quantity ELSE 0 END),0) FROM stock_movements sm WHERE sm.product_id = c.id AND sm.warehouse_id = $warehouseId)"
        : "(SELECT COALESCE(SUM(CASE WHEN sm.quantity > 0 THEN sm.quantity ELSE 0 END),0) FROM stock_movements sm WHERE sm.product_id = c.id)";

    final outboundExpr = warehouseId != null
        ? "(SELECT COALESCE(SUM(CASE WHEN sm.quantity < 0 THEN -sm.quantity ELSE 0 END),0) FROM stock_movements sm WHERE sm.product_id = c.id AND sm.warehouse_id = $warehouseId)"
        : "(SELECT COALESCE(SUM(CASE WHEN sm.quantity < 0 THEN -sm.quantity ELSE 0 END),0) FROM stock_movements sm WHERE sm.product_id = c.id)";

    // Current quantity and cost: from warehouse_stocks
    final currentQtyExpr = warehouseId != null
        ? "COALESCE((SELECT ws.quantity FROM warehouse_stocks ws WHERE ws.product_id = c.id AND ws.warehouse_id = $warehouseId LIMIT 1), 0)"
        : "COALESCE((SELECT SUM(ws.quantity) FROM warehouse_stocks ws WHERE ws.product_id = c.id), 0)";

    final unitCostExpr = warehouseId != null
        ? "COALESCE((SELECT ws.avg_cost FROM warehouse_stocks ws WHERE ws.product_id = c.id AND ws.warehouse_id = $warehouseId LIMIT 1), c.cost_amount, 0)"
        : "COALESCE((SELECT AVG(ws.avg_cost) FROM warehouse_stocks ws WHERE ws.product_id = c.id AND ws.quantity > 0), c.cost_amount, 0)";

    final warehouseIdSelect = warehouseId != null ? "$warehouseId as warehouse_id" : "NULL as warehouse_id";
    final warehouseNameSelect = warehouseId != null
        ? "(SELECT name FROM stocks WHERE id = $warehouseId) as warehouse_name"
        : "NULL as warehouse_name";

    final query = '''
      SELECT
        c.id as product_id,
        c.name as product_name,
        c.barcode_no as product_code,
        COALESCE(cu.name, 'حبة') as unit_name,
        $currentQtyExpr as current_quantity,
        $inboundExpr as total_inbound,
        $outboundExpr as total_outbound,
        $unitCostExpr as unit_cost,
        ($currentQtyExpr * $unitCostExpr) as total_value,
        $warehouseIdSelect,
        $warehouseNameSelect
      FROM categories c
      LEFT JOIN categories_units cu ON cu.id = c.unit_id
      $whereSql
      ORDER BY c.name ASC
    ''';

    final rows = await db.rawQuery(query, args);
    // Filter out zero-balance items? Spec shows only items with movement, but we show all with any stock/movement
    // Keep all active products but if both current and inbound/outbound zero and warehouse filter null, we hide empty rows
    final filtered = rows.where((r) {
      final cur = (r['current_quantity'] as num?)?.toDouble() ?? 0;
      final inn = (r['total_inbound'] as num?)?.toDouble() ?? 0;
      final out = (r['total_outbound'] as num?)?.toDouble() ?? 0;
      // Show if has any quantity or movement
      return cur != 0 || inn != 0 || out != 0;
    }).toList();

    // If still empty and no warehouse filter, show at least products with stock from warehouse_stocks (already filtered)
    // If searchQuery is present, filtered already respects it via whereClauses
    return filtered.map((m) => ItemsBalanceModel.fromMap(m)).toList();
  }
}
