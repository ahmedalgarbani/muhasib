import 'package:equatable/equatable.dart';

class PurchaseInvoiceItemEntity extends Equatable {
  final int? id;
  final int productId;
  final String productName;
  final String? barcode;
  final String? description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final double? discountAmount;
  final double? discountPercent;
  final double? taxAmount;
  final double? taxPercent;
  final DateTime? expiryDate;
  final String? batchNumber;
  final String? serialNumber;

  const PurchaseInvoiceItemEntity({
    this.id,
    required this.productId,
    required this.productName,
    this.barcode,
    this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    this.taxAmount = 0.0,
    this.taxPercent = 0.0,
    this.expiryDate,
    this.batchNumber,
    this.serialNumber,
  });

  double get calculatedTotal => quantity * unitPrice;
  
  double get calculatedDiscountAmount => 
      discountPercent != null && discountPercent! > 0 
          ? calculatedTotal * discountPercent! / 100 
          : discountAmount ?? 0.0;
  
  double get calculatedTaxAmount => 
      taxPercent != null && taxPercent! > 0 
          ? (calculatedTotal - calculatedDiscountAmount) * taxPercent! / 100 
          : taxAmount ?? 0.0;
  
  double get finalPrice => calculatedTotal - calculatedDiscountAmount + calculatedTaxAmount;

  PurchaseInvoiceItemEntity copyWith({
    int? id,
    int? productId,
    String? productName,
    String? barcode,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    double? discountAmount,
    double? discountPercent,
    double? taxAmount,
    double? taxPercent,
    DateTime? expiryDate,
    String? batchNumber,
    String? serialNumber,
  }) {
    return PurchaseInvoiceItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        barcode,
        description,
        quantity,
        unit,
        unitPrice,
        totalPrice,
        discountAmount,
        discountPercent,
        taxAmount,
        taxPercent,
        expiryDate,
        batchNumber,
        serialNumber,
      ];
}
