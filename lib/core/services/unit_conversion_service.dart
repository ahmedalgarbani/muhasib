import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/services/database_service.dart';

/// Service for handling unit conversion in inventory and invoicing
/// Ensures accurate quantity tracking across different units of measure
class UnitConversionService {
  final DatabaseService _databaseService;

  UnitConversionService(this._databaseService);

  /// Convert quantity from one unit to base unit
  /// Returns the equivalent quantity in the product's base unit
  Future<UnitConversionResult> convertToBaseUnit({
    required int productId,
    required double quantity,
    required int? unitId,
  }) async {
    if (quantity <= 0) {
      throw LocalStorageException('الكمية يجب أن تكون موجبة');
    }
    
    final db = await _databaseService.database;
    
    // Get the sub-unit configuration for this product and unit
    final subUnitResult = await db.query(
      'category_sub_units',
      where: 'category_id = ? AND unit_id = ?',
      whereArgs: [productId, unitId],
      limit: 1,
    );
    
    if (subUnitResult.isEmpty) {
      // No specific conversion defined, assume 1:1
      return UnitConversionResult(
        originalQuantity: quantity,
        originalUnitId: unitId,
        baseQuantity: quantity,
        conversionRate: 1.0,
        packaging: 1,
      );
    }
    
    final subUnit = subUnitResult.first;
    final conversionRate = (subUnit['conversion_rate'] as num?)?.toDouble() ?? 1.0;
    final packaging = (subUnit['packaging'] as int?) ?? 1;
    final isMainUnit = (subUnit['is_main_unit'] as int?) == 1;
    
    // If this is the main unit, no conversion needed
    if (isMainUnit) {
      return UnitConversionResult(
        originalQuantity: quantity,
        originalUnitId: unitId,
        baseQuantity: quantity,
        conversionRate: 1.0,
        packaging: 1,
      );
    }
    
    // Convert: baseQuantity = quantity * packaging * conversionRate
    final baseQuantity = quantity * packaging * conversionRate;
    
    return UnitConversionResult(
      originalQuantity: quantity,
      originalUnitId: unitId,
      baseQuantity: baseQuantity,
      conversionRate: conversionRate,
      packaging: packaging,
    );
  }

  /// Convert quantity from base unit to target unit
  Future<double> convertFromBaseUnit({
    required int productId,
    required double baseQuantity,
    required int? targetUnitId,
  }) async {
    final db = await _databaseService.database;
    
    final subUnitResult = await db.query(
      'category_sub_units',
      where: 'category_id = ? AND unit_id = ?',
      whereArgs: [productId, targetUnitId],
      limit: 1,
    );
    
    if (subUnitResult.isEmpty) {
      return baseQuantity; // No conversion, return as-is
    }
    
    final subUnit = subUnitResult.first;
    final conversionRate = (subUnit['conversion_rate'] as num?)?.toDouble() ?? 1.0;
    final packaging = (subUnit['packaging'] as int?) ?? 1;
    
    // Convert: targetQuantity = baseQuantity / (packaging * conversionRate)
    final divisor = packaging * conversionRate;
    if (divisor <= 0) {
      throw LocalStorageException('معامل التحويل غير صالح');
    }
    
    return baseQuantity / divisor;
  }

  /// Validate unit conversion rate
  /// Throws exception if rate is invalid
  void validateConversionRate(double rate) {
    if (rate <= 0) {
      throw LocalStorageException('معامل التحويل يجب أن يكون موجباً');
    }
    if (rate > 1000000) {
      throw LocalStorageException('معامل التحويل كبير جداً (الحد الأقصى: 1,000,000)');
    }
    if (rate < 0.000001) {
      throw LocalStorageException('معامل التحويل صغير جداً (الحد الأدنى: 0.000001)');
    }
  }

  /// Validate quantity value
  /// Throws exception if quantity is invalid
  void validateQuantity(double quantity, {bool allowFractions = true}) {
    if (quantity < 0) {
      throw LocalStorageException('الكمية لا يمكن أن تكون سالبة');
    }
    if (quantity > 999999999) {
      throw LocalStorageException('الكمية كبيرة جداً');
    }
    if (!allowFractions && quantity != quantity.roundToDouble()) {
      throw LocalStorageException('هذا المنتج لا يقبل كسور');
    }
  }

