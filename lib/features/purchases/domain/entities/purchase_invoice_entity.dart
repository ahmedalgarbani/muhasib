import 'package:equatable/equatable.dart';
import 'package:muhasib/features/purchases/domain/entities/purchase_invoice_item_entity.dart';
import 'package:muhasib/features/purchases/domain/entities/purchase_payment_entity.dart';

class PurchaseInvoiceEntity extends Equatable {
  final int? id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final int supplierId;
  final String? supplierName;
  final String? supplierPhone;
  final String? supplierAddress;
  final List<PurchaseInvoiceItemEntity> items;
  final double subtotal;
  final double discountAmount;
  final double discountPercent;
  final double taxAmount;
  final double taxPercent;
  final double shippingCost;
  final double otherCharges;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final List<PurchasePaymentEntity> payments;
  final String? notes;
  final String? warehouse;
  final String currency;
  final int paymentStatus; // 0: unpaid, 1: partial, 2: paid
  final int invoiceType; // 0: cash, 1: credit, 2: return
  final int? parentInvoiceId; // For returns
  final String? parentInvoiceNumber;
  final DateTime? dueDate;
  final bool isPosted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PurchaseInvoiceEntity({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.supplierId,
    this.supplierName,
    this.supplierPhone,
    this.supplierAddress,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    this.taxAmount = 0.0,
    this.taxPercent = 0.0,
    this.shippingCost = 0.0,
    this.otherCharges = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.payments = const [],
    this.notes,
    this.warehouse,
    this.currency = 'ريال سعودي',
    this.paymentStatus = 0,
    this.invoiceType = 0,
    this.parentInvoiceId,
    this.parentInvoiceNumber,
    this.dueDate,
    this.isPosted = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate derived values
  double get calculatedSubtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  double get calculatedDiscountAmount => 
      discountPercent > 0 ? subtotal * discountPercent / 100 : discountAmount;
  
  double get calculatedTaxAmount => 
      taxPercent > 0 ? (subtotal - calculatedDiscountAmount) * taxPercent / 100 : taxAmount;
  
  double get calculatedTotal => 
      subtotal - calculatedDiscountAmount + calculatedTaxAmount + shippingCost + otherCharges;
  
  double get calculatedRemaining => totalAmount - paidAmount;
  
  bool get isFullyPaid => paidAmount >= totalAmount;
  
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < totalAmount;
  
  bool get isReturn => invoiceType == 2;

  PurchaseInvoiceEntity copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    int? supplierId,
    String? supplierName,
    String? supplierPhone,
    String? supplierAddress,
    List<PurchaseInvoiceItemEntity>? items,
    double? subtotal,
    double? discountAmount,
    double? discountPercent,
    double? taxAmount,
    double? taxPercent,
    double? shippingCost,
    double? otherCharges,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    List<PurchasePaymentEntity>? payments,
    String? notes,
    String? warehouse,
    String? currency,
    int? paymentStatus,
    int? invoiceType,
    int? parentInvoiceId,
    String? parentInvoiceNumber,
    DateTime? dueDate,
    bool? isPosted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseInvoiceEntity(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      shippingCost: shippingCost ?? this.shippingCost,
      otherCharges: otherCharges ?? this.otherCharges,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      payments: payments ?? this.payments,
      notes: notes ?? this.notes,
      warehouse: warehouse ?? this.warehouse,
      currency: currency ?? this.currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceType: invoiceType ?? this.invoiceType,
      parentInvoiceId: parentInvoiceId ?? this.parentInvoiceId,
      parentInvoiceNumber: parentInvoiceNumber ?? this.parentInvoiceNumber,
      dueDate: dueDate ?? this.dueDate,
      isPosted: isPosted ?? this.isPosted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        invoiceDate,
        supplierId,
        supplierName,
        items,
        subtotal,
        discountAmount,
        discountPercent,
        taxAmount,
        taxPercent,
        shippingCost,
        otherCharges,
        totalAmount,
        paidAmount,
        remainingAmount,
        payments,
        notes,
        warehouse,
        currency,
        paymentStatus,
        invoiceType,
        parentInvoiceId,
        dueDate,
        isPosted,
        createdAt,
        updatedAt,
      ];
}
