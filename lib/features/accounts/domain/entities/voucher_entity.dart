import 'package:equatable/equatable.dart';

enum VoucherType {
  receipt,
  payment;

  int get value => this == VoucherType.payment ? 2 : 1;

  String get label => this == VoucherType.payment ? 'سند صرف' : 'سند قبض';

  static VoucherType fromValue(int value) {
    return value == 2 ? VoucherType.payment : VoucherType.receipt;
  }
}

class VoucherLineEntity extends Equatable {
  final int? id;
  final int? voucherId;
  final int? accountId;
  final String? accountName;
  final double? amount;
  final double? localAmount;
  final String? currencyCode;
  final int? currencyId;
  final double? exchangeRate;
  final String statement;

  const VoucherLineEntity({
    this.id,
    this.voucherId,
    this.accountId,
    this.accountName,
    this.amount,
    this.localAmount,
    this.currencyCode,
    this.currencyId,
    this.exchangeRate,
    this.statement = '',
  });

  VoucherLineEntity copyWith({
    int? id,
    int? voucherId,
    int? accountId,
    String? accountName,
    double? amount,
    double? localAmount,
    String? currencyCode,
    int? currencyId,
    double? exchangeRate,
    String? statement,
  }) {
    return VoucherLineEntity(
      id: id ?? this.id,
      voucherId: voucherId ?? this.voucherId,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      localAmount: localAmount ?? this.localAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyId: currencyId ?? this.currencyId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      statement: statement ?? this.statement,
    );
  }

  @override
  List<Object?> get props => [
        id,
        voucherId,
        accountId,
        accountName,
        amount,
        localAmount,
        currencyCode,
        currencyId,
        exchangeRate,
        statement,
      ];
}

class VoucherEntity extends Equatable {
  final int? id;
  final int number;
  final DateTime date;
  final String statement;
  final double amount;
  final int accountId;
  final String? accountName;
  final VoucherType type;
  final bool isPosted;
  final String referenceNumber;
  final double? localAmount;
  final String? currencyCode;
  final int? currencyId;
  final double? exchangeRate;
  final String? imagePath;
  final String? parentNumber;
  final int? parentId;
  final int status;
  final List<VoucherLineEntity> lines;

  const VoucherEntity({
    this.id,
    required this.number,
    required this.date,
    required this.statement,
    required this.amount,
    required this.accountId,
    this.accountName,
    required this.type,
    this.isPosted = false,
    this.referenceNumber = '',
    this.localAmount,
    this.currencyCode,
    this.currencyId,
    this.exchangeRate,
    this.imagePath,
    this.parentNumber,
    this.parentId,
    this.status = 0,
    this.lines = const [],
  });

  VoucherEntity copyWith({
    int? id,
    int? number,
    DateTime? date,
    String? statement,
    double? amount,
    int? accountId,
    String? accountName,
    VoucherType? type,
    bool? isPosted,
    String? referenceNumber,
    double? localAmount,
    String? currencyCode,
    int? currencyId,
    double? exchangeRate,
    String? imagePath,
    String? parentNumber,
    int? parentId,
    int? status,
    List<VoucherLineEntity>? lines,
  }) {
    return VoucherEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      statement: statement ?? this.statement,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      type: type ?? this.type,
      isPosted: isPosted ?? this.isPosted,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      localAmount: localAmount ?? this.localAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyId: currencyId ?? this.currencyId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      imagePath: imagePath ?? this.imagePath,
      parentNumber: parentNumber ?? this.parentNumber,
      parentId: parentId ?? this.parentId,
      status: status ?? this.status,
      lines: lines ?? this.lines,
    );
  }

  @override
  List<Object?> get props => [
        id,
        number,
        date,
        statement,
        amount,
        accountId,
        accountName,
        type,
        isPosted,
        referenceNumber,
        localAmount,
        currencyCode,
        currencyId,
        exchangeRate,
        imagePath,
        parentNumber,
        parentId,
        status,
        lines,
      ];
}

