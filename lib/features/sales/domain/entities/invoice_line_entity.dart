import 'package:equatable/equatable.dart';

class InvoiceLineEntity extends Equatable {
  final int? id;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  final int invoiceType;
  final double amount;
  final double totalAmount;
  final double? taxAmt;
  final int? taxRatio;
  final double? discountAmt;
  final int? discountRatio;
  final double? otherFeeAmt;
  final int? otherFeeNetRatio;
  final double netRevenueAmt;
  final String? currencyCode;
  final double? exchangeRate;
  final int? currencyId;
  final double quantity;
  final int? categoryId;
  final int groupId;
  final int unitId;
  final int categorySubUnitId;
  final int stockId;
  final int invoiceId;
  final int customerId;
  final int date;
  final int? expireDate;
  final int invoiceTransType;
  final double? lineDiscount;

  const InvoiceLineEntity({
    this.id,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
    required this.invoiceType,
    required this.amount,
    required this.totalAmount,
    this.taxAmt,
    this.taxRatio,
    this.discountAmt,
    this.discountRatio,
    this.otherFeeAmt,
    this.otherFeeNetRatio,
    required this.netRevenueAmt,
    this.currencyCode,
    this.exchangeRate,
    this.currencyId,
    required this.quantity,
    this.categoryId,
    required this.groupId,
    required this.unitId,
    required this.categorySubUnitId,
    required this.stockId,
    required this.invoiceId,
    required this.customerId,
    required this.date,
    this.expireDate,
    required this.invoiceTransType,
    this.lineDiscount,
  });

  @override
  List<Object?> get props => [
        id,
        creatorId,
        lastModifierId,
        concurrencyStamp,
        extraProperties,
        creationTime,
        lastModificationTime,
        invoiceType,
        amount,
        totalAmount,
        taxAmt,
        taxRatio,
        discountAmt,
        discountRatio,
        otherFeeAmt,
        otherFeeNetRatio,
        netRevenueAmt,
        currencyCode,
        exchangeRate,
        currencyId,
        quantity,
        categoryId,
        groupId,
        unitId,
        categorySubUnitId,
        stockId,
        invoiceId,
        customerId,
        date,
        expireDate,
        invoiceTransType,
        lineDiscount,
      ];
}
