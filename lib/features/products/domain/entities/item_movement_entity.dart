import 'package:equatable/equatable.dart';

class ItemMovementEntity extends Equatable {
  final int docNo;
  final int transDocType;
  final bool transInOut; // true = in, false = out
  final int transDate;
  final int categoryId;
  final int unitId;
  final int groupId;
  final int categorySubUnitId;
  final int stockId;
  final double? quantity;
  final double quantityIn;
  final double quantityOut;
  final double? costAmount;
  final double? costLocalAmount;
  final int currencyId;
  final String? currencyCode;
  final double? exchangeRate;
  final double? sellAmount;
  final double? sellLocalAmount;
  final String refrencNo;
  final String statement;
  final String? referenceNumber;
  final String? uNo;
  final String? barcodeNo;
  final int? expireDate;
  final int? customerId;
  final int? creatorId;
  final int? lastModifierId;
  final String? concurrencyStamp;
  final String? extraProperties;
  final int? creationTime;
  final int? lastModificationTime;

  const ItemMovementEntity({
    required this.docNo,
    required this.transDocType,
    required this.transInOut,
    required this.transDate,
    required this.categoryId,
    required this.unitId,
    required this.groupId,
    required this.categorySubUnitId,
    required this.stockId,
    this.quantity,
    required this.quantityIn,
    required this.quantityOut,
    this.costAmount,
    this.costLocalAmount,
    required this.currencyId,
    this.currencyCode,
    this.exchangeRate,
    this.sellAmount,
    this.sellLocalAmount,
    required this.refrencNo,
    required this.statement,
    this.referenceNumber,
    this.uNo,
    this.barcodeNo,
    this.expireDate,
    this.customerId,
    this.creatorId,
    this.lastModifierId,
    this.concurrencyStamp,
    this.extraProperties,
    this.creationTime,
    this.lastModificationTime,
  });

  double get netQuantity => quantityIn - quantityOut;
  
  String get movementTypeString {
    switch (transDocType) {
      case 1:
        return 'فاتورة مبيعات';
      case 2:
        return 'فاتورة مشتريات';
      case 3:
        return 'عرض سعر';
      case 4:
        return 'مرتجع مبيعات';
      case 5:
        return 'مرتجع مشتريات';
      case 6:
        return 'تحويل مخزني';
      case 7:
        return 'جرد مخزني';
      default:
        return 'حركة أخرى';
    }
  }

  @override
  List<Object?> get props => [
        docNo,
        transDocType,
        transInOut,
        transDate,
        categoryId,
        unitId,
        groupId,
        categorySubUnitId,
        stockId,
        quantity,
        quantityIn,
        quantityOut,
        costAmount,
        costLocalAmount,
        currencyId,
        currencyCode,
        exchangeRate,
        sellAmount,
        sellLocalAmount,
        refrencNo,
        statement,
        referenceNumber,
        uNo,
        barcodeNo,
        expireDate,
        customerId,
      ];
}
