import 'package:muhasib/features/purchases/domain/entities/purchase_invoice_entity.dart';
import 'package:muhasib/features/purchases/data/models/purchase_invoice_item_model.dart';
import 'package:muhasib/features/purchases/data/models/purchase_payment_model.dart';

class PurchaseInvoiceModel extends PurchaseInvoiceEntity {
  const PurchaseInvoiceModel({
    super.id,
    required super.invoiceNumber,
    required super.invoiceDate,
    required super.supplierId,
    super.supplierName,
    super.supplierPhone,
    super.supplierAddress,
    required super.items,
    required super.subtotal,
    super.discountAmount,
    super.discountPercent,
    super.taxAmount,
    super.taxPercent,
    super.shippingCost,
    super.otherCharges,
    required super.totalAmount,
    super.paidAmount,
    super.remainingAmount,
    super.payments,
    super.notes,
    super.warehouse,
    super.currency,
    super.paymentStatus,
    super.invoiceType,
    super.parentInvoiceId,
    super.parentInvoiceNumber,
    super.dueDate,
    super.isPosted,
    required super.createdAt,
    super.updatedAt,
  });

  factory PurchaseInvoiceModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceModel(
      id: json['id'] as int?,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: DateTime.fromMillisecondsSinceEpoch(
        (json['invoice_date'] as int) * 1000,
      ),
      supplierId: json['supplier_id'] as int,
      supplierName: json['supplier_name'] as String?,
      supplierPhone: json['supplier_phone'] as String?,
      supplierAddress: json['supplier_address'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => PurchaseInvoiceItemModel.fromJson(item))
              .toList()
          : [],
      subtotal: (json['subtotal'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (json['other_charges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      payments: json['payments'] != null
          ? (json['payments'] as List)
              .map((payment) => PurchasePaymentModel.fromJson(payment))
              .toList()
          : [],
      notes: json['notes'] as String?,
      warehouse: json['warehouse'] as String?,
      currency: json['currency'] as String? ?? 'ريال سعودي',
      paymentStatus: json['payment_status'] as int? ?? 0,
      invoiceType: json['invoice_type'] as int? ?? 0,
      parentInvoiceId: json['parent_invoice_id'] as int?,
      parentInvoiceNumber: json['parent_invoice_number'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['due_date'] as int) * 1000,
            )
          : null,
      isPosted: json['is_posted'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['creation_time'] as int) * 1000,
      ),
      updatedAt: json['last_modification_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['last_modification_time'] as int) * 1000,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.millisecondsSinceEpoch ~/ 1000,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_phone': supplierPhone,
      'supplier_address': supplierAddress,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'discount_percent': discountPercent,
      'tax_amount': taxAmount,
      'tax_percent': taxPercent,
      'shipping_cost': shippingCost,
      'other_charges': otherCharges,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'notes': notes,
      'warehouse': warehouse,
      'currency': currency,
      'payment_status': paymentStatus,
      'invoice_type': invoiceType,
      'parent_invoice_id': parentInvoiceId,
      'parent_invoice_number': parentInvoiceNumber,
      'due_date': dueDate != null ? dueDate!.millisecondsSinceEpoch ~/ 1000 : null,
      'is_posted': isPosted ? 1 : 0,
      'creation_time': createdAt.millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': updatedAt != null ? updatedAt!.millisecondsSinceEpoch ~/ 1000 : null,
    };
  }

  factory PurchaseInvoiceModel.fromEntity(PurchaseInvoiceEntity entity) {
    return PurchaseInvoiceModel(
      id: entity.id,
      invoiceNumber: entity.invoiceNumber,
      invoiceDate: entity.invoiceDate,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      supplierPhone: entity.supplierPhone,
      supplierAddress: entity.supplierAddress,
      items: entity.items
          .map((item) => PurchaseInvoiceItemModel.fromEntity(item))
          .toList(),
      subtotal: entity.subtotal,
      discountAmount: entity.discountAmount,
      discountPercent: entity.discountPercent,
      taxAmount: entity.taxAmount,
      taxPercent: entity.taxPercent,
      shippingCost: entity.shippingCost,
      otherCharges: entity.otherCharges,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      remainingAmount: entity.remainingAmount,
      payments: entity.payments
          .map((payment) => PurchasePaymentModel.fromEntity(payment))
          .toList(),
      notes: entity.notes,
      warehouse: entity.warehouse,
      currency: entity.currency,
      paymentStatus: entity.paymentStatus,
      invoiceType: entity.invoiceType,
      parentInvoiceId: entity.parentInvoiceId,
      parentInvoiceNumber: entity.parentInvoiceNumber,
      dueDate: entity.dueDate,
      isPosted: entity.isPosted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
