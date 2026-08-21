import 'package:equatable/equatable.dart';

/// كيان رصيد صنف - يلخص الوارد/المنصرف/الرصيد الحالي
class ItemsBalanceEntity extends Equatable {
  final int productId;
  final String productName;
  final String productCode;
  final String unitName;
  final double currentQuantity; // الرصيد الحالي = الوارد - المنصرف (بالوحدة الأساسية)
  final double totalInbound; // إجمالي الوارد
  final double totalOutbound; // إجمالي المنصرف
  final double unitCost; // تكلفة الوحدة (avg_cost أو cost_amount)
  final double totalValue; // current * unitCost
  final int? warehouseId; // null = الكل
  final String? warehouseName;
  final String? packageUnitName; // اسم وحدة التعبئة الكبرى إن وجدت
  final int? packaging;
  final double? conversionRate;

  const ItemsBalanceEntity({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitName,
    required this.currentQuantity,
    required this.totalInbound,
    required this.totalOutbound,
    required this.unitCost,
    required this.totalValue,
    this.warehouseId,
    this.warehouseName,
    this.packageUnitName,
    this.packaging,
    this.conversionRate,
  });

  /// عرض الرصيد بشكل هرمي: مثال "10 كرتون و 10 حبة (250 حبة)"
  String get hierarchicalDisplay {
    if (packageUnitName == null || packaging == null || (packaging! <= 1 && (conversionRate ?? 1) <= 1)) {
      final q = currentQuantity == currentQuantity.roundToDouble() ? currentQuantity.toInt().toString() : currentQuantity.toStringAsFixed(2);
      return '$q $unitName';
    }
    final factor = (packaging! <= 0 ? 1 : packaging!) * ((conversionRate ?? 1) <= 0 ? 1.0 : conversionRate!);
    if (factor <= 1) {
      final q = currentQuantity == currentQuantity.roundToDouble() ? currentQuantity.toInt().toString() : currentQuantity.toStringAsFixed(2);
      return '$q $unitName';
    }
    final packages = (currentQuantity / factor).floor();
    final remainder = currentQuantity - packages * factor;
    final remStr = remainder.abs() < 0.001 ? '' : ' و ${remainder == remainder.roundToDouble() ? remainder.toInt().toString() : remainder.toStringAsFixed(2)} $unitName';
    if (packages == 0) {
      final q = currentQuantity == currentQuantity.roundToDouble() ? currentQuantity.toInt().toString() : currentQuantity.toStringAsFixed(2);
      return '$q $unitName';
    }
    if (remStr.isEmpty) return '$packages $packageUnitName';
    return '$packages $packageUnitName$remStr (${currentQuantity == currentQuantity.roundToDouble() ? currentQuantity.toInt().toString() : currentQuantity.toStringAsFixed(2)} $unitName)';
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productCode,
        unitName,
        currentQuantity,
        totalInbound,
        totalOutbound,
        unitCost,
        totalValue,
        warehouseId,
        warehouseName,
        packageUnitName,
        packaging,
        conversionRate,
      ];
}
