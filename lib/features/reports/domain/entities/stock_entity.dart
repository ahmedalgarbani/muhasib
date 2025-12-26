class StockEntity {
  final int productId;
  final String productCode;
  final String productName;
  final String? categoryName;
  final String? unitName;
  final double currentStock;
  final double minStock;
  final double maxStock;
  final double costPrice;
  final double salePrice;
  final double stockValue;
  final int warehouseId;
  final String? warehouseName;
  final DateTime? lastMovementDate;

  const StockEntity({
    required this.productId,
    required this.productCode,
    required this.productName,
    this.categoryName,
    this.unitName,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.costPrice,
    required this.salePrice,
    required this.stockValue,
    required this.warehouseId,
    this.warehouseName,
    this.lastMovementDate,
  });

  bool get isLowStock => currentStock <= minStock;
  bool get isOverStock => currentStock >= maxStock;
  bool get isInStock => currentStock > 0;
}

class StockSummary {
  final double totalStockValue;
  final int totalProducts;
  final double totalQuantity;
  final int lowStockCount;
  final int overStockCount;
  final int outOfStockCount;

  const StockSummary({
    required this.totalStockValue,
    required this.totalProducts,
    required this.totalQuantity,
    required this.lowStockCount,
    required this.overStockCount,
    required this.outOfStockCount,
  });
}
