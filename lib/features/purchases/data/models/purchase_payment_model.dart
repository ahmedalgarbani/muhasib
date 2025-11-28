import 'package:muhasib/features/purchases/domain/entities/purchase_payment_entity.dart';

class PurchasePaymentModel extends PurchasePaymentEntity {
  const PurchasePaymentModel({
    super.id,
    required super.method,
    required super.amount,
    required super.paymentDate,
    super.referenceNumber,
    super.bankName,
    super.accountNumber,
    super.chequeNumber,
    super.chequeDate,
    super.cashBox,
    super.dueDate,
    super.notes,
    super.details,
  });

  factory PurchasePaymentModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentModel(
      id: json['id'] as int?,
      method: _parsePaymentMethod(json['payment_method'] as String),
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.fromMillisecondsSinceEpoch(
        (json['payment_date'] as int) * 1000,
      ),
      referenceNumber: json['reference_number'] as String?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      chequeNumber: json['cheque_number'] as String?,
      chequeDate: json['cheque_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['cheque_date'] as int) * 1000,
            )
          : null,
      cashBox: json['cash_box'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['due_date'] as int) * 1000,
            )
          : null,
      notes: json['notes'] as String?,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson({int? invoiceId}) {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'payment_method': _methodToString(method),
      'amount': amount,
      'payment_date': paymentDate.millisecondsSinceEpoch ~/ 1000,
      'reference_number': referenceNumber,
      'bank_name': bankName,
      'account_number': accountNumber,
      'cheque_number': chequeNumber,
      'cheque_date': chequeDate != null ? chequeDate!.millisecondsSinceEpoch ~/ 1000 : null,
      'cash_box': cashBox,
      'due_date': dueDate != null ? dueDate!.millisecondsSinceEpoch ~/ 1000 : null,
      'notes': notes,
      'details': details,
    };
  }

  factory PurchasePaymentModel.fromEntity(PurchasePaymentEntity entity) {
    return PurchasePaymentModel(
      id: entity.id,
      method: entity.method,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      referenceNumber: entity.referenceNumber,
      bankName: entity.bankName,
      accountNumber: entity.accountNumber,
      chequeNumber: entity.chequeNumber,
      chequeDate: entity.chequeDate,
      cashBox: entity.cashBox,
      dueDate: entity.dueDate,
      notes: entity.notes,
      details: entity.details,
    );
  }

  static PurchasePaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return PurchasePaymentMethod.cash;
      case 'bank':
        return PurchasePaymentMethod.bank;
      case 'deferred':
        return PurchasePaymentMethod.deferred;
      case 'cheque':
        return PurchasePaymentMethod.cheque;
      default:
        return PurchasePaymentMethod.cash;
    }
  }

  static String _methodToString(PurchasePaymentMethod method) {
    switch (method) {
      case PurchasePaymentMethod.cash:
        return 'cash';
      case PurchasePaymentMethod.bank:
        return 'bank';
      case PurchasePaymentMethod.deferred:
        return 'deferred';
      case PurchasePaymentMethod.cheque:
        return 'cheque';
    }
  }
}
