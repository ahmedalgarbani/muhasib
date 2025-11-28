import 'package:muhasib/features/purchases/domain/entities/purchase_invoice_item_entity.dart';

class PurchaseInvoiceItemModel extends PurchaseInvoiceItemEntity {
  const PurchaseInvoiceItemModel({
    super.id,
    required super.productId,
    required super.productName,
    super.barcode,
    super.description,
    required super.quantity,
    required super.unit,
    required super.unitPrice,
    required super.totalPrice,
    super.discountAmount,
    super.discountPercent,
    super.taxAmount,
    super.taxPercent,
    super.expiryDate,
    super.batchNumber,
    super.serialNumber,
  });

  factory PurchaseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceItemModel(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      taxPercent: (json['tax_percent'] as num?)?.toDouble(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['expiry_date'] as int) * 1000,
            )
          : null,
      batchNumber: json['batch_number'] as String?,
      serialNumber: json['serial_number'] as String?,
    );
  }

  Map<String, dynamic> toJson({int? invoiceId}) {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'barcode': barcode,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'discount_amount': discountAmount,
      'discount_percent': discountPercent,
      'tax_amount': taxAmount,
      'tax_percent': taxPercent,
      'expiry_date': expiryDate != null ? expiryDate!.millisecondsSinceEpoch ~/ 1000 : null,
      'batch_number': batchNumber,
      'serial_number': serialNumber,
    };
  }

  factory PurchaseInvoiceItemModel.fromEntity(PurchaseInvoiceItemEntity entity) {
    return PurchaseInvoiceItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      barcode: entity.barcode,
      description: entity.description,
      quantity: entity.quantity,
      unit: entity.unit,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      discountAmount: entity.discountAmount,
      discountPercent: entity.discountPercent,
      taxAmount: entity.taxAmount,
      taxPercent: entity.taxPercent,
      expiryDate: entity.expiryDate,
      batchNumber: entity.batchNumber,
      serialNumber: entity.serialNumber,
    );
  }
}
