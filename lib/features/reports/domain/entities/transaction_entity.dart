import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final int id;
  final DateTime date;
  final String description;
  final String reference;
  final String transactionType;
  final double totalAmount;
  final List<TransactionDetailEntity> details;
  final int? invoiceId;
  final int? voucherId;
  final int createdBy;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.date,
    required this.description,
    required this.reference,
    required this.transactionType,
    required this.totalAmount,
    required this.details,
    this.invoiceId,
    this.voucherId,
    required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        description,
        reference,
        transactionType,
        totalAmount,
        details,
        invoiceId,
        voucherId,
        createdBy,
        createdAt,
      ];
}

class TransactionDetailEntity extends Equatable {
  final int id;
  final int accountId;
  final String accountName;
  final String accountCode;
  final double debitAmount;
  final double creditAmount;
  final String? notes;
  final int? costCenterId;
  final String? costCenterName;

  const TransactionDetailEntity({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.debitAmount,
    required this.creditAmount,
    this.notes,
    this.costCenterId,
    this.costCenterName,
  });

  @override
  List<Object?> get props => [
        id,
        accountId,
        accountName,
        accountCode,
        debitAmount,
        creditAmount,
        notes,
        costCenterId,
        costCenterName,
      ];
}

enum TransactionType {
  sales,
  purchase,
  receipt,
  payment,
  journal,
  opening,
  salesReturn,
  purchaseReturn,
}

extension TransactionTypeExt on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.sales:
        return 'مبيعات';
      case TransactionType.purchase:
        return 'مشتريات';
      case TransactionType.receipt:
        return 'قبض';
      case TransactionType.payment:
        return 'صرف';
      case TransactionType.journal:
        return 'قيد يومية';
      case TransactionType.opening:
        return 'رصيد افتتاحي';
      case TransactionType.salesReturn:
        return 'مردود مبيعات';
      case TransactionType.purchaseReturn:
        return 'مردود مشتريات';
    }
  }
  
  String get value {
    return name;
  }
}
