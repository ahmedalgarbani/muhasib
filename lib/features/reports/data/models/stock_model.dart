import 'package:muhasib/features/reports/domain/entities/stock_entity.dart';

class StockModel extends StockEntity {
  const StockModel({
    required super.productId,
    required super.productCode,
    required super.productName,
    super.categoryName,
    super.unitName,
    required super.currentStock,
    required super.minStock,
    required super.maxStock,
    required super.costPrice,
    required super.salePrice,
    required super.stockValue,
    required super.warehouseId,
    super.warehouseName,
    super.lastMovementDate,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      productId: map['product_id'] ?? 0,
      productCode: map['product_code'] ?? '',
      productName: map['product_name'] ?? '',
      categoryName: map['category_name'],
      unitName: map['unit_name'],
      currentStock: (map['current_stock'] ?? 0.0).toDouble(),
      minStock: (map['min_stock'] ?? 0.0).toDouble(),
      maxStock: (map['max_stock'] ?? 999999.0).toDouble(),
      costPrice: (map['cost_price'] ?? 0.0).toDouble(),
      salePrice: (map['sale_price'] ?? 0.0).toDouble(),
      stockValue: (map['stock_value'] ?? 0.0).toDouble(),
      warehouseId: map['warehouse_id'] ?? 1,
      warehouseName: map['warehouse_name'],
      lastMovementDate: map['last_movement_date'] != null 
        ? DateTime.tryParse(map['last_movement_date'])
        : null,
    );
  }
}
