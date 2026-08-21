import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/precision_helper.dart';

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
    
    // Convert with precision helper (base = qty * factor, rounded to 6 decimals)
    final baseQuantity = PrecisionHelper.calcBaseQuantity(
      quantity: quantity,
      packaging: packaging,
      conversionRate: conversionRate,
    );
    
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
      return PrecisionHelper.roundQuantity(baseQuantity);
    }
    
    final subUnit = subUnitResult.first;
    final conversionRate = (subUnit['conversion_rate'] as num?)?.toDouble() ?? 1.0;
    final packaging = (subUnit['packaging'] as int?) ?? 1;
    
    // Convert: targetQuantity = baseQuantity / (packaging * conversionRate)
    final divisor = packaging * conversionRate;
    if (divisor <= 0) {
      throw LocalStorageException('معامل التحويل غير صالح');
    }
    
    return PrecisionHelper.roundQuantity(baseQuantity / divisor);
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

  /// Get all available units for a product (main + sub units) مع الأسعار والباركود
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
        su.is_default_sale,
        su.is_default_purchase,
        su.barcode,
        su.cost_price,
        su.sell_price,
        su.wholesale_price,
        u.name as unit_name,
        u.short as unit_short
      FROM category_sub_units su
      LEFT JOIN categories_units u ON u.id = su.unit_id
      WHERE su.category_id = ?
      ORDER BY su.is_main_unit DESC, su.is_default_sale DESC, su.packaging ASC
    ''', [productId]);
    
    final result = <ProductUnitOption>[];
    
    for (final su in subUnits) {
      result.add(ProductUnitOption(
        unitId: su['unit_id'] as int?,
        subUnitId: su['sub_unit_id'] as int?,
        unitName: su['unit_name'] as String? ?? 'غير معروف',
        unitShort: su['unit_short'] as String? ?? '؟',
        packaging: (su['packaging'] as int?) ?? 1,
        conversionRate: (su['conversion_rate'] as num?)?.toDouble() ?? 1.0,
        isMainUnit: (su['is_main_unit'] as int?) == 1,
        isDefaultSale: (su['is_default_sale'] as int?) == 1,
        isDefaultPurchase: (su['is_default_purchase'] as int?) == 1,
        barcode: su['barcode'] as String?,
        costPrice: (su['cost_price'] as num?)?.toDouble(),
        sellPrice: (su['sell_price'] as num?)?.toDouble(),
        wholesalePrice: (su['wholesale_price'] as num?)?.toDouble(),
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
          subUnitId: null,
          unitName: unit.first['name'] as String? ?? 'غير معروف',
          unitShort: unit.first['short'] as String? ?? '؟',
          packaging: 1,
          conversionRate: 1.0,
          isMainUnit: true,
          isDefaultSale: true,
          isDefaultPurchase: true,
        ));
      }
    }
    
    return result;
  }

  /// جلب الوحدة الافتراضية للبيع
  Future<ProductUnitOption?> getDefaultSaleUnit(int productId) async {
    final units = await getUnitsForProduct(productId);
    if (units.isEmpty) return null;
    try {
      return units.firstWhere((u) => u.isDefaultSale);
    } catch (_) {
      try {
        return units.firstWhere((u) => u.isMainUnit);
      } catch (_) {
        return units.first;
      }
    }
  }

  /// جلب الوحدة الافتراضية للشراء
  Future<ProductUnitOption?> getDefaultPurchaseUnit(int productId) async {
    final units = await getUnitsForProduct(productId);
    if (units.isEmpty) return null;
    try {
      return units.firstWhere((u) => u.isDefaultPurchase);
    } catch (_) {
      try {
        return units.firstWhere((u) => u.isMainUnit);
      } catch (_) {
        return units.first;
      }
    }
  }

  /// البحث الذكي عبر الباركود: يحاول مطابقة باركود الصنف الأساسي ثم باركود الوحدة
  Future<BarcodeLookupResult?> lookupByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    final db = await _databaseService.database;
    final code = barcode.trim();
    // 1) ابحث في باركود الصنف الأساسي
    final productRows = await db.query('categories', where: 'barcode_no = ?', whereArgs: [code], limit: 1);
    if (productRows.isNotEmpty) {
      final pid = productRows.first['id'] as int;
      final units = await getUnitsForProduct(pid);
      final def = await getDefaultSaleUnit(pid);
      return BarcodeLookupResult(productId: pid, unit: def ?? (units.isNotEmpty ? units.first : null), isMainBarcode: true);
    }
    // 2) ابحث في باركود الوحدة الفرعية
    final suRows = await db.query('category_sub_units', where: 'barcode = ?', whereArgs: [code], limit: 1);
    if (suRows.isNotEmpty) {
      final pid = suRows.first['category_id'] as int;
      final unitId = suRows.first['unit_id'] as int?;
      final units = await getUnitsForProduct(pid);
      ProductUnitOption? matched;
      for (final u in units) {
        if (u.unitId == unitId) { matched = u; break; }
      }
      // fallback create option from row itself
      if (matched == null) {
        final unitNameRow = unitId != null ? await db.query('categories_units', where: 'id = ?', whereArgs: [unitId], limit: 1) : [];
        matched = ProductUnitOption(
          unitId: unitId,
          subUnitId: suRows.first['id'] as int?,
          unitName: unitNameRow.isNotEmpty ? (unitNameRow.first['name'] as String? ?? 'غير معروف') : 'وحدة',
          unitShort: unitNameRow.isNotEmpty ? (unitNameRow.first['short'] as String? ?? '؟') : '؟',
          packaging: (suRows.first['packaging'] as int?) ?? 1,
          conversionRate: (suRows.first['conversion_rate'] as num?)?.toDouble() ?? 1.0,
          isMainUnit: (suRows.first['is_main_unit'] as int?) == 1,
          isDefaultSale: (suRows.first['is_default_sale'] as int?) == 1,
          barcode: code,
          sellPrice: (suRows.first['sell_price'] as num?)?.toDouble(),
          wholesalePrice: (suRows.first['wholesale_price'] as num?)?.toDouble(),
          costPrice: (suRows.first['cost_price'] as num?)?.toDouble(),
        );
      }
      return BarcodeLookupResult(productId: pid, unit: matched, isMainBarcode: false);
    }
    return null;
  }

  /// حساب السعر المناسب للوحدة: يفضل سعر الوحدة المخصص ثم basePrice * factor
  double resolveUnitPrice({
    required double baseSellPrice,
    required ProductUnitOption unit,
  }) {
    if (unit.sellPrice != null && unit.sellPrice! > 0) {
      return PrecisionHelper.roundCurrency(unit.sellPrice!);
    }
    return PrecisionHelper.calcUnitPrice(basePrice: baseSellPrice, packaging: unit.packaging, conversionRate: unit.conversionRate);
  }

  double resolveUnitWholesalePrice({required double baseWholesaleOrSell, required ProductUnitOption unit}) {
    if (unit.wholesalePrice != null && unit.wholesalePrice! > 0) return PrecisionHelper.roundCurrency(unit.wholesalePrice!);
    return PrecisionHelper.calcUnitPrice(basePrice: baseWholesaleOrSell, packaging: unit.packaging, conversionRate: unit.conversionRate);
  }

  double resolveUnitCost({required double baseCost, required ProductUnitOption unit}) {
    if (unit.costPrice != null && unit.costPrice! > 0) return PrecisionHelper.roundCurrency(unit.costPrice!);
    return PrecisionHelper.calcUnitPrice(basePrice: baseCost, packaging: unit.packaging, conversionRate: unit.conversionRate);
  }

  /// تفصيل الكمية الأساسية إلى تعبئة (مثل: 250 حبة => 10 كرتون و 10 حبة)
  String formatBreakdown(double baseQuantity, ProductUnitOption packageUnit, String baseUnitName) {
    final br = PrecisionHelper.breakdownQuantity(
      baseQuantity: baseQuantity,
      packaging: packageUnit.packaging,
      conversionRate: packageUnit.conversionRate,
      baseUnitName: baseUnitName,
      packageUnitName: packageUnit.unitName,
    );
    return br.display;
  }

  /// Calculate price for a specific unit based on base price
  double calculatePriceForUnit({
    required double basePrice,
    required int packaging,
    required double conversionRate,
  }) {
    return PrecisionHelper.calcUnitPrice(basePrice: basePrice, packaging: packaging, conversionRate: conversionRate);
  }

  /// Calculate cost for a specific unit based on base cost
  double calculateCostForUnit({
    required double baseCost,
    required int packaging,
    required double conversionRate,
  }) {
    return PrecisionHelper.calcUnitPrice(basePrice: baseCost, packaging: packaging, conversionRate: conversionRate);
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
  final int? subUnitId;
  final String unitName;
  final String unitShort;
  final int packaging;
  final double conversionRate;
  final bool isMainUnit;
  final bool isDefaultSale;
  final bool isDefaultPurchase;
  final String? barcode;
  final double? costPrice;
  final double? sellPrice;
  final double? wholesalePrice;

  ProductUnitOption({
    this.unitId,
    this.subUnitId,
    required this.unitName,
    required this.unitShort,
    required this.packaging,
    required this.conversionRate,
    required this.isMainUnit,
    this.isDefaultSale = false,
    this.isDefaultPurchase = false,
    this.barcode,
    this.costPrice,
    this.sellPrice,
    this.wholesalePrice,
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

  /// يحتوي على باركود
  bool get hasBarcode => barcode != null && barcode!.trim().isNotEmpty;
}

class BarcodeLookupResult {
  final int productId;
  final ProductUnitOption? unit;
  final bool isMainBarcode;
  BarcodeLookupResult({required this.productId, this.unit, required this.isMainBarcode});
}
