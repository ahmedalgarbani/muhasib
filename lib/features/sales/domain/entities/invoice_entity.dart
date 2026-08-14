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

  final int? quotationStatus;
  final double? paidAmount;  // Amount paid in cash for split payments
  final double? bankPaidAmount;  // Amount paid via bank for split payments

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
    this.quotationStatus,
    this.paidAmount,
    this.bankPaidAmount,
    this.lines = const [],
  });

  InvoiceEntity copyWith({
    int? id,
    int? creatorId,
    int? lastModifierId,
    String? concurrencyStamp,
    String? extraProperties,
    int? creationTime,
    int? lastModificationTime,
    int? invoiceType,
    String? number,
    int? date,
    String? statement,
    double? amount,
    double? totalAmount,
    double? taxAmt,
    double? taxRatio,
    double? discountAmt,
    double? discountRatio,
    double? otherFeeAmt,
    double? otherFeeNetRatio,
    double? netRevenueAmt,
    double? totalAmountAfterDiscount,
    double? finalAmt,
    int? currencyId,
    int? stockId,
    int? customerId,
    int? taxId,
    int? otherFeeAccountId,
    int? invoiceTransType,
    int? parentInvoiceType,
    int? parentInvoiceId,
    String? parentInvoiceNumber,
    int? nextInvoiceType,
    int? nextInvoiceId,
    String? nextInvoiceNumber,
    String? uNo,
    String? currencyCode,
    double? exchangeRate,
    String? imagePath,
    int? paymentStatus,
    String? shippingAddress,
    int? dueDate,
    int? quotationStatus,
    double? paidAmount,
    double? bankPaidAmount,
    List<InvoiceLineEntity>? lines,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      concurrencyStamp: concurrencyStamp ?? this.concurrencyStamp,
      extraProperties: extraProperties ?? this.extraProperties,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      invoiceType: invoiceType ?? this.invoiceType,
      number: number ?? this.number,
      date: date ?? this.date,
      statement: statement ?? this.statement,
      amount: amount ?? this.amount,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmt: taxAmt ?? this.taxAmt,
      taxRatio: taxRatio ?? this.taxRatio,
      discountAmt: discountAmt ?? this.discountAmt,
      discountRatio: discountRatio ?? this.discountRatio,
      otherFeeAmt: otherFeeAmt ?? this.otherFeeAmt,
      otherFeeNetRatio: otherFeeNetRatio ?? this.otherFeeNetRatio,
      netRevenueAmt: netRevenueAmt ?? this.netRevenueAmt,
      totalAmountAfterDiscount: totalAmountAfterDiscount ?? this.totalAmountAfterDiscount,
      finalAmt: finalAmt ?? this.finalAmt,
      currencyId: currencyId ?? this.currencyId,
      stockId: stockId ?? this.stockId,
      customerId: customerId ?? this.customerId,
      taxId: taxId ?? this.taxId,
      otherFeeAccountId: otherFeeAccountId ?? this.otherFeeAccountId,
      invoiceTransType: invoiceTransType ?? this.invoiceTransType,
      parentInvoiceType: parentInvoiceType ?? this.parentInvoiceType,
      parentInvoiceId: parentInvoiceId ?? this.parentInvoiceId,
      parentInvoiceNumber: parentInvoiceNumber ?? this.parentInvoiceNumber,
      nextInvoiceType: nextInvoiceType ?? this.nextInvoiceType,
      nextInvoiceId: nextInvoiceId ?? this.nextInvoiceId,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      uNo: uNo ?? this.uNo,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      imagePath: imagePath ?? this.imagePath,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      dueDate: dueDate ?? this.dueDate,
      quotationStatus: quotationStatus ?? this.quotationStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      bankPaidAmount: bankPaidAmount ?? this.bankPaidAmount,
      lines: lines ?? this.lines,
    );
  }

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
        quotationStatus,
        paidAmount,
        bankPaidAmount,
        lines,
      ];
}
