import 'package:muhasib/features/customers/domain/entities/customer_entity.dart';
import 'dart:convert';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.type,
    super.contact,
    super.address,
    super.isActive,
    super.creditLimit,
    super.currentBalance,
    super.accountId,
    super.classificationId,
    super.creationTime,
    super.lastModificationTime,
  });

  static Map<String, dynamic> _decodeExtraProperties(String? value) {
    if (value == null || value.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return <String, dynamic>{};
  }

  static String? _encodeExtraProperties(Map<String, dynamic> extra) {
    if (extra.isEmpty) return null;
    try {
      return jsonEncode(extra);
    } catch (_) {
      return null;
    }
  }

  // Factory constructor to create from database map
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    final extra = _decodeExtraProperties(map['extra_properties'] as String?);
    return CustomerModel(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as int? ?? 1,
      contact: map['contact'] as String?,
      // customers table has no `address` column; keep it in extra_properties
      address: (extra['address'] as String?) ?? (extra['addr'] as String?),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      accountId: map['account_id'] as int?,
      classificationId: map['classification_id'] as int?,
      creationTime: map['creation_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['creation_time'] as int) * 1000)
          : null,
      lastModificationTime: map['last_modification_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['last_modification_time'] as int) * 1000)
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    final extra = <String, dynamic>{};
    if (address != null && address!.trim().isNotEmpty) {
      extra['address'] = address!.trim();
    }
    return {
      'id': id,
      'name': name,
      'type': type,
      'contact': contact,
      'extra_properties': _encodeExtraProperties(extra),
      'is_active': isActive ? 1 : 0,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'account_id': accountId,
      'classification_id': classificationId,
      'creation_time': creationTime != null 
          ? creationTime!.millisecondsSinceEpoch ~/ 1000 
          : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': lastModificationTime != null 
          ? lastModificationTime!.millisecondsSinceEpoch ~/ 1000 
          : DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  // Create a new customer map for database insertion
  static Map<String, dynamic> toInsertMap({
    required String name,
    required int type,
    String? contact,
    String? address,
    double creditLimit = 0.0,
    double currentBalance = 0.0,
    int? accountId,
    int classificationId = 1,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final extra = <String, dynamic>{};
    if (address != null && address.trim().isNotEmpty) {
      extra['address'] = address.trim();
    }
    return {
      'name': name,
      'type': type,
      'classification': classificationId,
      'classification_id': classificationId,
      'contact': contact,
      'contact_type': contact != null ? 1 : null,
      'extra_properties': _encodeExtraProperties(extra),
      'is_active': 1,
      'account_id': accountId,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'creation_time': now,
      'last_modification_time': now,
    };
  }

  // Convert entity to model
  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      contact: entity.contact,
      address: entity.address,
      isActive: entity.isActive,
      creditLimit: entity.creditLimit,
      currentBalance: entity.currentBalance,
      accountId: entity.accountId,
      classificationId: entity.classificationId,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }
}
