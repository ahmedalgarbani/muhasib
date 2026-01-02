import 'package:muhasib/features/reports/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required int id,
    required DateTime date,
    required String description,
    required String reference,
    required String transactionType,
    required double totalAmount,
    required List<TransactionDetailEntity> details,
    int? invoiceId,
    int? voucherId,
    required int createdBy,
    required DateTime createdAt,
  }) : super(
          id: id,
          date: date,
          description: description,
          reference: reference,
          transactionType: transactionType,
          totalAmount: totalAmount,
          details: details,
          invoiceId: invoiceId,
          voucherId: voucherId,
          createdBy: createdBy,
          createdAt: createdAt,
        );

  factory TransactionModel.fromDatabase(Map<String, dynamic> json, List<Map<String, dynamic>> lines) {
    return TransactionModel(
      id: json['id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch((json['entry_date'] ?? json['creation_time']) * 1000),
      description: json['description'] ?? '',
      reference: json['number'] ?? json['reference_number'] ?? '',
      transactionType: _mapTransactionType(json['reference_type']),
      totalAmount: (json['total_debit'] ?? 0.0) as double,
      details: lines.map<TransactionDetailEntity>((line) => TransactionDetailModel.fromDatabase(line)).toList(),
      invoiceId: json['reference_id'] as int?,
      voucherId: json['voucher_id'] as int?,
      createdBy: json['creator_id'] ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['creation_time'] ?? 0) * 1000),
    );
  }

  static String _mapTransactionType(String? type) {
    if (type == null) return TransactionType.journal.value;
    
    switch (type.toLowerCase()) {
      case 'invoice':
      case 'sales':
        return TransactionType.sales.value;
      case 'purchase':
        return TransactionType.purchase.value;
      case 'receipt':
        return TransactionType.receipt.value;
      case 'payment':
        return TransactionType.payment.value;
      case 'opening':
        return TransactionType.opening.value;
      case 'sales_return':
        return TransactionType.salesReturn.value;
      case 'purchase_return':
        return TransactionType.purchaseReturn.value;
      default:
        return TransactionType.journal.value;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_date': date.millisecondsSinceEpoch ~/ 1000,
      'description': description,
      'number': reference,
      'reference_type': transactionType,
      'total_debit': totalAmount,
      'total_credit': totalAmount,
      'creator_id': createdBy,
      'creation_time': createdAt.millisecondsSinceEpoch ~/ 1000,
      'invoice_id': invoiceId,
      'voucher_id': voucherId,
    };
  }
}

class TransactionDetailModel extends TransactionDetailEntity {
  const TransactionDetailModel({
    required int id,
    required int accountId,
    required String accountName,
    required String accountCode,
    required double debitAmount,
    required double creditAmount,
    String? notes,
    int? costCenterId,
    String? costCenterName,
  }) : super(
          id: id,
          accountId: accountId,
          accountName: accountName,
          accountCode: accountCode,
          debitAmount: debitAmount,
          creditAmount: creditAmount,
          notes: notes,
          costCenterId: costCenterId,
          costCenterName: costCenterName,
        );

  factory TransactionDetailModel.fromDatabase(Map<String, dynamic> json) {
    return TransactionDetailModel(
      id: json['id'] as int,
      accountId: json['account_id'] as int,
      accountName: json['account_name'] ?? '',
      accountCode: json['account_code'] ?? '',
      debitAmount: (json['debit_amount'] ?? 0.0) as double,
      creditAmount: (json['credit_amount'] ?? 0.0) as double,
      notes: json['notes'] as String?,
      costCenterId: json['cost_center_id'] as int?,
      costCenterName: json['cost_center_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'account_name': accountName,
      'account_code': accountCode,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'notes': notes,
      'cost_center_id': costCenterId,
      'cost_center_name': costCenterName,
    };
  }
}
