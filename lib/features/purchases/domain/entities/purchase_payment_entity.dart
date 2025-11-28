import 'package:equatable/equatable.dart';

enum PurchasePaymentMethod { cash, bank, deferred, cheque }

class PurchasePaymentEntity extends Equatable {
  final int? id;
  final PurchasePaymentMethod method;
  final double amount;
  final DateTime paymentDate;
  final String? referenceNumber;
  final String? bankName;
  final String? accountNumber;
  final String? chequeNumber;
  final DateTime? chequeDate;
  final String? cashBox;
  final DateTime? dueDate;
  final String? notes;
  final Map<String, dynamic>? details;

  const PurchasePaymentEntity({
    this.id,
    required this.method,
    required this.amount,
    required this.paymentDate,
    this.referenceNumber,
    this.bankName,
    this.accountNumber,
    this.chequeNumber,
    this.chequeDate,
    this.cashBox,
    this.dueDate,
    this.notes,
    this.details,
  });

  String get methodLabel {
    switch (method) {
      case PurchasePaymentMethod.cash:
        return 'نقدي';
      case PurchasePaymentMethod.bank:
        return 'تحويل بنكي';
      case PurchasePaymentMethod.deferred:
        return 'آجل';
      case PurchasePaymentMethod.cheque:
        return 'شيك';
    }
  }

  PurchasePaymentEntity copyWith({
    int? id,
    PurchasePaymentMethod? method,
    double? amount,
    DateTime? paymentDate,
    String? referenceNumber,
    String? bankName,
    String? accountNumber,
    String? chequeNumber,
    DateTime? chequeDate,
    String? cashBox,
    DateTime? dueDate,
    String? notes,
    Map<String, dynamic>? details,
  }) {
    return PurchasePaymentEntity(
      id: id ?? this.id,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      chequeDate: chequeDate ?? this.chequeDate,
      cashBox: cashBox ?? this.cashBox,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      details: details ?? this.details,
    );
  }

  @override
  List<Object?> get props => [
        id,
        method,
        amount,
        paymentDate,
        referenceNumber,
        bankName,
        accountNumber,
        chequeNumber,
        chequeDate,
        cashBox,
        dueDate,
        notes,
        details,
      ];
}
