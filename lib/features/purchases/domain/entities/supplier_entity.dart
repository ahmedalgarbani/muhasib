import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? phone;
  final String? mobile;
  final String? email;
  final String? address;
  final String? taxNumber;
  final String? commercialRegister;
  final double creditLimit;
  final double currentBalance;
  final int paymentTerms; // Days
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.code,
    this.phone,
    this.mobile,
    this.email,
    this.address,
    this.taxNumber,
    this.commercialRegister,
    this.creditLimit = 0.0,
    this.currentBalance = 0.0,
    this.paymentTerms = 30,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasCredit => creditLimit > 0;
  bool get isOverCreditLimit => currentBalance > creditLimit && creditLimit > 0;
  double get availableCredit => creditLimit > currentBalance ? creditLimit - currentBalance : 0;

  SupplierEntity copyWith({
    int? id,
    String? name,
    String? code,
    String? phone,
    String? mobile,
    String? email,
    String? address,
    String? taxNumber,
    String? commercialRegister,
    double? creditLimit,
    double? currentBalance,
    int? paymentTerms,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        phone,
        mobile,
        email,
        address,
        taxNumber,
        commercialRegister,
        creditLimit,
        currentBalance,
        paymentTerms,
        isActive,
        notes,
        createdAt,
        updatedAt,
      ];
}
