import 'package:equatable/equatable.dart';
import 'invoice_line_entity.dart';

class InvoiceEntity extends Equatable {
  final int? id;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  final int invoiceType;
  final String number;
  final int date;
  final String? statement;
  final double amount;
  final double? totalAmount;
  final double? taxAmt;
  final double? taxRatio;
  final double? discountAmt;
  final double? discountRatio;
  final double? otherFeeAmt;
  final double? otherFeeNetRatio;
  final double? netRevenueAmt;
  final double? totalAmountAfterDiscount;
  final double? finalAmt;
  final int? currencyId;
  final int stockId;
  final int customerId;
  final int? taxId;
  final int? otherFeeAccountId;
  final int invoiceTransType;
  final int? parentInvoiceType;
  final int? parentInvoiceId;
  final String? parentInvoiceNumber;
  final int? nextInvoiceType;
  final int? nextInvoiceId;
  final String? nextInvoiceNumber;
  final String? uNo;
  final String? currencyCode;
  final double? exchangeRate;
  final String? imagePath;
  final int paymentStatus;
  final String? shippingAddress;
  final int? dueDate;

  final List<InvoiceLineEntity> lines;

  const InvoiceEntity({
    this.id,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
    required this.invoiceType,
    required this.number,
    required this.date,
    this.statement,
    required this.amount,
    this.totalAmount,
    this.taxAmt,
    this.taxRatio,
    this.discountAmt,
    this.discountRatio,
    this.otherFeeAmt,
    this.otherFeeNetRatio,
    this.netRevenueAmt,
    this.totalAmountAfterDiscount,
    this.finalAmt,
    this.currencyId,
    required this.stockId,
    required this.customerId,
    this.taxId,
    this.otherFeeAccountId,
    required this.invoiceTransType,
    this.parentInvoiceType,
    this.parentInvoiceId,
    this.parentInvoiceNumber,
    this.nextInvoiceType,
    this.nextInvoiceId,
    this.nextInvoiceNumber,
    this.uNo,
    this.currencyCode,
    this.exchangeRate,
    this.imagePath,
    this.paymentStatus = 0,
    this.shippingAddress,
    this.dueDate,
    this.lines = const [],
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
        number,
        date,
        statement,
        amount,
        totalAmount,
        taxAmt,
        taxRatio,
        discountAmt,
        discountRatio,
        otherFeeAmt,
        otherFeeNetRatio,
        netRevenueAmt,
        totalAmountAfterDiscount,
        finalAmt,
        currencyId,
        stockId,
        customerId,
        taxId,
        otherFeeAccountId,
        invoiceTransType,
        parentInvoiceType,
        parentInvoiceId,
        parentInvoiceNumber,
        nextInvoiceType,
        nextInvoiceId,
        nextInvoiceNumber,
        uNo,
        currencyCode,
        exchangeRate,
        imagePath,
        paymentStatus,
        shippingAddress,
        dueDate,
        lines,
      ];
}
