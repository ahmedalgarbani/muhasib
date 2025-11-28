import 'package:muhasib/features/purchases/domain/entities/supplier_entity.dart';

class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.name,
    super.code,
    super.phone,
    super.mobile,
    super.email,
    super.address,
    super.taxNumber,
    super.commercialRegister,
    super.creditLimit,
    super.currentBalance,
    super.paymentTerms,
    super.isActive,
    super.notes,
    required super.createdAt,
    super.updatedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      phone: json['contact'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      taxNumber: json['tax_number'] as String?,
      commercialRegister: json['commercial_register'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      paymentTerms: json['payment_terms'] as int? ?? 30,
      isActive: json['is_active'] == 1,
      notes: json['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['creation_time'] as int) * 1000,
      ),
      updatedAt: json['last_modification_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['last_modification_time'] as int) * 1000,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'contact': phone,
      'mobile': mobile,
      'email': email,
      'address': address,
      'tax_number': taxNumber,
      'commercial_register': commercialRegister,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'payment_terms': paymentTerms,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'type': 1, // Supplier type
      'creation_time': createdAt.millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': updatedAt != null ? updatedAt!.millisecondsSinceEpoch ~/ 1000 : null,
    };
  }

  factory SupplierModel.fromEntity(SupplierEntity entity) {
    return SupplierModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      phone: entity.phone,
      mobile: entity.mobile,
      email: entity.email,
      address: entity.address,
      taxNumber: entity.taxNumber,
      commercialRegister: entity.commercialRegister,
      creditLimit: entity.creditLimit,
      currentBalance: entity.currentBalance,
      paymentTerms: entity.paymentTerms,
      isActive: entity.isActive,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
