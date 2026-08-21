import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/inventory_reports/data/models/item_movement_model.dart';

abstract class ItemMovementDataSource {
  Future<List<ItemMovementModel>> getMovements({
    int? warehouseId,
    String? searchQuery,
    int? limit,
    int? offset,
  });

  Future<List<ItemMovementModel>> getMovementsByProduct(
    int productId, {
    int? warehouseId,
  });
}

class ItemMovementDataSourceImpl implements ItemMovementDataSource {
  final DatabaseService databaseService;

  ItemMovementDataSourceImpl({required this.databaseService});

  @override
  Future<List<ItemMovementModel>> getMovements({
    int? warehouseId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await databaseService.database;

    final whereClauses = <String>[];
    final args = <Object?>[];

    if (warehouseId != null) {
      whereClauses.add('sm.warehouse_id = ?');
      args.add(warehouseId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add(
          '(c.name LIKE ? OR c.barcode_no LIKE ? OR sm.reference_number LIKE ? OR sm.movement_type LIKE ?)');
      args.addAll([q, q, q, q]);
    }

    final whereSql =
        whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final limitSql = limit != null ? 'LIMIT $limit' : 'LIMIT 500';
    final offsetSql = offset != null ? 'OFFSET $offset' : '';

    // Primary source: stock_movements (single source of truth)
    // Fallback: if stock_movements empty, we also consider category_movs legacy
    // We UNION both with same shape, then order by creation_time DESC

    final query = '''
      SELECT
        sm.id as id,
        sm.product_id as product_id,
        COALESCE(c.name, 'صنف محذوف') as product_name,
        COALESCE(c.barcode_no, '') as product_code,
        COALESCE(mu.name, cu.name, 'حبة') as unit_name,
        sm.warehouse_id as warehouse_id,
        COALESCE(s.name, 'غير محدد') as warehouse_name,
        sm.movement_type as movement_type,
        sm.quantity as quantity,
        sm.original_quantity as original_quantity,
        sm.unit_id as unit_id,
        sm.conversion_rate as conversion_rate,
        sm.packaging as packaging,
        sm.unit_cost as unit_cost,
        sm.total_cost as total_cost,
        sm.balance_after as balance_after,
        sm.reference_type as reference_type,
        COALESCE(sm.reference_number, sm.reference_type, '') as reference_number,
        sm.creation_time as creation_time,
        sm.notes as notes
      FROM stock_movements sm
      LEFT JOIN categories c ON c.id = sm.product_id
      LEFT JOIN stocks s ON s.id = sm.warehouse_id
      LEFT JOIN categories_units cu ON cu.id = c.unit_id
      LEFT JOIN categories_units mu ON mu.id = sm.unit_id
      $whereSql
      ORDER BY sm.creation_time DESC, sm.id DESC
      $limitSql $offsetSql
    ''';

    try {
      final rows = await db.rawQuery(query, args);
      if (rows.isNotEmpty) {
        return rows.map((m) => ItemMovementModel.fromMap(m)).toList();
      }
      // Fallback to legacy category_movs if no stock_movements
      return _getLegacyMovements(
          warehouseId: warehouseId, searchQuery: searchQuery, limit: limit, offset: offset);
    } catch (e) {
      // If stock_movements table missing, fallback
      return _getLegacyMovements(
          warehouseId: warehouseId, searchQuery: searchQuery, limit: limit, offset: offset);
    }
  }

  Future<List<ItemMovementModel>> _getLegacyMovements({
    int? warehouseId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await databaseService.database;
    final whereClauses = <String>[];
    final args = <Object?>[];

    if (warehouseId != null) {
      whereClauses.add('cm.stock_id = ?');
      args.add(warehouseId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(c.name LIKE ? OR c.barcode_no LIKE ? OR cm.refrenc_no LIKE ?)');
      args.addAll([q, q, q]);
    }
    final whereSql =
        whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';
    final limitSql = limit != null ? 'LIMIT $limit' : 'LIMIT 500';
    final offsetSql = offset != null ? 'OFFSET $offset' : '';

    final query = '''
      SELECT
        (cm.doc_no * 10000 + cm.category_id) as id,
        cm.category_id as product_id,
        COALESCE(c.name, 'صنف محذوف') as product_name,
        COALESCE(c.barcode_no, '') as product_code,
        COALESCE(cu.name, 'حبة') as unit_name,
        cm.stock_id as warehouse_id,
        COALESCE(s.name, 'غير محدد') as warehouse_name,
        CASE cm.trans_doc_type
          WHEN 5 THEN 'transfer_out'
          WHEN 6 THEN 'adjustment'
          ELSE 'legacy'
        END as movement_type,
        CASE WHEN cm.trans_in_out = 1 THEN cm.quantity ELSE -cm.quantity END as quantity,
        COALESCE(cm.cost_amount, 0) as unit_cost,
        COALESCE(cm.cost_local_amount, 0) as total_cost,
        0 as balance_after,
        cm.refrenc_no as reference_number,
        'legacy' as reference_type,
        cm.trans_date as creation_time,
        cm.statement as notes
      FROM category_movs cm
      LEFT JOIN categories c ON c.id = cm.category_id
      LEFT JOIN stocks s ON s.id = cm.stock_id
      LEFT JOIN categories_units cu ON cu.id = c.unit_id
      $whereSql
      ORDER BY cm.trans_date DESC
      $limitSql $offsetSql
    ''';
    final rows = await db.rawQuery(query, args);
    return rows.map((m) => ItemMovementModel.fromMap(m)).toList();
  }

  @override
  Future<List<ItemMovementModel>> getMovementsByProduct(
    int productId, {
    int? warehouseId,
  }) async {
    return getMovements(warehouseId: warehouseId, searchQuery: null).then((list) =>
        list.where((e) => e.productId == productId).toList());
  }
}
