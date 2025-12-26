import '../../domain/entities/voucher_entity.dart';

class VoucherModel extends VoucherEntity {
  const VoucherModel({
    int? id,
    required int number,
    required DateTime date,
    required String statement,
    required double amount,
    required int accountId,
    String? accountName,
    required VoucherType type,
    bool isPosted = false,
    String referenceNumber = '',
    double? localAmount,
    String? currencyCode,
    int? currencyId,
    double? exchangeRate,
    String? imagePath,
    String? parentNumber,
    int? parentId,
    int status = 0,
    List<VoucherLineEntity> lines = const [],
  }) : super(
          id: id,
          number: number,
          date: date,
          statement: statement,
          amount: amount,
          accountId: accountId,
          accountName: accountName,
          type: type,
          isPosted: isPosted,
          referenceNumber: referenceNumber,
          localAmount: localAmount,
          currencyCode: currencyCode,
          currencyId: currencyId,
          exchangeRate: exchangeRate,
          imagePath: imagePath,
          parentNumber: parentNumber,
          parentId: parentId,
          status: status,
          lines: lines,
        );

  factory VoucherModel.fromJson(
    Map<String, dynamic> json, {
    List<VoucherLineModel> lines = const [],
  }) {
    return VoucherModel(
      id: json['id'] as int?,
      number: json['number'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      statement: (json['statement'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      accountId: json['account_id'] as int,
      accountName: json['account_name'] as String?,
      type: VoucherType.fromValue(json['type'] as int),
      isPosted: (json['is_posted'] as int? ?? 0) == 1,
      referenceNumber: (json['reference_number'] as String?) ?? '',
      localAmount: (json['local_amount'] as num?)?.toDouble(),
      currencyCode: json['currency_code'] as String?,
      currencyId: json['currency_id'] as int?,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble(),
      imagePath: json['image_path'] as String?,
      parentNumber: json['parent_number'] as String?,
      parentId: json['parent_id'] as int?,
      status: json['status'] as int? ?? 0,
      lines: lines,
    );
  }

  factory VoucherModel.fromEntity(VoucherEntity entity) {
    final lineModels = entity.lines
        .map((line) => line is VoucherLineModel
            ? line
            : VoucherLineModel.fromEntity(line))
        .toList();

    return VoucherModel(
      id: entity.id,
      number: entity.number,
      date: entity.date,
      statement: entity.statement,
      amount: entity.amount,
      accountId: entity.accountId,
      accountName: entity.accountName,
      type: entity.type,
      isPosted: entity.isPosted,
      referenceNumber: entity.referenceNumber,
      localAmount: entity.localAmount,
      currencyCode: entity.currencyCode,
      currencyId: entity.currencyId,
      exchangeRate: entity.exchangeRate,
      imagePath: entity.imagePath,
      parentNumber: entity.parentNumber,
      parentId: entity.parentId,
      status: entity.status,
      lines: lineModels,
    );
  }

  Map<String, dynamic> toJson() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': id,
      'type': type.value,
      'number': number,
      'date': date.millisecondsSinceEpoch,
      'statement': statement,
      'is_posted': isPosted ? 1 : 0,
      'reference_number': referenceNumber.isEmpty ? ' ' : referenceNumber,
      'amount': amount,
      'local_amount': localAmount ?? amount,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'currency_id': currencyId,
      'account_id': accountId,
      'parent_number': parentNumber,
      'parent_id': parentId,
      'status': status,
      'image_path': imagePath,
      'last_modification_time': now,
      if (id == null) 'creation_time': now,
    };
  }
}

class VoucherLineModel extends VoucherLineEntity {
  const VoucherLineModel({
    int? id,
    int? voucherId,
    int? accountId,
    String? accountName,
    double? amount,
    double? localAmount,
    String? currencyCode,
    int? currencyId,
    double? exchangeRate,
    String statement = '',
  }) : super(
          id: id,
          voucherId: voucherId,
          accountId: accountId,
          accountName: accountName,
          amount: amount,
          localAmount: localAmount,
          currencyCode: currencyCode,
          currencyId: currencyId,
          exchangeRate: exchangeRate,
          statement: statement,
        );

  factory VoucherLineModel.fromJson(Map<String, dynamic> json) {
    return VoucherLineModel(
      id: json['id'] as int?,
      voucherId: json['vouchers_id'] as int?,
      accountId: json['account_id'] as int?,
      accountName: json['account_name'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      localAmount: (json['local_amount'] as num?)?.toDouble(),
      currencyCode: json['currency_code'] as String?,
      currencyId: json['currency_id'] as int?,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble(),
      statement: (json['statement'] as String?) ?? '',
    );
  }

  factory VoucherLineModel.fromEntity(VoucherLineEntity entity) {
    return VoucherLineModel(
      id: entity.id,
      voucherId: entity.voucherId,
      accountId: entity.accountId,
      accountName: entity.accountName,
      amount: entity.amount,
      localAmount: entity.localAmount,
      currencyCode: entity.currencyCode,
      currencyId: entity.currencyId,
      exchangeRate: entity.exchangeRate,
      statement: entity.statement,
    );
  }

  Map<String, dynamic> toJson({required int voucherId}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'vouchers_id': voucherId,
      'account_id': accountId,
      'amount': amount,
      'local_amount': localAmount ?? amount,
      'currency_code': currencyCode,
      'currency_id': currencyId,
      'exchange_rate': exchangeRate,
      'statement': statement.isEmpty ? ' ' : statement,
      'creation_time': now,
      'last_modification_time': now,
    };
  }
}

