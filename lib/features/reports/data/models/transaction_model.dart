import 'package:muhasib/features/reports/domain/entities/transaction_entity.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.date,
    required super.description,
    required super.reference,
    required super.transactionType,
    required super.totalAmount,
    required super.details,
    super.invoiceId,
    super.voucherId,
    required super.createdBy,
    required super.createdAt,
  });

  factory TransactionModel.fromDatabase(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> lines,
  ) {
    final entryTimestamp =
        (json['entry_date'] ?? json['creation_time'] ?? 0) as num;
    final creationTimestamp = (json['creation_time'] ?? 0) as num;
    return TransactionModel(
      id: json['id'] as int,
      date: dateTimeFromReportTimestamp(entryTimestamp),
      description: json['description'] ?? '',
      reference: json['number'] ?? json['reference_number'] ?? '',
      transactionType: _mapTransactionType(json['reference_type']),
      totalAmount: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      details: lines
          .map<TransactionDetailEntity>(TransactionDetailModel.fromDatabase)
          .toList(),
      invoiceId: json['reference_id'] as int?,
      voucherId: json['voucher_id'] as int?,
      createdBy: json['creator_id'] ?? 1,
      createdAt: dateTimeFromReportTimestamp(creationTimestamp),
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
    required super.id,
    required super.accountId,
    required super.accountName,
    required super.accountCode,
    required super.debitAmount,
    required super.creditAmount,
    super.notes,
    super.costCenterId,
    super.costCenterName,
  });

  factory TransactionDetailModel.fromDatabase(Map<String, dynamic> json) {
    return TransactionDetailModel(
      id: json['id'] as int,
      accountId: json['account_id'] as int,
      accountName: json['account_name'] ?? '',
      accountCode: json['account_code'] ?? '',
      debitAmount: (json['debit_amount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0.0,
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
