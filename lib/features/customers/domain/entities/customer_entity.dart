import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final int id;
  final String name;
  final int type; // 1=customer, 2=supplier
  final String? contact;
  final String? address;
  final bool isActive;
  final double creditLimit;
  final double currentBalance;
  final int? accountId;
  final int? classificationId;
  final DateTime? creationTime;
  final DateTime? lastModificationTime;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.type,
    this.contact,
    this.address,
    this.isActive = true,
    this.creditLimit = 0.0,
    this.currentBalance = 0.0,
    this.accountId,
    this.classificationId,
    this.creationTime,
    this.lastModificationTime,
  });

  // Helper getters
  bool get isCustomer => type == 1;
  bool get isSupplier => type == 2;
  bool get hasCredit => creditLimit > 0;
  bool get isOverCreditLimit => currentBalance > creditLimit && creditLimit > 0;
  
  @override
  List<Object?> get props => [
        id,
        name,
        type,
        contact,
        address,
        isActive,
        creditLimit,
        currentBalance,
        accountId,
        classificationId,
        creationTime,
        lastModificationTime,
      ];
}
