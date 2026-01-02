import 'package:equatable/equatable.dart';

class ProductGroupEntity extends Equatable {
  final int? id;
  final String name;
  final String? statement;
  final int? parentGroupId;
  final bool isActive;
  final int? creatorId;
  final int? lastModifierId;
  final int? creationTime;
  final int? lastModificationTime;
  
  // Accounting Account Links
  final int? inventoryAccountId;
  final int? cogsAccountId;
  final int? revenueAccountId;
  final int? purchaseAccountId;
  final int? purchaseReturnAccountId;
  final int? salesReturnAccountId;
  
  // Default settings
  final int? defaultTaxId;
  final double? defaultMarginPercent;

  const ProductGroupEntity({
    this.id,
    required this.name,
    this.statement,
    this.parentGroupId,
    this.isActive = true,
    this.creatorId,
    this.lastModifierId,
    this.creationTime,
    this.lastModificationTime,
    this.inventoryAccountId,
    this.cogsAccountId,
    this.revenueAccountId,
    this.purchaseAccountId,
    this.purchaseReturnAccountId,
    this.salesReturnAccountId,
    this.defaultTaxId,
    this.defaultMarginPercent,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        statement,
        parentGroupId,
        isActive,
        creatorId,
        lastModifierId,
        creationTime,
        lastModificationTime,
        inventoryAccountId,
        cogsAccountId,
        revenueAccountId,
        purchaseAccountId,
        purchaseReturnAccountId,
        salesReturnAccountId,
        defaultTaxId,
        defaultMarginPercent,
      ];
  
  /// Copy with method for immutable updates
  ProductGroupEntity copyWith({
    int? id,
    String? name,
    String? statement,
    int? parentGroupId,
    bool? isActive,
    int? creatorId,
    int? lastModifierId,
    int? creationTime,
    int? lastModificationTime,
    int? inventoryAccountId,
    int? cogsAccountId,
    int? revenueAccountId,
    int? purchaseAccountId,
    int? purchaseReturnAccountId,
    int? salesReturnAccountId,
    int? defaultTaxId,
    double? defaultMarginPercent,
  }) {
    return ProductGroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      statement: statement ?? this.statement,
      parentGroupId: parentGroupId ?? this.parentGroupId,
      isActive: isActive ?? this.isActive,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      inventoryAccountId: inventoryAccountId ?? this.inventoryAccountId,
      cogsAccountId: cogsAccountId ?? this.cogsAccountId,
      revenueAccountId: revenueAccountId ?? this.revenueAccountId,
      purchaseAccountId: purchaseAccountId ?? this.purchaseAccountId,
      purchaseReturnAccountId: purchaseReturnAccountId ?? this.purchaseReturnAccountId,
      salesReturnAccountId: salesReturnAccountId ?? this.salesReturnAccountId,
      defaultTaxId: defaultTaxId ?? this.defaultTaxId,
      defaultMarginPercent: defaultMarginPercent ?? this.defaultMarginPercent,
    );
  }
}

