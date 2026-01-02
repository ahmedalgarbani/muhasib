import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';

class ProductGroupModel extends ProductGroupEntity {
  const ProductGroupModel({
    super.id,
    required super.name,
    super.statement,
    super.parentGroupId,
    super.isActive = true,
    super.creatorId,
    super.lastModifierId,
    super.creationTime,
    super.lastModificationTime,
    super.inventoryAccountId,
    super.cogsAccountId,
    super.revenueAccountId,
    super.purchaseAccountId,
    super.purchaseReturnAccountId,
    super.salesReturnAccountId,
    super.defaultTaxId,
    super.defaultMarginPercent,
  });

  factory ProductGroupModel.fromJson(Map<String, dynamic> json) {
    return ProductGroupModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      statement: json['description'] as String?, // Database uses 'description' column
      parentGroupId: json['parent_group_id'] as int?,
      isActive: (json['is_active'] as int? ?? 1) == 1,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
      // Accounting accounts
      inventoryAccountId: json['inventory_account_id'] as int?,
      cogsAccountId: json['cogs_account_id'] as int?,
      revenueAccountId: json['revenue_account_id'] as int?,
      purchaseAccountId: json['purchase_account_id'] as int?,
      purchaseReturnAccountId: json['purchase_return_account_id'] as int?,
      salesReturnAccountId: json['sales_return_account_id'] as int?,
      // Default settings
      defaultTaxId: json['default_tax_id'] as int?,
      defaultMarginPercent: (json['default_margin_percent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': statement, // Map statement to database's 'description' column
      'parent_group_id': parentGroupId,
      'is_active': isActive ? 1 : 0,
      'creator_id': creatorId ?? 1,
      'last_modifier_id': lastModifierId ?? 1,
      // Accounting accounts
      'inventory_account_id': inventoryAccountId,
      'cogs_account_id': cogsAccountId,
      'revenue_account_id': revenueAccountId,
      'purchase_account_id': purchaseAccountId,
      'purchase_return_account_id': purchaseReturnAccountId,
      'sales_return_account_id': salesReturnAccountId,
      // Default settings
      'default_tax_id': defaultTaxId,
      'default_margin_percent': defaultMarginPercent,
    };
    
    // Set timestamps with defaults if null
    map['creation_time'] = creationTime ?? DateTime.now().millisecondsSinceEpoch;
    map['last_modification_time'] = lastModificationTime ?? DateTime.now().millisecondsSinceEpoch;
    
    return map;
  }

  factory ProductGroupModel.fromEntity(ProductGroupEntity entity) {
    return ProductGroupModel(
      id: entity.id,
      name: entity.name,
      statement: entity.statement,
      parentGroupId: entity.parentGroupId,
      isActive: entity.isActive,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
      inventoryAccountId: entity.inventoryAccountId,
      cogsAccountId: entity.cogsAccountId,
      revenueAccountId: entity.revenueAccountId,
      purchaseAccountId: entity.purchaseAccountId,
      purchaseReturnAccountId: entity.purchaseReturnAccountId,
      salesReturnAccountId: entity.salesReturnAccountId,
      defaultTaxId: entity.defaultTaxId,
      defaultMarginPercent: entity.defaultMarginPercent,
    );
  }
}