  /// Check if a unit can be deleted safely
  /// Returns a list of issues if deletion is not safe
  Future<List<String>> canDeleteUnit(int unitId) async {
    final db = await _databaseService.database;
    final issues = <String>[];
    
    // Check if unit is used in products
    final productsUsing = await db.rawQuery('''
      SELECT COUNT(*) as count FROM categories WHERE unit_id = ?
    ''', [unitId]);
    final productCount = (productsUsing.first['count'] as int?) ?? 0;
    if (productCount > 0) {
      issues.add('الوحدة مستخدمة في $productCount منتج');
    }
    
    // Check if unit is used in sub-units
    final subUnitsUsing = await db.rawQuery('''
      SELECT COUNT(*) as count FROM category_sub_units WHERE unit_id = ?
    ''', [unitId]);
    final subUnitCount = (subUnitsUsing.first['count'] as int?) ?? 0;
    if (subUnitCount > 0) {
      issues.add('الوحدة مستخدمة في $subUnitCount تحويل');
    }
    
    // Check if unit is used in invoice lines
    final invoicesUsing = await db.rawQuery('''
      SELECT COUNT(*) as count FROM invoice_lines WHERE unit_id = ?
    ''', [unitId]);
    final invoiceCount = (invoicesUsing.first['count'] as int?) ?? 0;
    if (invoiceCount > 0) {
      issues.add('الوحدة مستخدمة في $invoiceCount سطر فاتورة');
    }
    
    return issues;
  }

  /// Get all available units for a product (main + sub units)
  Future<List<ProductUnitOption>> getUnitsForProduct(int productId) async {
    final db = await _databaseService.database;
    
    // Get product's main unit
    final product = await db.query(
      'categories',
      columns: ['unit_id'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    
    final mainUnitId = product.isNotEmpty ? product.first['unit_id'] as int? : null;
    
    // Get all sub-units for this product
    final subUnits = await db.rawQuery('''
      SELECT 
        su.id as sub_unit_id,
        su.unit_id,
        su.packaging,
        su.conversion_rate,
        su.is_main_unit,
        u.name as unit_name,
        u.short as unit_short
      FROM category_sub_units su
      LEFT JOIN categories_units u ON u.id = su.unit_id
      WHERE su.category_id = ?
      ORDER BY su.is_main_unit DESC, su.packaging ASC
    ''', [productId]);
    
    final result = <ProductUnitOption>[];
    
    for (final su in subUnits) {
      result.add(ProductUnitOption(
        unitId: su['unit_id'] as int?,
        unitName: su['unit_name'] as String? ?? 'غير معروف',
        unitShort: su['unit_short'] as String? ?? '؟',
        packaging: (su['packaging'] as int?) ?? 1,
        conversionRate: (su['conversion_rate'] as num?)?.toDouble() ?? 1.0,
        isMainUnit: (su['is_main_unit'] as int?) == 1,
      ));
    }
    
    // If no sub-units defined and product has a main unit, add it
    if (result.isEmpty && mainUnitId != null) {
      final unit = await db.query(
        'categories_units',
        where: 'id = ?',
        whereArgs: [mainUnitId],
        limit: 1,
      );
      
      if (unit.isNotEmpty) {
        result.add(ProductUnitOption(
          unitId: mainUnitId,
          unitName: unit.first['name'] as String? ?? 'غير معروف',
          unitShort: unit.first['short'] as String? ?? '؟',
          packaging: 1,
          conversionRate: 1.0,
          isMainUnit: true,
        ));
      }
    }
    
    return result;
  }

  /// Calculate price for a specific unit based on base price
  double calculatePriceForUnit({
    required double basePrice,
    required int packaging,
    required double conversionRate,
  }) {
    return basePrice * packaging * conversionRate;
  }

  /// Calculate cost for a specific unit based on base cost
  double calculateCostForUnit({
    required double baseCost,
    required int packaging,
    required double conversionRate,
  }) {
    return baseCost * packaging * conversionRate;
  }
}

/// Result of unit conversion
class UnitConversionResult {
  final double originalQuantity;
  final int? originalUnitId;
  final double baseQuantity;
  final double conversionRate;
  final int packaging;

  UnitConversionResult({
    required this.originalQuantity,
    this.originalUnitId,
    required this.baseQuantity,
    required this.conversionRate,
    required this.packaging,
  });

  /// Get the conversion description
  String get description => 
    '$originalQuantity وحدة = $baseQuantity وحدة أساسية (×$packaging ×${conversionRate.toStringAsFixed(2)})';
}

/// Available unit option for a product
class ProductUnitOption {
  final int? unitId;
  final String unitName;
  final String unitShort;
  final int packaging;
  final double conversionRate;
  final bool isMainUnit;

  ProductUnitOption({
    this.unitId,
    required this.unitName,
    required this.unitShort,
    required this.packaging,
    required this.conversionRate,
    required this.isMainUnit,
  });

  /// Get total conversion factor
  double get totalConversion => packaging * conversionRate;

  /// Get display name with packaging info
  String get displayName {
    if (isMainUnit || packaging == 1) {
      return unitName;
    }
    return '$unitName ($packaging قطعة)';
  }
}
