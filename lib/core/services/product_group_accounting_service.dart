import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/account_config_service.dart';

/// Service to resolve accounting accounts based on product group configuration
/// Enables segment-based accounting where different product groups can have
/// different inventory, COGS, revenue, and purchase accounts
class ProductGroupAccountingService {
  final DatabaseService _databaseService;
  final AccountConfigService _accountConfigService;

  ProductGroupAccountingService(this._databaseService, this._accountConfigService);

  /// Get the appropriate inventory account for a product
  /// Falls back to default if product/group doesn't have one configured
  Future<int> getInventoryAccountForProduct(int? productId, {int? groupId}) async {
    final accounts = await _getProductGroupAccounts(productId, groupId: groupId);
    return accounts.inventoryAccountId ?? DefaultAccountIds.inventory;
  }

  /// Get the appropriate COGS account for a product
  Future<int> getCogsAccountForProduct(int? productId, {int? groupId}) async {
    final accounts = await _getProductGroupAccounts(productId, groupId: groupId);
    return accounts.cogsAccountId ?? DefaultAccountIds.costOfGoodsSold;
  }

  /// Get the appropriate revenue account for a product
  Future<int> getRevenueAccountForProduct(int? productId, {int? groupId}) async {
    final accounts = await _getProductGroupAccounts(productId, groupId: groupId);
    return accounts.revenueAccountId ?? await _getDefaultRevenueAccount();
  }

  /// Get the appropriate purchase account for a product
  Future<int> getPurchaseAccountForProduct(int? productId, {int? groupId}) async {
    final accounts = await _getProductGroupAccounts(productId, groupId: groupId);
    return accounts.purchaseAccountId ?? await _getDefaultPurchaseAccount();
  }

  /// Get all accounting accounts for a product based on its group
  Future<ProductGroupAccountConfig> getAccountConfigForProduct(int? productId, {int? groupId}) async {
    return await _getProductGroupAccounts(productId, groupId: groupId);
  }

  /// Get accounting accounts for a list of products (for batch operations)
  Future<Map<int, ProductGroupAccountConfig>> getAccountConfigForProducts(List<int> productIds) async {
    final result = <int, ProductGroupAccountConfig>{};
    
    for (final productId in productIds) {
      result[productId] = await _getProductGroupAccounts(productId);
    }
    
    return result;
  }

  /// Internal method to get product group accounts
  Future<ProductGroupAccountConfig> _getProductGroupAccounts(int? productId, {int? groupId}) async {
    final db = await _databaseService.database;
    
    int? resolvedGroupId = groupId;
    
    // If no groupId provided, get it from the product
    if (resolvedGroupId == null && productId != null) {
      final product = await db.query(
        'categories',
        columns: ['group_id'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      
      if (product.isNotEmpty) {
        resolvedGroupId = product.first['group_id'] as int?;
      }
    }
    
    // If we have a group ID, try to get its accounts
    if (resolvedGroupId != null) {
      final group = await db.query(
        'categories_groups',
        where: 'id = ?',
        whereArgs: [resolvedGroupId],
        limit: 1,
      );
      
      if (group.isNotEmpty) {
        final g = group.first;
        
        // Check if any account is configured
        final hasAccounts = g['inventory_account_id'] != null ||
                           g['cogs_account_id'] != null ||
                           g['revenue_account_id'] != null ||
                           g['purchase_account_id'] != null;
        
        if (hasAccounts) {
          return ProductGroupAccountConfig(
            groupId: resolvedGroupId,
            groupName: g['name'] as String?,
            inventoryAccountId: g['inventory_account_id'] as int?,
            cogsAccountId: g['cogs_account_id'] as int?,
            revenueAccountId: g['revenue_account_id'] as int?,
            purchaseAccountId: g['purchase_account_id'] as int?,
            purchaseReturnAccountId: g['purchase_return_account_id'] as int?,
            salesReturnAccountId: g['sales_return_account_id'] as int?,
            defaultTaxId: g['default_tax_id'] as int?,
            defaultMarginPercent: (g['default_margin_percent'] as num?)?.toDouble(),
          );
        }
        
        // Check parent group if current group has no accounts
        final parentGroupId = g['parent_group_id'] as int?;
        if (parentGroupId != null) {
          return await _getProductGroupAccounts(null, groupId: parentGroupId);
        }
      }
    }
    
    // Return default configuration
    return ProductGroupAccountConfig(
      groupId: null,
      groupName: 'افتراضي',
    );
  }

  Future<int> _getDefaultRevenueAccount() async {
    // Try to get from account config service or use default
    return 4110; // Default sales/revenue account
  }

  Future<int> _getDefaultPurchaseAccount() async {
    // Try to get from account config service or use default
    return 5110; // Default purchases account
  }

  /// Get summary of inventory value by product group
  Future<List<GroupInventorySummary>> getInventoryByGroup() async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery('''
      SELECT 
        g.id as group_id,
        g.name as group_name,
        COUNT(c.id) as product_count,
        SUM(COALESCE(ws.quantity, 0)) as total_quantity,
        SUM(COALESCE(ws.quantity, 0) * COALESCE(ws.avg_cost, c.cost_amount, 0)) as total_value
      FROM categories_groups g
      LEFT JOIN categories c ON c.group_id = g.id
      LEFT JOIN warehouse_stocks ws ON ws.product_id = c.id
      GROUP BY g.id, g.name
      ORDER BY g.name
    ''');
    
    return result.map((row) => GroupInventorySummary(
      groupId: row['group_id'] as int,
      groupName: row['group_name'] as String,
      productCount: row['product_count'] as int? ?? 0,
      totalQuantity: (row['total_quantity'] as num?)?.toDouble() ?? 0.0,
      totalValue: (row['total_value'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }
}

/// Configuration for a product group's accounting accounts
class ProductGroupAccountConfig {
  final int? groupId;
  final String? groupName;
  final int? inventoryAccountId;
  final int? cogsAccountId;
  final int? revenueAccountId;
  final int? purchaseAccountId;
  final int? purchaseReturnAccountId;
  final int? salesReturnAccountId;
  final int? defaultTaxId;
  final double? defaultMarginPercent;

  ProductGroupAccountConfig({
    this.groupId,
    this.groupName,
    this.inventoryAccountId,
    this.cogsAccountId,
    this.revenueAccountId,
    this.purchaseAccountId,
    this.purchaseReturnAccountId,
    this.salesReturnAccountId,
    this.defaultTaxId,
    this.defaultMarginPercent,
  });

  /// Check if this group has any custom account configuration
  bool get hasCustomAccounts => 
    inventoryAccountId != null ||
    cogsAccountId != null ||
    revenueAccountId != null ||
    purchaseAccountId != null;
}

/// Summary of inventory for a product group
class GroupInventorySummary {
  final int groupId;
  final String groupName;
  final int productCount;
  final double totalQuantity;
  final double totalValue;

  GroupInventorySummary({
    required this.groupId,
    required this.groupName,
    required this.productCount,
    required this.totalQuantity,
    required this.totalValue,
  });
}
